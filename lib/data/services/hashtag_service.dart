import 'package:dio/dio.dart';
import '../../config/app_config.dart';
import '../../utils/logger.dart';
import 'api_client.dart';
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
  static final String _baseUrl = '${EnvironmentConfig.baseUrl}/api/hashtag';

  final ApiClient _apiClient;

  HashtagService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

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

      final response = await _apiClient.post<Map<String, dynamic>>(
        '$_baseUrl/predict',
        data: {
          'event_text': eventText,
          'use_bart': useBart,
          'alpha': alpha,
          'threshold': threshold,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data == null) {
          throw Exception('Invalid response from hashtag service');
        }

        final prediction = HashtagPrediction.fromJson(data);

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

      final response = await _apiClient.post<Map<String, dynamic>>(
        '$_baseUrl/collect',
        data: {
          'user_id': userId,
          'event_text': eventText,
          'selected_hashtags': selectedHashtags,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'source': 'orbit-flutter',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data ?? <String, dynamic>{};
        Logger.infoWithTag(
          'HashtagService',
          'Feedback submitted: ${data['message'] ?? 'success'}',
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
      final response = await _apiClient.get<Map<String, dynamic>>(
        '$_baseUrl/health',
      );

      if (response.statusCode == 200) {
        final data = response.data ?? <String, dynamic>{};
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
    _apiClient.close();
  }
}
