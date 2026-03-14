import '../../core/view_models/base_view_model.dart';
import '../../../data/repositories/calendar_repository.dart';
import '../../../data/models/event_model.dart';
import '../../../data/models/task_model.dart';
import '../../../data/services/api_client.dart';
import '../../../utils/logger.dart';

class CalendarViewModel extends BaseViewModel {
  final CalendarRepository _calendarRepository;

  List<EventModel> _events = [];
  List<TaskModel> _tasks = [];

  List<EventModel> get events => _events;
  List<TaskModel> get tasks => _tasks;

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
        notifyListeners();
        Logger.infoWithTag(
          'CalendarViewModel',
          'Data fetch complete: ${_events.length} events, ${_tasks.length} tasks',
        );
      } catch (e) {
        Logger.errorWithTag('CalendarViewModel', 'Fetch all failed: $e');
        rethrow;
      }
    });
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

  Future<void> updateTask(TaskModel task) async {
    final result = await executeAsync(() async {
      await _calendarRepository.updateTask(task);
      await fetchAll(userId: task.userId); // Refresh data after update
      return true;
    });
    if (result == null && error != null) {
      throw Exception(error);
    }
  }

  Future<void> deleteTask(String taskId) async {
    await executeAsync(() async {
      await _calendarRepository.deleteTask(taskId);
      // Remove from local list to update UI immediately
      _tasks.removeWhere((task) => task.id == taskId);
      notifyListeners();
    });
  }

  void reorderTasks(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final task = _tasks.removeAt(oldIndex);
    _tasks.insert(newIndex, task);
    notifyListeners();
    // Optional: Call API to persist reordering if supported by backend.
  }
}
