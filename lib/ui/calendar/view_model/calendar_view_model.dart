import '../../core/view_models/base_view_model.dart';
import '../../../data/repositories/calendar_repository.dart';
import '../../../data/models/event_model.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/habit_suggestion.dart';
import '../../../data/services/api_client.dart';
import '../../../utils/logger.dart';

class CalendarViewModel extends BaseViewModel {
  final CalendarRepository _calendarRepository;

  List<EventModel> _events = [];
  List<TaskModel> _tasks = [];
  List<HabitSuggestion> _habitSuggestions = [];

  List<EventModel> get events => _events;
  List<TaskModel> get tasks => _tasks;
  List<HabitSuggestion> get habitSuggestions => _habitSuggestions;

  /// Whether there are any pending habit suggestions
  bool get hasHabitSuggestions => _habitSuggestions.isNotEmpty;

  /// Number of pending habit suggestions
  int get habitSuggestionsCount => _habitSuggestions.length;

  CalendarViewModel({CalendarRepository? calendarRepository})
      : _calendarRepository =
            calendarRepository ?? CalendarRepository(ApiClient());

  Future<void> fetchEvents({
    required String userId,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    await executeAsync(() async {
      final fetchedEvents = await _calendarRepository.getEvents(
        userId: userId,
        startTime: startTime,
        endTime: endTime,
      );
      _events = fetchedEvents;
      notifyListeners();
    });
  }

  Future<void> fetchTasks({required String userId, bool? completed}) async {
    await executeAsync(() async {
      final fetchedTasks = await _calendarRepository.getTasks(
        userId: userId,
        completed: completed,
      );
      _tasks = fetchedTasks;
      notifyListeners();
    });
  }

  Future<void> fetchAll({required String userId}) async {
    await executeAsync(() async {
      try {
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        final endOfMonth = startOfDay.add(const Duration(days: 30));

        // Fetch events and tasks together – these are critical
        final results = await Future.wait([
          _calendarRepository.getEvents(
            userId: userId,
            startTime: startOfDay,
            endTime: endOfMonth,
          ),
          _calendarRepository.getTasks(userId: userId),
        ]);
        _events = results[0] as List<EventModel>;
        _tasks = results[1] as List<TaskModel>;

        // Fetch habit suggestions separately so a failure here does not
        // break the loading of events and tasks.
        try {
          _habitSuggestions = await _calendarRepository.getHabitSuggestions();
        } catch (e) {
          Logger.errorWithTag(
            'CalendarViewModel',
            'Failed to fetch habit suggestions (non-fatal): $e',
          );
          _habitSuggestions = [];
        }

        notifyListeners();
        Logger.infoWithTag(
          'CalendarViewModel',
          'Data fetch complete: ${_events.length} events, ${_tasks.length} tasks, ${_habitSuggestions.length} suggestions',
        );
      } catch (e) {
        Logger.errorWithTag('CalendarViewModel', 'Fetch all failed: $e');
        rethrow;
      }
    });
  }

  /// Get habit suggestions that match a specific date (by day of week)
  List<HabitSuggestion> suggestionsForDay(DateTime date) {
    return _habitSuggestions
        .where((s) => s.matchesDate(date) && s.isValid)
        .toList();
  }

  /// Accept a habit suggestion
  Future<AcceptSuggestionResponse?> acceptHabitSuggestion(
    String suggestionId, {
    String? userId,
  }) async {
    final response = await executeAsync(() async {
      return await _calendarRepository.acceptHabitSuggestion(suggestionId);
    }, showLoading: false);

    if (response != null && response.success) {
      _habitSuggestions.removeWhere((s) => s.id == suggestionId);
      notifyListeners();
      // Refresh all data if userId is available so the new recurring event shows
      if (userId != null) {
        await fetchAll(userId: userId);
      }
    }
    return response;
  }

  /// Reject/dismiss a habit suggestion
  Future<bool> dismissHabitSuggestion(String suggestionId) async {
    final result = await executeAsync(() async {
      await _calendarRepository.rejectHabitSuggestion(suggestionId);
      return true;
    }, showLoading: false);

    if (result == true) {
      _habitSuggestions.removeWhere((s) => s.id == suggestionId);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> createEvent(EventModel event) async {
    final result = await executeAsync(() async {
      await _calendarRepository.createEvent(event);
      await fetchAll(userId: event.userId); // Refresh data after creation
      return true;
    });

    if (result == null && error != null) {
      throw Exception(error);
    }
  }

  Future<void> createTask(TaskModel task) async {
    final result = await executeAsync(() async {
      await _calendarRepository.createTask(task);
      await fetchAll(userId: task.userId); // Refresh data after creation
      return true;
    });

    if (result == null && error != null) {
      throw Exception(error);
    }
  }

  Future<void> updateEvent(EventModel event) async {
    final result = await executeAsync(() async {
      await _calendarRepository.updateEvent(event);
      await fetchAll(userId: event.userId); // Refresh data after update
      return true;
    });
    if (result == null && error != null) {
      throw Exception(error);
    }
  }

  Future<void> deleteEvent(String eventId) async {
    await executeAsync(() async {
      await _calendarRepository.deleteEvent(eventId);
      // Remove from local list to update UI immediately
      _events.removeWhere((event) => event.id == eventId);
      notifyListeners();
    });
  }
}
