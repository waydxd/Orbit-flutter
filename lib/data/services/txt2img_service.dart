import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../config/app_config.dart';
import '../../config/environment.dart';
import '../../utils/logger.dart';
import '../models/event_model.dart';
import 'auth_token_service.dart';

/// Outcome of requesting an AI cover image from Orbit-txt2img (direct or via Orbit-core BFF).
class Txt2ImgCoverResult {
  Txt2ImgCoverResult.success(this.url, {this.contentType})
      : skipped = false,
        errorMessage = null;

  Txt2ImgCoverResult.skipped()
      : url = null,
        contentType = null,
        skipped = true,
        errorMessage = null;

  Txt2ImgCoverResult.failure(this.errorMessage)
      : url = null,
        contentType = null,
        skipped = false;

  final String? url;

  /// Optional `content_type` from `images[0]` (e.g. `image/png`).
  final String? contentType;
  final bool skipped;
  final String? errorMessage;

  bool get isSuccess => url != null && url!.isNotEmpty;
}

/// Calls `POST /v1/text-to-image` on Orbit-txt2img, or `POST /api/v1/image/text-to-image` on Orbit-core when proxying.
class Txt2ImgService {
  Txt2ImgService({Dio? dio}) : _dio = dio ?? _buildDio();

  final Dio _dio;

  static Dio _buildDio() {
    final base = EnvironmentConfig.shouldClientAttemptTxt2Img
        ? EnvironmentConfig.txt2ImgHttpBaseUrl
        : 'https://txt2img.disabled';
    return Dio(
      BaseOptions(
        baseUrl: base,
        connectTimeout: AppConfig.networkTimeout,
        sendTimeout: AppConfig.networkTimeout,
        receiveTimeout: const Duration(seconds: 120),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  /// Fixed negative guidance (fal flux-kontext-lora has a single `prompt` field; we append as "Avoid:").
  static const String _eventCoverNegativePrompt =
      'frame, border, card, poster, mockup, UI, text, label, watermark, '
      'white background, white margin, panel, window, device screen, '
      'image within image, floating element, illustration inside a box, '
      'dark vignette border, rounded corners, canvas edge, photo frame';

  /// Positive prompt body only (title + detail interpolated).
  static String buildPositivePrompt(String titleRaw, String detailsRaw) {
    final title = _sanitizeSegment(
      titleRaw.trim().isEmpty ? 'Event' : titleRaw,
      300,
    );
    final details = _sanitizeSegment(
      detailsRaw.trim().isEmpty ? 'No additional details' : detailsRaw,
      1200,
    );

    return '''
A full-bleed photorealistic scene of $title, $details.

The scene extends naturally to every edge of the frame with no white space.
Soft natural lighting, clean modern composition, one clear focal subject centered.
Professional and polished look, shallow depth of field, warm neutral tones.'''
        .trim();
  }

  /// Full string sent as API `prompt` (positive + negative as avoid-list).
  static String buildPrompt(String titleRaw, String detailsRaw) {
    final positive = buildPositivePrompt(titleRaw, detailsRaw);
    return '$positive\n\nAvoid: $_eventCoverNegativePrompt';
  }

  static String _sanitizeSegment(String s, int maxChars) {
    final oneLine = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    final noQuotes = oneLine.replaceAll('"', "'");
    if (noQuotes.length <= maxChars) return noQuotes;
    return '${noQuotes.substring(0, maxChars)}…';
  }

  static Map<String, dynamic>? _coerceMap(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    if (data is String) {
      final t = data.trim();
      if (t.isEmpty || t[0] != '{') return null;
      try {
        final decoded = jsonDecode(t);
        return _coerceMap(decoded);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static String? _extractApiErrorMessage(dynamic data) {
    final m = _coerceMap(data);
    if (m == null) return null;

    String? fromValue(Object? v) {
      if (v == null) return null;
      if (v is String && v.trim().isNotEmpty) return v.trim();
      if (v is List && v.isNotEmpty) {
        final first = v.first;
        if (first is String && first.trim().isNotEmpty) return first.trim();
        if (first is Map) {
          final msg = first['msg'] ?? first['message'];
          if (msg is String && msg.trim().isNotEmpty) return msg.trim();
        }
      }
      return null;
    }

    for (final key in ['error', 'message', 'detail', 'title']) {
      final s = fromValue(m[key]);
      if (s != null) return s;
    }
    return null;
  }

  /// Requests a cover image URL for [event].
  Future<Txt2ImgCoverResult> requestCoverUrl(EventModel event) async {
    if (!EnvironmentConfig.shouldClientAttemptTxt2Img) {
      Logger.debugWithTag('Txt2Img',
          'Image generation disabled (TXT2IMG_USE_CORE_PROXY=false, no direct URL)');
      return Txt2ImgCoverResult.skipped();
    }

    final token = await AuthTokenService.getAccessToken();
    if (token == null) {
      Logger.debugWithTag('Txt2Img', 'No access token; skipping cover');
      return Txt2ImgCoverResult.skipped();
    }

    final prompt = buildPrompt(event.title, event.description);
    final path = EnvironmentConfig.txt2ImgRequestPath;
    final baseOpt = _dio.options.baseUrl;
    final fullUrl =
        Uri.tryParse(baseOpt)?.resolve(path).toString() ?? '$baseOpt$path';
    try {
      final response = await _dio.post<dynamic>(
        path,
        data: <String, dynamic>{
          'prompt': prompt,
          'num_images': 1,
          'output_format': 'png',
        },
        options: Options(
          headers: <String, dynamic>{'Authorization': 'Bearer $token'},
        ),
      );

      final data = _coerceMap(response.data);
      if (data == null) {
        Logger.errorWithTag('Txt2Img',
            'Success HTTP ${response.statusCode} but body is not a JSON object');
        return Txt2ImgCoverResult.failure(
            'Unexpected response from image service');
      }

      final imagesRaw = data['images'];
      if (imagesRaw is! List || imagesRaw.isEmpty) {
        Logger.warningWithTag('Txt2Img',
            '200 response without images[] keys=${data.keys.toList()}');
        return Txt2ImgCoverResult.failure('No image returned');
      }

      final firstMap = _coerceMap(imagesRaw.first);
      if (firstMap == null) {
        return Txt2ImgCoverResult.failure('Invalid image payload');
      }

      final url = firstMap['url']?.toString();
      if (url == null || url.isEmpty) {
        return Txt2ImgCoverResult.failure('Missing image URL');
      }

      final ct = firstMap['content_type']?.toString().trim();
      Logger.infoWithTag('Txt2Img', 'Cover URL received');
      return Txt2ImgCoverResult.success(
        url,
        contentType: ct != null && ct.isNotEmpty ? ct : null,
      );
    } on DioException catch (e) {
      final msg = _messageFromDio(e);
      final code = e.response?.statusCode;
      final bodyPreview = _responseBodyPreview(e.response?.data);
      Logger.errorWithTag(
        'Txt2Img',
        'Cover request failed: $msg (HTTP $code) url=$fullUrl body=$bodyPreview',
      );
      return Txt2ImgCoverResult.failure(msg);
    } catch (e, st) {
      Logger.errorWithTag('Txt2Img', 'Cover request failed: $e\n$st');
      return Txt2ImgCoverResult.failure('Something went wrong. Try again.');
    }
  }

  /// Downloads image bytes from a public HTTPS URL (e.g. fal CDN). No auth.
  static Future<Uint8List?> downloadImageBytes(String imageUrl) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: AppConfig.networkTimeout,
        receiveTimeout: const Duration(seconds: 90),
        responseType: ResponseType.bytes,
        followRedirects: true,
        validateStatus: (code) => code != null && code < 500,
      ),
    );
    try {
      final response = await dio.get<List<int>>(imageUrl);
      if (response.statusCode == 200 && response.data != null) {
        return Uint8List.fromList(response.data!);
      }
      Logger.warningWithTag(
        'Txt2Img',
        'Download image failed HTTP ${response.statusCode} url=$imageUrl',
      );
      return null;
    } on DioException catch (e) {
      Logger.errorWithTag(
        'Txt2Img',
        'Download image failed: ${e.message} url=$imageUrl',
      );
      return null;
    } catch (e, st) {
      Logger.errorWithTag('Txt2Img', 'Download image failed: $e\n$st');
      return null;
    }
  }

  static String coverFilenameForContentType(String? declared) {
    if (declared == null || declared.isEmpty) return 'cover.png';
    final lower = declared.toLowerCase();
    if (lower.contains('jpeg') || lower.contains('jpg')) return 'cover.jpg';
    if (lower.contains('png')) return 'cover.png';
    if (lower.contains('webp')) return 'cover.webp';
    return 'cover.png';
  }

  static String _responseBodyPreview(dynamic data) {
    if (data == null) return '';
    final s = data is String ? data : data.toString();
    if (s.length <= 240) return s;
    return '${s.substring(0, 240)}…';
  }

  static String _messageFromDio(DioException e) {
    final code = e.response?.statusCode;
    final fromBody = _extractApiErrorMessage(e.response?.data);
    if (fromBody != null) return fromBody;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Request timed out. Try again.';
      case DioExceptionType.connectionError:
        return 'No connection. Check your network.';
      case DioExceptionType.badCertificate:
        return 'Secure connection failed. Check your network or server certificate.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.badResponse:
        if (code == 401) return 'Session expired. Sign in again.';
        if (code == 404) {
          return 'Image API not found (HTTP 404). Check TXT2IMG_CORE_PATH / deploy the imagen BFF, or set TXT2IMG_BASE_URL to a running txt2img service.';
        }
        if (code == 403) {
          return 'Access denied (HTTP 403).';
        }
        if (code == 429) return 'Too many requests. Try again later.';
        if (code == 502) return 'Image service unreachable. Try again later.';
        if (code == 503) return 'Image service unavailable.';
        if (code != null && code >= 500) {
          return 'Server error. Try again later.';
        }
        if (code != null) {
          return 'Could not generate image (HTTP $code). Try again.';
        }
        return 'Could not generate image. Try again.';
      case DioExceptionType.unknown:
        final err = e.error;
        if (err != null && '$err'.isNotEmpty) {
          return 'Could not reach image service: $err';
        }
        return 'Could not generate image. Try again.';
    }
  }
}
