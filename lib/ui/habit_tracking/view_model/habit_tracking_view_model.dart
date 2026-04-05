import '../../core/view_models/base_view_model.dart';
import '../../../data/models/habit_suggestion.dart';
import '../../../data/repositories/calendar_repository.dart';
import '../../../data/services/api_client.dart';

/// ViewModel for habit tracking feature
class HabitTrackingViewModel extends BaseViewModel {
  final CalendarRepository _repository;

  List<HabitSuggestion> _suggestions = [];

  HabitTrackingViewModel({
    CalendarRepository? repository,
  }) : _repository = repository ?? CalendarRepository(ApiClient());

  /// List of habit suggestions
  List<HabitSuggestion> get suggestions => _suggestions;

  /// Whether there are any suggestions
  bool get hasSuggestions => _suggestions.isNotEmpty;

  /// Number of pending suggestions
  int get suggestionsCount => _suggestions.length;

  /// Load habit suggestions from the backend
  Future<void> loadSuggestions() async {
    await executeAsync(() async {
      _suggestions = await _repository.getHabitSuggestions();
      notifyListeners();
      return _suggestions;
    });
  }

  /// Accept a habit suggestion (creates a recurring event on the backend)
  Future<AcceptSuggestionResponse?> acceptSuggestion(String suggestionId,
      {int? years, int? weeks}) async {
    final response = await executeAsync(() async {
      return await _repository.acceptHabitSuggestion(suggestionId,
          years: years, weeks: weeks);
    });

    if (response != null) {
      // Remove the accepted suggestion from the list
      _suggestions.removeWhere((s) => s.id == suggestionId);
      notifyListeners();
    }
    return response;
  }

  /// Reject/dismiss a habit suggestion
  Future<bool> dismissSuggestion(String suggestionId) async {
    final result = await executeAsync(() async {
      await _repository.rejectHabitSuggestion(suggestionId);
      return true;
    });

    if (result == true) {
      // Remove the rejected suggestion from the list
      _suggestions.removeWhere((s) => s.id == suggestionId);
      notifyListeners();
      return true;
    }
    return false;
  }
}
