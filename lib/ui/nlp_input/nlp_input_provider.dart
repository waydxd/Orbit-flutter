import 'package:flutter/foundation.dart';
import '../../data/models/nlp_parse_result.dart';
import '../../data/services/nlp_service.dart';

/// State management for NLP input feature
class NlpInputProvider extends ChangeNotifier {
  final NlpService _nlpService;

  NlpInputProvider({String? apiKey}) : _nlpService = NlpService(apiKey: apiKey);

  NlpParseResult? _result;
  bool _isLoading = false;
  String? _error;

  NlpParseResult? get result => _result;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasResult => _result != null;
  bool get hasError => _error != null;

  /// Classify natural language input as task or event, then parse details
  Future<void> parseInput(String text) async {
    if (text.trim().isEmpty) {
      _error = 'Please enter some text';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    _result = null;
    notifyListeners();

    try {
      // Step 1: Classify as task or event
      final classification = await _nlpService.classifyText(text);

      // Step 2: Parse details using local server
      Map<String, dynamic>? parsedData;
      try {
        if (classification.type == 'event') {
          parsedData = await _nlpService.parseEvent(text);
        } else {
          parsedData = await _nlpService.parseTask(text);
        }
      } on NlpServiceException catch (e) {
        // If parsing fails, log but continue with classification only
        print('Parsing failed (using classification only): ${e.message}');
        parsedData = null;
      }

      // Step 3: Build result
      _result = _buildParseResult(classification, text, parsedData);
      _error = null;
    } on NlpServiceException catch (e) {
      _error = e.message;
      _result = null;
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
      _result = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Build NlpParseResult from classification and optional parsed data
  NlpParseResult _buildParseResult(
    ClassificationResult classification,
    String text,
    Map<String, dynamic>? parsedData,
  ) {
    if (parsedData == null) {
      // Parsing failed or not available - return basic result
      return NlpParseResult(
        type: classification.type,
        title: text,
        confidence: classification.confidence,
        originalText: text,
      );
    }

    // Build result with parsed data
    if (classification.type == 'event') {
      final recurrenceRaw = parsedData['recurrence'] as String?;
      final recurrence = (recurrenceRaw == null || recurrenceRaw.isEmpty)
          ? null
          : recurrenceRaw;

      return NlpParseResult(
        type: classification.type,
        title: parsedData['title'] as String? ?? text,
        description: parsedData['description'] as String?,
        startTime: parsedData['start_time'] != null
            ? DateTime.parse(parsedData['start_time'] as String)
            : null,
        endTime: parsedData['end_time'] != null
            ? DateTime.parse(parsedData['end_time'] as String)
            : null,
        location: parsedData['location'] as String?,
        recurrence: recurrence,
        confidence: classification.confidence,
        originalText: text,
      );
    } else {
      // Task
      return NlpParseResult(
        type: classification.type,
        title: parsedData['title'] as String? ?? text,
        description: parsedData['description'] as String?,
        dueDate: parsedData['due_date'] != null
            ? DateTime.parse(parsedData['due_date'] as String)
            : null,
        priority: parsedData['priority'] as String? ?? 'medium',
        confidence: classification.confidence,
        originalText: text,
      );
    }
  }

  /// Clear the current result and error
  void clear() {
    _result = null;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _nlpService.dispose();
    super.dispose();
  }
}
