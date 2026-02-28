import 'package:dio/dio.dart';
import '../../config/app_config.dart';
import '../../utils/logger.dart';

/// Service for natural language processing using Hugging Face API
/// Classifies text as task or event and extracts relevant entities
class NlpService {
  late final Dio _dio;
  final String _apiKey;

  NlpService({String? apiKey}) : _apiKey = apiKey ?? AppConfig.huggingFaceApiKey {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.huggingFaceBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
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

    final url = '/hf-inference/models/${AppConfig.hfClassificationModel}';
    
    try {
      Logger.debugWithTag('NLP', 'Classifying text: "$text"');
      
      final response = await _dio.post(
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
          allScores: Map.fromIterable(
            items,
            key: (item) => item['label'] as String,
            value: (item) => (item['score'] as num).toDouble(),
          ),
        );
        
        Logger.infoWithTag('NLP', 'Classified as: ${result.type} (${(result.confidence * 100).toStringAsFixed(1)}%)');
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
        
        Logger.infoWithTag('NLP', 'Classified as: ${result.type} (${(result.confidence * 100).toStringAsFixed(1)}%)');
        return result;
      }

      // If we get here, the format is unexpected
      Logger.errorWithTag('NLP', 'Unexpected response format. Full response: $data');
      throw NlpServiceException('Unexpected response format from classification API. Response: ${data.toString().substring(0, 200)}...');
    } on DioException catch (e) {
      Logger.errorWithTag('NLP', 'Classification failed: ${e.message}');
      
      // Handle model loading (cold start)
      if (e.response?.statusCode == 503) {
        final data = e.response?.data;
        if (data is Map && data['error']?.toString().contains('loading') == true) {
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


  void dispose() {
    _dio.close();
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

