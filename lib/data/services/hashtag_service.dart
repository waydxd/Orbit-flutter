import 'package:grpc/grpc.dart';
import '../../config/app_config.dart';
import '../../utils/logger.dart';
import 'local_storage_service.dart';
import '../models/hashtag_prediction.dart' as models;
import '../../generated/grpc/hashtag.pbgrpc.dart';
import '../../generated/grpc/hashtag.pb.dart' as pb;

/// Custom exception for authentication errors
class AuthenticationException implements Exception {
  final String message;
  AuthenticationException(this.message);

  @override
  String toString() => message;
}

/// Service for hashtag prediction via gRPC
class HashtagService {
  // gRPC server configuration
  // For physical device: use your machine's local IP
  // For Android emulator: use 10.0.2.2
  // For iOS simulator: use localhost
  static const String _host = '192.168.99.120';
  static const int _port = 50052;

  ClientChannel? _channel;
  HashtagServiceClient? _client;

  HashtagService();

  /// Initialize or get the gRPC channel
  ClientChannel _getChannel() {
    _channel ??= ClientChannel(
      _host,
      port: _port,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
        connectionTimeout: Duration(seconds: 30),
      ),
    );
    return _channel!;
  }

  /// Get the gRPC client with auth metadata
  Future<HashtagServiceClient> _getClient() async {
    final channel = _getChannel();

    // Get auth token for metadata
    final token = await LocalStorageService.getSecure(AppConfig.accessTokenKey);

    final options = CallOptions(
      metadata: token != null ? {'authorization': 'Bearer $token'} : {},
      timeout: AppConfig.networkTimeout,
    );

    _client = HashtagServiceClient(channel, options: options);
    return _client!;
  }

  /// Predict hashtags for given event text
  ///
  /// [eventText] - The event title/description to analyze
  /// [useBart] - Enable BART model for better accuracy (default: true)
  /// [alpha] - Model weight between 0.0 and 1.0 (default: 0.7)
  /// [threshold] - Confidence threshold between 0.0 and 1.0 (default: 0.3)
  Future<models.HashtagPrediction> predictHashtags(
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

      final client = await _getClient();

      final request = pb.PredictRequest()
        ..eventText = eventText
        ..useBart = useBart
        ..alpha = alpha
        ..threshold = threshold;

      final response = await client.predictHashtags(request);

      // Convert gRPC response to HashtagPrediction model
      final prediction = models.HashtagPrediction(
        suggested: response.suggested.toList(),
        top5: response.top5.map((score) => models.HashtagScore(
          hashtag: score.hashtag,
          confidence: score.confidence,
        )).toList(),
      );

      Logger.infoWithTag(
        'HashtagService',
        'Got ${prediction.suggested.length} suggestions (inference: ${response.inferenceTimeMs.toStringAsFixed(2)}ms)',
      );

      return prediction;
    } on GrpcError catch (e) {
      Logger.errorWithTag('HashtagService', 'gRPC error: ${e.message}');
      if (e.code == StatusCode.unauthenticated) {
        throw AuthenticationException('Token expired or invalid');
      } else if (e.code == StatusCode.invalidArgument) {
        throw Exception('Invalid request: Please check your input');
      }
      throw Exception('Failed to predict hashtags: ${e.message}');
    } catch (e) {
      Logger.errorWithTag('HashtagService', 'Prediction failed: $e');
      throw Exception('Failed to predict hashtags: $e');
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

      final client = await _getClient();

      final request = pb.CollectDataRequest()
        ..userId = int.tryParse(userId) ?? 0
        ..eventText = eventText
        ..selectedHashtags.addAll(selectedHashtags)
        ..timestamp = DateTime.now().toUtc().toIso8601String()
        ..source = 'orbit-flutter';

      final response = await client.collectData(request);

      Logger.infoWithTag(
        'HashtagService',
        'Feedback submitted: ${response.message}',
      );
    } on GrpcError catch (e) {
      Logger.errorWithTag('HashtagService', 'gRPC error: ${e.message}');
      if (e.code == StatusCode.unauthenticated) {
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
      final client = await _getClient();
      final request = pb.HealthRequest();
      final response = await client.healthCheck(request);

      Logger.infoWithTag(
        'HashtagService',
        'Health: ${response.status}, Model: ${response.modelVersion}, F1: ${response.f1Score}',
      );

      return response.status == 'healthy';
    } on GrpcError catch (e) {
      Logger.errorWithTag('HashtagService', 'Health check failed: ${e.message}');
      return false;
    } catch (e) {
      Logger.errorWithTag('HashtagService', 'Health check failed: $e');
      return false;
    }
  }

  /// Close the gRPC channel
  Future<void> dispose() async {
    await _channel?.shutdown();
    _channel = null;
    _client = null;
  }
}
