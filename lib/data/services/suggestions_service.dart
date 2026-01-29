import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/suggestion_model.dart';
import '../models/event_model.dart';
import '../../config/environment.dart';
import '../../utils/logger.dart';

/// Service for fetching AI-generated suggestions for events
class SuggestionsService {
  late final Dio _dio;

  SuggestionsService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: '${EnvironmentConfig.baseUrl}/api/v1',
        connectTimeout: const Duration(seconds: 60), // Longer timeout for AI processing
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    if (EnvironmentConfig.isDebug) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (object) =>
              Logger.debugWithTag('SuggestionsService', object.toString()),
        ),
      );
    }
  }

  /// Fetch AI suggestions for an event
  /// This calls the backend suggestions endpoint which uses Azure OpenAI
  Future<SuggestionResponse> getSuggestions({
    required EventModel event,
    String? accessToken,
  }) async {
    try {
      Logger.infoWithTag(
        'SuggestionsService',
        'Fetching suggestions for event: ${event.id}',
      );

      final requestBody = {
        'event_id': event.id,
        'title': event.title,
        'description': event.description,
        'location': event.location,
        'start_time': event.startTime.toIso8601String(),
        'end_time': event.endTime.toIso8601String(),
      };

      final response = await _dio.post(
        '/suggestions/generate',
        data: requestBody,
        options: accessToken != null
            ? Options(headers: {'Authorization': 'Bearer $accessToken'})
            : null,
      );

      Logger.infoWithTag(
        'SuggestionsService',
        'Suggestions response status: ${response.statusCode}',
      );

      if (response.statusCode == 200 && response.data != null) {
        return SuggestionResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      return SuggestionResponse.empty();
    } on DioException catch (e) {
      Logger.errorWithTag(
        'SuggestionsService',
        'Failed to fetch suggestions: ${e.message}',
      );
      return SuggestionResponse.error(
        _getErrorMessage(e),
      );
    } catch (e) {
      Logger.errorWithTag(
        'SuggestionsService',
        'Unexpected error fetching suggestions: $e',
      );
      return SuggestionResponse.error('Failed to load suggestions');
    }
  }

  /// Stream suggestions for real-time updates (if backend supports SSE)
  Stream<SuggestionModel> streamSuggestions({
    required EventModel event,
    String? accessToken,
  }) async* {
    try {
      Logger.infoWithTag(
        'SuggestionsService',
        'Streaming suggestions for event: ${event.id}',
      );

      final requestBody = {
        'event_id': event.id,
        'title': event.title,
        'description': event.description,
        'location': event.location,
        'start_time': event.startTime.toIso8601String(),
        'end_time': event.endTime.toIso8601String(),
      };

      final response = await _dio.post<ResponseBody>(
        '/suggestions/stream',
        data: requestBody,
        options: Options(
          responseType: ResponseType.stream,
          headers: accessToken != null
              ? {'Authorization': 'Bearer $accessToken'}
              : null,
        ),
      );

      final stream = response.data!.stream;
      String buffer = '';

      await for (final chunk in stream) {
        buffer += utf8.decode(chunk);
        
        // Process complete SSE messages
        while (buffer.contains('\n\n')) {
          final index = buffer.indexOf('\n\n');
          final message = buffer.substring(0, index);
          buffer = buffer.substring(index + 2);

          if (message.startsWith('data: ')) {
            final jsonStr = message.substring(6);
            if (jsonStr.trim() == '[DONE]') {
              return;
            }
            try {
              final json = jsonDecode(jsonStr) as Map<String, dynamic>;
              yield SuggestionModel.fromJson(json);
            } catch (_) {
              // Skip invalid JSON
            }
          }
        }
      }
    } catch (e) {
      Logger.errorWithTag(
        'SuggestionsService',
        'Error streaming suggestions: $e',
      );
    }
  }

  /// Get cached suggestions for an event (if available)
  Future<SuggestionResponse?> getCachedSuggestions({
    required String eventId,
    String? accessToken,
  }) async {
    try {
      final response = await _dio.get(
        '/suggestions/cached/$eventId',
        options: accessToken != null
            ? Options(headers: {'Authorization': 'Bearer $accessToken'})
            : null,
      );

      if (response.statusCode == 200 && response.data != null) {
        return SuggestionResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      Logger.debugWithTag(
        'SuggestionsService',
        'No cached suggestions for event: $eventId',
      );
      return null;
    }
  }

  String _getErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Request timed out. AI suggestions may take a moment to generate.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 429) {
          return 'Too many requests. Please try again later.';
        } else if (statusCode == 503) {
          return 'AI service temporarily unavailable.';
        }
        return 'Failed to get suggestions. Please try again.';
      default:
        return 'Failed to load suggestions';
    }
  }

  void dispose() {
    _dio.close();
  }
}

