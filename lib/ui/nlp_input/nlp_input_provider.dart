import 'package:flutter/foundation.dart';
import '../../data/models/nlp_parse_result.dart';
import '../../data/services/nlp_service.dart';

/// State management for NLP input feature
class NlpInputProvider extends ChangeNotifier {
  final NlpService _nlpService;
  
  NlpInputProvider({String? apiKey}) 
      : _nlpService = NlpService(apiKey: apiKey);

  NlpParseResult? _result;
  bool _isLoading = false;
  String? _error;

  NlpParseResult? get result => _result;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasResult => _result != null;
  bool get hasError => _error != null;

  /// Classify natural language input as task or event
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
      final classification = await _nlpService.classifyText(text);
      _result = NlpParseResult(
        type: classification.type,
        title: text,
        confidence: classification.confidence,
        originalText: text,
      );
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

