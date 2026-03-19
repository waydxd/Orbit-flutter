import 'package:dio/dio.dart';
import '../../config/app_config.dart';
import '../../utils/logger.dart';

/// Service for natural language processing using Hugging Face API
/// Classifies text as task or event and extracts relevant entities
class NlpService {
  late final Dio _hfDio; // For Hugging Face classification
  late final Dio _localDio; // For local NLP server parsing
  final String _apiKey;

  NlpService({String? apiKey})
      : _apiKey = apiKey ?? AppConfig.huggingFaceApiKey {
    // Hugging Face API client
    _hfDio = Dio(
      BaseOptions(
        baseUrl: AppConfig.huggingFaceBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    // Local NLP server client
    _localDio = Dio(
      BaseOptions(
        baseUrl: AppConfig.nlpServerBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  /// Classify text as either "task" or "event" using zero-shot classification
  /// Returns the classification result with confidence score
  Future<ClassificationResult> classifyText(String text) async {
    if (_apiKey.isEmpty) {
      throw NlpServiceException('Hugging Face API key is not configured');
    }

    const url = '/hf-inference/models/${AppConfig.hfClassificationModel}';

    try {
      Logger.debugWithTag('NLP', 'Classifying text: "$text"');

      final response = await _hfDio.post(
        url,
        data: {
          'inputs': text,
          'parameters': {
            'candidate_labels': ['task', 'event'],
          },
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
          },
        ),
      );

      final data = response.data;
      Logger.debugWithTag('NLP', 'Classification response: $data');
      Logger.debugWithTag('NLP', 'Response type: ${data.runtimeType}');

      // Parse zero-shot classification response
      // Router format: [{"label": "event", "score": 0.85}, {"label": "task", "score": 0.15}]
      // Standard format: {"sequence": "...", "labels": ["task", "event"], "scores": [0.8, 0.2]}

      // Try router format (array of label-score pairs)
      if (data is List && data.isNotEmpty) {
        final items = data.cast<Map<String, dynamic>>();

        // Find highest scoring item
        var maxItem = items[0];
        double maxScore = (maxItem['score'] as num).toDouble();

        for (var item in items.skip(1)) {
          final score = (item['score'] as num).toDouble();
          if (score > maxScore) {
            maxScore = score;
            maxItem = item;
          }
        }

        final result = ClassificationResult(
          type: maxItem['label'] as String,
          confidence: maxScore,
          allScores: {
            for (final item in items)
              (item['label'] as String): (item['score'] as num).toDouble(),
          },
        );

        Logger.infoWithTag('NLP',
            'Classified as: ${result.type} (${(result.confidence * 100).toStringAsFixed(1)}%)');
        return result;
      }

      // Try standard format (map with labels and scores arrays)
      if (data is Map<String, dynamic> &&
          data.containsKey('labels') &&
          data.containsKey('scores')) {
        final labels = (data['labels'] as List).cast<String>();
        final scores = (data['scores'] as List).cast<num>();

        Logger.debugWithTag('NLP', 'Labels: $labels');
        Logger.debugWithTag('NLP', 'Scores: $scores');

        // Find the highest scoring label
        int maxIndex = 0;
        double maxScore = scores[0].toDouble();
        for (int i = 1; i < scores.length; i++) {
          if (scores[i] > maxScore) {
            maxScore = scores[i].toDouble();
            maxIndex = i;
          }
        }

        final result = ClassificationResult(
          type: labels[maxIndex],
          confidence: maxScore,
          allScores: Map.fromIterables(
            labels,
            scores.map((s) => s.toDouble()),
          ),
        );

        Logger.infoWithTag('NLP',
            'Classified as: ${result.type} (${(result.confidence * 100).toStringAsFixed(1)}%)');
        return result;
      }

      // If we get here, the format is unexpected
      Logger.errorWithTag(
          'NLP', 'Unexpected response format. Full response: $data');
      throw NlpServiceException(
          'Unexpected response format from classification API. Response: ${data.toString().substring(0, 200)}...');
    } on DioException catch (e) {
      Logger.errorWithTag('NLP', 'Classification failed: ${e.message}');

      // Handle model loading (cold start)
      if (e.response?.statusCode == 503) {
        final data = e.response?.data;
        if (data is Map &&
            data['error']?.toString().contains('loading') == true) {
          throw NlpServiceException(
            'Model is loading, please try again in a few seconds',
            isRetryable: true,
          );
        }
      }

      // Handle invalid/expired API key
      if (e.response?.statusCode == 410 || e.response?.statusCode == 401) {
        throw NlpServiceException(
          'Invalid API key. Please update your Hugging Face API key in app_config.dart',
        );
      }

      throw NlpServiceException('Failed to classify text: ${e.message}');
    } catch (e) {
      Logger.errorWithTag('NLP', 'Classification error: $e');
      throw NlpServiceException('Classification error: $e');
    }
  }

  /// Parse event details using local T5 model
  /// Returns structured event data from natural language input
  Future<Map<String, dynamic>> parseEvent(String text) async {
    try {
      Logger.debugWithTag('NLP', 'Parsing event: "$text"');

      // The hosted NLP API protects /parse/* with a bearer token.
      // Dev-only: hardcoded bearer token (token expiry risk is accepted).
      const token = AppConfig.nlpParseBearerTokenDev;
      if (token.isEmpty) {
        throw NlpServiceException(
          'NLP parse bearer token dev value is empty. Update AppConfig.nlpParseBearerTokenDev.',
          isRetryable: false,
        );
      }

      final response = await _localDio.post(
        'parse/event',
        data: {'text': text},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      Logger.debugWithTag('NLP', 'Event parsed: ${response.data}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      Logger.errorWithTag('NLP', 'Event parsing failed: ${e.message}');

      if (e.response?.statusCode == 401) {
        throw NlpServiceException(
          'Unauthorized: NLP parse API rejected the bearer token. Update AppConfig.nlpParseBearerTokenDev with a valid (non-expired) token.',
          isRetryable: false,
        );
      }

      if (e.response?.statusCode == 503) {
        throw NlpServiceException(
          'Event parsing model not loaded on server',
          isRetryable: false,
        );
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NlpServiceException(
          'Connection timeout. Please ensure the NLP server is running on ${AppConfig.nlpServerBaseUrl}',
          isRetryable: true,
        );
      }

      if (e.type == DioExceptionType.connectionError) {
        throw NlpServiceException(
          'Cannot connect to NLP server at ${AppConfig.nlpServerBaseUrl}. Please start the server.',
          isRetryable: true,
        );
      }

      throw NlpServiceException('Failed to parse event: ${e.message}');
    } catch (e) {
      Logger.errorWithTag('NLP', 'Event parsing error: $e');
      throw NlpServiceException('Event parsing error: $e');
    }
  }

  /// Parse task details using local T5 model
  /// Returns structured task data from natural language input
  Future<Map<String, dynamic>> parseTask(String text) async {
    try {
      Logger.debugWithTag('NLP', 'Parsing task: "$text"');

      // See `parseEvent` for why we attach the bearer token here.
      const token = AppConfig.nlpParseBearerTokenDev;
      if (token.isEmpty) {
        throw NlpServiceException(
          'NLP parse bearer token dev value is empty. Update AppConfig.nlpParseBearerTokenDev.',
          isRetryable: false,
        );
      }

      final response = await _localDio.post(
        'parse/task',
        data: {'text': text},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      Logger.debugWithTag('NLP', 'Task parsed: ${response.data}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      Logger.errorWithTag('NLP', 'Task parsing failed: ${e.message}');

      if (e.response?.statusCode == 401) {
        throw NlpServiceException(
          'Unauthorized: NLP parse API rejected the bearer token. Update AppConfig.nlpParseBearerTokenDev with a valid (non-expired) token.',
          isRetryable: false,
        );
      }

      if (e.response?.statusCode == 503) {
        throw NlpServiceException(
          'Task parsing model not loaded on server',
          isRetryable: false,
        );
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NlpServiceException(
          'Connection timeout. Please ensure the NLP server is running on ${AppConfig.nlpServerBaseUrl}',
          isRetryable: true,
        );
      }

      if (e.type == DioExceptionType.connectionError) {
        throw NlpServiceException(
          'Cannot connect to NLP server at ${AppConfig.nlpServerBaseUrl}. Please start the server.',
          isRetryable: true,
        );
      }

      throw NlpServiceException('Failed to parse task: ${e.message}');
    } catch (e) {
      Logger.errorWithTag('NLP', 'Task parsing error: $e');
      throw NlpServiceException('Task parsing error: $e');
    }
  }

  void dispose() {
    _hfDio.close();
    _localDio.close();
  }
}

/// Result of text classification
class ClassificationResult {
  final String type;
  final double confidence;
  final Map<String, double> allScores;

  const ClassificationResult({
    required this.type,
    required this.confidence,
    required this.allScores,
  });

  @override
  String toString() {
    return 'ClassificationResult(type: $type, confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
  }
}

/// Exception thrown by NlpService
class NlpServiceException implements Exception {
  final String message;
  final bool isRetryable;

  NlpServiceException(this.message, {this.isRetryable = false});

  @override
  String toString() => 'NlpServiceException: $message';
}
