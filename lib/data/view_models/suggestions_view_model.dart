import '../../ui/core/view_models/base_view_model.dart';
import '../models/suggestion_model.dart';
import '../models/event_model.dart';
import '../services/suggestions_service.dart';
import '../../utils/logger.dart';

/// ViewModel for managing AI-generated suggestions for events
class SuggestionsViewModel extends BaseViewModel {
  final SuggestionsService _suggestionsService;

  // Cache of suggestions by event ID
  final Map<String, SuggestionResponse> _suggestionsCache = {};

  // Current event's suggestions
  SuggestionResponse _currentSuggestions = SuggestionResponse.empty();
  String? _currentEventId;

  SuggestionResponse get suggestions => _currentSuggestions;
  String? get currentEventId => _currentEventId;

  bool get hasSuggestions => _currentSuggestions.suggestions.isNotEmpty;
  bool get isFetchingSuggestions => _currentSuggestions.isLoading;
  String? get suggestionsError => _currentSuggestions.error;

  SuggestionsViewModel({SuggestionsService? suggestionsService})
      : _suggestionsService = suggestionsService ?? SuggestionsService();

  /// Fetch suggestions for an event
  Future<void> fetchSuggestions({
    required EventModel event,
    String? accessToken,
    bool forceRefresh = false,
  }) async {
    // Check cache first
    if (!forceRefresh && _suggestionsCache.containsKey(event.id)) {
      _currentEventId = event.id;
      _currentSuggestions = _suggestionsCache[event.id]!;
      notifyListeners();
      return;
    }

    // Set loading state
    _currentEventId = event.id;
    _currentSuggestions = SuggestionResponse.loading();
    notifyListeners();

    try {
      Logger.infoWithTag(
        'SuggestionsViewModel',
        'Fetching suggestions for event: ${event.title}',
      );

      final response = await _suggestionsService.getSuggestions(
        event: event,
        accessToken: accessToken,
      );

      // Update cache and current suggestions
      _suggestionsCache[event.id] = response;
      if (_currentEventId == event.id) {
        _currentSuggestions = response;
        notifyListeners();
      }

      Logger.infoWithTag(
        'SuggestionsViewModel',
        'Received ${response.suggestions.length} suggestions',
      );
    } catch (e) {
      Logger.errorWithTag(
        'SuggestionsViewModel',
        'Error fetching suggestions: $e',
      );
      if (_currentEventId == event.id) {
        _currentSuggestions = SuggestionResponse.error(e.toString());
        notifyListeners();
      }
    }
  }

  /// Get cached suggestions for an event
  SuggestionResponse? getCachedSuggestions(String eventId) {
    return _suggestionsCache[eventId];
  }

  /// Clear suggestions cache for an event
  void clearCache(String eventId) {
    _suggestionsCache.remove(eventId);
    if (_currentEventId == eventId) {
      _currentSuggestions = SuggestionResponse.empty();
      notifyListeners();
    }
  }

  /// Clear all cached suggestions
  void clearAllCache() {
    _suggestionsCache.clear();
    _currentSuggestions = SuggestionResponse.empty();
    _currentEventId = null;
    notifyListeners();
  }

  /// Get suggestions grouped by type
  Map<SuggestionType, List<SuggestionModel>> getSuggestionsGroupedByType() {
    final grouped = <SuggestionType, List<SuggestionModel>>{};
    for (final suggestion in _currentSuggestions.suggestions) {
      final type = SuggestionType.fromString(suggestion.type);
      grouped.putIfAbsent(type, () => []).add(suggestion);
    }
    return grouped;
  }

  @override
  void dispose() {
    _suggestionsService.dispose();
    super.dispose();
  }
}

