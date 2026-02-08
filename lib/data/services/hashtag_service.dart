import 'package:dio/dio.dart';
import '../../config/app_config.dart';
import '../../utils/logger.dart';
import 'local_storage_service.dart';
import '../models/hashtag_prediction.dart';

/// Custom exception for authentication errors
class AuthenticationException implements Exception {
  final String message;
  AuthenticationException(this.message);

  @override
  String toString() => message;
}

/// Service for hashtag prediction via HTTP REST API
class HashtagService {
  // Remote hashtag service endpoint
  static const String _baseUrl = '${AppConfig.baseUrl}/api/hashtag';

  late final Dio _dio;

  HashtagService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: AppConfig.networkTimeout,
        receiveTimeout: AppConfig.networkTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Add logging interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          Logger.infoWithTag(
            'HashtagService',
            'Request: ${options.method} ${options.uri}',
          );
          return handler.next(options);
        },
        onResponse: (response, handler) {
          Logger.infoWithTag(
            'HashtagService',
            'Response: ${response.statusCode}',
          );
          return handler.next(response);
        },
        onError: (error, handler) {
          Logger.errorWithTag(
            'HashtagService',
            'Request failed: ${error.message}',
          );
          return handler.next(error);
        },
      ),
    );
  }

  /// Get authorization headers with token
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await LocalStorageService.getSecure(AppConfig.accessTokenKey);
    if (token != null) {
      return {'Authorization': 'Bearer $token'};
    }
    return {};
  }

  /// Predict hashtags for given event text
  ///
  /// [eventText] - The event title/description to analyze
  /// [useBart] - Enable BART model for better accuracy (default: true)
  /// [alpha] - Model weight between 0.0 and 1.0 (default: 0.7)
  /// [threshold] - Confidence threshold between 0.0 and 1.0 (default: 0.3)
  Future<HashtagPrediction> predictHashtags(
    String eventText, {
    bool useBart = true,
    double alpha = 0.7,
    double threshold = 0.3,
  }) async {
    try {
      Logger.infoWithTag(
        'HashtagService',
        'Predicting hashtags for: $eventText',
      );

      final headers = await _getAuthHeaders();

      final response = await _dio.post(
        '/predict',
        data: {
          'event_text': eventText,
          'use_bart': useBart,
          'alpha': alpha,
          'threshold': threshold,
        },
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final prediction = HashtagPrediction.fromJson(response.data);

        Logger.infoWithTag(
          'HashtagService',
          'Got ${prediction.suggested.length} suggestions',
        );

        return prediction;
      } else if (response.statusCode == 401) {
        throw AuthenticationException('Token expired or invalid');
      } else {
        throw Exception('Failed to predict hashtags: ${response.statusCode}');
      }
    } on DioException catch (e) {
      Logger.errorWithTag('HashtagService', 'Request failed: ${e.message}');
      if (e.response?.statusCode == 401) {
        throw AuthenticationException('Token expired or invalid');
      } else if (e.response?.statusCode == 422) {
        throw Exception('Invalid request: Please check your input');
      }
      throw Exception('Failed to predict hashtags: ${e.message}');
    } catch (e) {
      Logger.errorWithTag('HashtagService', 'Prediction failed: $e');
      rethrow;
    }
  }

  /// Submit user feedback for model improvement
  ///
  /// [userId] - The user's ID
  /// [eventText] - The original event text
  /// [selectedHashtags] - The hashtags the user actually selected
  Future<void> submitFeedback({
    required String userId,
    required String eventText,
    required List<String> selectedHashtags,
  }) async {
    try {
      Logger.infoWithTag(
        'HashtagService',
        'Submitting feedback: ${selectedHashtags.length} hashtags',
      );

      final headers = await _getAuthHeaders();

      final response = await _dio.post(
        '/collect',
        data: {
          'user_id': userId,
          'event_text': eventText,
          'selected_hashtags': selectedHashtags,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'source': 'orbit-flutter',
        },
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        Logger.infoWithTag(
          'HashtagService',
          'Feedback submitted: ${response.data['message'] ?? 'success'}',
        );
      } else if (response.statusCode == 401) {
        throw AuthenticationException('Token expired or invalid');
      }
    } on DioException catch (e) {
      Logger.errorWithTag('HashtagService', 'Request failed: ${e.message}');
      if (e.response?.statusCode == 401) {
        throw AuthenticationException('Token expired or invalid');
      }
      // Don't throw - feedback is optional
    } catch (e) {
      Logger.errorWithTag('HashtagService', 'Feedback submission failed: $e');
      // Don't throw - feedback is optional
    }
  }

  /// Check service health
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get('/health');

      if (response.statusCode == 200) {
        final data = response.data;
        Logger.infoWithTag(
          'HashtagService',
          'Health: ${data['status']}, Model: ${data['model_version']}, F1: ${data['f1_score']}',
        );
        return data['status'] == 'healthy';
      }
      return false;
    } on DioException catch (e) {
      Logger.errorWithTag(
        'HashtagService',
        'Health check failed: ${e.message}',
      );
      return false;
    } catch (e) {
      Logger.errorWithTag('HashtagService', 'Health check failed: $e');
      return false;
    }
  }

  /// Close connections (no-op for HTTP, kept for API compatibility)
  Future<void> dispose() async {
    _dio.close();
  }
}
