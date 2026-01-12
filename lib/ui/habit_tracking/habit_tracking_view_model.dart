import '../core/ui/base_view_model.dart';
import '../../data/models/habit_suggestion.dart';
import '../../data/services/habit_tracking_service.dart';

/// ViewModel for habit tracking feature
class HabitTrackingViewModel extends BaseViewModel {
  final HabitTrackingService _service;
  final String userId;

  List<HabitSuggestion> _suggestions = [];

  HabitTrackingViewModel({
    required this.userId,
    HabitTrackingService? service,
  }) : _service = service ?? HabitTrackingService();

  /// List of habit suggestions
  List<HabitSuggestion> get suggestions => _suggestions;

  /// Whether there are any suggestions
  bool get hasSuggestions => _suggestions.isNotEmpty;

  /// Number of pending suggestions
  int get suggestionsCount => _suggestions.length;

  /// Load habit suggestions from the backend
  Future<void> loadSuggestions() async {
    await executeAsync(() async {
      _suggestions = await _service.getSuggestions(userId);
      notifyListeners();
      return _suggestions;
    });
  }

  /// Accept a habit suggestion (creates 5-year recurring events)
  Future<int?> acceptSuggestion(int habitId) async {
    final response = await executeAsync(() async {
      return await _service.acceptSuggestion(
        userId: userId,
        habitId: habitId,
      );
    });

    if (response != null) {
      // Remove the accepted suggestion from the list
      _suggestions.removeWhere((s) => s.habitId == habitId);
      notifyListeners();
      return response.eventsCreated;
    }
    return null;
  }

  /// Dismiss a habit suggestion
  Future<bool> dismissSuggestion(int habitId) async {
    final result = await executeAsync(() async {
      await _service.dismissSuggestion(habitId);
      return true;
    });

    if (result == true) {
      // Remove the dismissed suggestion from the list
      _suggestions.removeWhere((s) => s.habitId == habitId);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Record an event for habit tracking
  /// Call this when a user creates/saves an event
  Future<void> recordEvent({
    required String title,
    String? description,
    required DateTime startDateTime,
    required DateTime endDateTime,
    String? location,
  }) async {
    try {
      await _service.recordEvent(
        userId: userId,
        title: title,
        description: description,
        startTime: _formatTime(startDateTime),
        endTime: _formatTime(endDateTime),
        dayOfWeek: startDateTime.weekday % 7, // Convert to 0-6 (Sun-Sat)
        location: location,
      );
    } catch (e) {
      // Log error but don't fail the main event creation
      // This is a background operation
      print('Habit tracking record failed: $e');
    }
  }

  /// Format time as HH:MM
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

