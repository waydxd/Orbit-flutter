import '../../core/view_models/base_view_model.dart';
import '../../../core/services/app_settings_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../data/repositories/calendar_repository.dart';
import '../../../data/models/event_model.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/habit_suggestion.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/push_notification_api_service.dart';
import '../../../utils/logger.dart';

/// Visible event query window: month of [anchor] ±7 days, or full [anchor].year ±7 days.
(DateTime start, DateTime end) eventQueryRange(DateTime anchor,
    {bool fullYear = false}) {
  if (fullYear) {
    final y = anchor.year;
    final start = DateTime(y, 1, 1).subtract(const Duration(days: 7));
    final end = DateTime(y, 12, 31, 23, 59, 59).add(const Duration(days: 7));
    return (start, end);
  }
  final y = anchor.year;
  final m = anchor.month;
  final first = DateTime(y, m, 1);
  final last = DateTime(y, m + 1, 0, 23, 59, 59);
  final start = first.subtract(const Duration(days: 7));
  final end = last.add(const Duration(days: 7));
  return (start, end);
}

/// Union of [eventQueryRange] for each anchor (widest start .. widest end).
(DateTime start, DateTime end) unionEventQueryRange(
  Iterable<DateTime> anchors, {
  bool fullYear = false,
}) {
  DateTime? minStart;
  DateTime? maxEnd;
  for (final a in anchors) {
    final (s, e) = eventQueryRange(a, fullYear: fullYear);
    final ms = minStart;
    final me = maxEnd;
    minStart = ms == null || s.isBefore(ms) ? s : ms;
    maxEnd = me == null || e.isAfter(me) ? e : me;
  }
  return (minStart!, maxEnd!);
}

class CalendarViewModel extends BaseViewModel {
  late final CalendarRepository _calendarRepository;
  late final PushNotificationApiService _pushApi;
  final NotificationService _notificationService;
  final AppSettingsService _appSettings;

  List<EventModel> _events = [];
  List<TaskModel> _tasks = [];
  List<HabitSuggestion> _habitSuggestions = [];

  /// Last anchor used for a successful event list fetch (calendar focused month/year).
  DateTime? _lastEventFetchAnchor;
  bool _lastFetchFullYear = false;

  List<EventModel> get events => _events;
  List<TaskModel> get tasks => _tasks;
  List<HabitSuggestion> get habitSuggestions => _habitSuggestions;

  /// Whether there are any pending habit suggestions
  bool get hasHabitSuggestions => _habitSuggestions.isNotEmpty;

  /// Number of pending habit suggestions
  int get habitSuggestionsCount => _habitSuggestions.length;

  CalendarViewModel({
    CalendarRepository? calendarRepository,
    NotificationService? notificationService,
    ApiClient? apiClient,
    PushNotificationApiService? pushNotificationApiService,
    AppSettingsService? appSettingsService,
  })  : _notificationService = notificationService ?? NotificationService(),
        _appSettings = appSettingsService ?? AppSettingsService() {
    final client = apiClient ?? ApiClient();
    _calendarRepository = calendarRepository ?? CalendarRepository(client);
    _pushApi = pushNotificationApiService ?? PushNotificationApiService(client);
  }

  /// Registers (or refreshes) the server-side FCM reminder at 15 minutes before [event] start.
  Future<void> _syncServerEventReminder(EventModel event) async {
    if (!await _appSettings.getEventNotificationsEnabled()) {
      await _pushApi.unsubscribeFromEvent(event.id);
      return;
    }
    final reminderUtc =
        event.startTime.toUtc().subtract(const Duration(minutes: 15));
    if (!reminderUtc.isAfter(DateTime.now().toUtc())) {
      await _pushApi.unsubscribeFromEvent(event.id);
      return;
    }
    await _pushApi.unsubscribeFromEvent(event.id);
    final loc = event.location.trim();
    await _pushApi.subscribeToEvent(
      event.id,
      eventStartAt: event.startTime,
      location: loc.isNotEmpty ? loc : null,
    );
  }

  Future<void> _removeServerEventReminder(String eventId) async {
    await _pushApi.unsubscribeFromEvent(eventId);
  }

  // Schedule a notification 30 minutes before the task's due date.
  Future<void> _scheduleTaskNotification(TaskModel task) async {
    if (task.dueDate == null || task.completed) return;

    final notificationTime =
        task.dueDate!.subtract(const Duration(minutes: 30));
    if (notificationTime.isBefore(DateTime.now())) return;

    // Use task id hash as notification id for easy lookup/cancellation later.
    final notificationId = task.id.hashCode;

    await _notificationService.scheduleNotification(
      id: notificationId,
      title: 'Task Due Soon',
      body: '"${task.title}" is due in 30 minutes',
      scheduledTime: notificationTime,
    );

    Logger.infoWithTag(
      'CalendarViewModel',
      'Scheduled notification for task ${task.id} at $notificationTime',
    );
  }

  // Cancel notification for a task.
  Future<void> _cancelTaskNotification(String taskId) async {
    final notificationId = taskId.hashCode;
    await _notificationService.cancelNotification(notificationId);
    Logger.infoWithTag(
      'CalendarViewModel',
      'Cancelled notification for task $taskId',
    );
  }

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

  /// Re-fetch tasks without showing the full-screen loading spinner.
  /// Intended for pull-to-refresh so the existing list stays visible.
  Future<void> refreshTasks({required String userId, bool? completed}) async {
    await executeAsync(() async {
      final fetchedTasks = await _calendarRepository.getTasks(
        userId: userId,
        completed: completed,
      );
      _tasks = fetchedTasks;
      notifyListeners();
    }, showLoading: false);
  }

  Future<void> fetchAll({
    required String userId,
    DateTime? eventRangeAnchor,
    List<DateTime> mergeEventAnchors = const [],
    bool fullYearRange = false,
    bool showLoading = true,
  }) async {
    await executeAsync(() async {
      try {
        final primary = eventRangeAnchor ?? DateTime.now();
        final anchors = <DateTime>[primary, ...mergeEventAnchors];
        final (rangeStart, rangeEnd) = anchors.length == 1
            ? eventQueryRange(primary, fullYear: fullYearRange)
            : unionEventQueryRange(anchors, fullYear: fullYearRange);

        // Fetch events and tasks together – these are critical
        final results = await Future.wait([
          _calendarRepository.getEvents(
            userId: userId,
            startTime: rangeStart,
            endTime: rangeEnd,
          ),
          _calendarRepository.getTasks(userId: userId),
        ]);
        _events = results[0] as List<EventModel>;
        _tasks = results[1] as List<TaskModel>;
        _lastEventFetchAnchor = primary;
        _lastFetchFullYear = fullYearRange;

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

        // Schedule notifications for tasks with due dates that aren't completed
        for (final task in _tasks) {
          if (task.dueDate != null && !task.completed) {
            await _scheduleTaskNotification(task);
          }
        }
      } catch (e) {
        Logger.errorWithTag('CalendarViewModel', 'Fetch all failed: $e');
        rethrow;
      }
    }, showLoading: showLoading);
  }

  /// Loads events/tasks without [executeAsync] (for use inside another async op).
  Future<void> _reloadEventsAndTasksQuiet({
    required String userId,
    required List<DateTime> anchors,
    bool fullYearRange = false,
  }) async {
    final (rangeStart, rangeEnd) = anchors.length == 1
        ? eventQueryRange(anchors.first, fullYear: fullYearRange)
        : unionEventQueryRange(anchors, fullYear: fullYearRange);
    final results = await Future.wait([
      _calendarRepository.getEvents(
        userId: userId,
        startTime: rangeStart,
        endTime: rangeEnd,
      ),
      _calendarRepository.getTasks(userId: userId),
    ]);
    _events = results[0] as List<EventModel>;
    _tasks = results[1] as List<TaskModel>;
    _lastEventFetchAnchor = anchors.first;
    _lastFetchFullYear = fullYearRange;
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
    for (final task in _tasks) {
      if (task.dueDate != null && !task.completed) {
        await _scheduleTaskNotification(task);
      }
    }
  }

  /// Get habit suggestions that match a specific date (by day of week)
  List<HabitSuggestion> suggestionsForDay(DateTime date) {
    return _habitSuggestions.where((s) {
      if (!s.isValid) return false;

      final matchingEvents = _events.where((e) {
        if (e.title.trim().toLowerCase() != s.title.trim().toLowerCase()) {
          return false;
        }
        final dMinutes = e.endTime.difference(e.startTime).inMinutes;
        if (dMinutes != s.durationMinutes) {
          return false;
        }
        final tOfDay = e.startTime.hour * 60 + e.startTime.minute;
        if (tOfDay != s.timeOfDayMinutes) {
          return false;
        }
        return true;
      }).toList();

      DateTime? latestDate;
      if (matchingEvents.isNotEmpty) {
        matchingEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
        final latestEvent = matchingEvents.last;
        latestDate = DateTime(
          latestEvent.startTime.year,
          latestEvent.startTime.month,
          latestEvent.startTime.day,
        ).add(const Duration(days: 7));
      } else if (s.suggestedStartTime != null) {
        latestDate = DateTime(
          s.suggestedStartTime!.year,
          s.suggestedStartTime!.month,
          s.suggestedStartTime!.day,
        );
      }

      if (latestDate != null) {
        return date.year == latestDate.year &&
            date.month == latestDate.month &&
            date.day == latestDate.day;
      }

      return false;
    }).toList();
  }

  Future<AcceptSuggestionResponse?> acceptHabitSuggestion(
    String suggestionId, {
    String? userId,
    int? years,
    int? weeks,
  }) async {
    final response = await executeAsync(() async {
      return await _calendarRepository.acceptHabitSuggestion(suggestionId,
          years: years, weeks: weeks);
    }, showLoading: false);

    if (response != null && response.success) {
      _habitSuggestions.removeWhere((s) => s.id == suggestionId);
      notifyListeners();
      if (userId != null) {
        await fetchAll(userId: userId);
      }
    }
    return response;
  }

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

  Future<EventModel> createEvent(EventModel event) async {
    final result = await executeAsync(() async {
      final created = await _calendarRepository.createEvent(event);
      final anchors = <DateTime>[
        _lastEventFetchAnchor ?? DateTime.now(),
        created.startTime,
      ];
      await _reloadEventsAndTasksQuiet(
        userId: event.userId,
        anchors: anchors,
        fullYearRange: _lastFetchFullYear,
      );
      await _syncServerEventReminder(created);
      return created;
    });

    if (result == null) {
      throw Exception(error ?? 'Failed to create event');
    }
    return result;
  }

  /// Creates many events with one calendar reload (e.g. materialized recurrence).
  Future<List<EventModel>> createEvents(List<EventModel> events) async {
    if (events.isEmpty) {
      return [];
    }
    final userId = events.first.userId;
    final result = await executeAsync(() async {
      final created = <EventModel>[];
      for (final e in events) {
        final c = await _calendarRepository.createEvent(e);
        created.add(c);
        await _syncServerEventReminder(c);
      }
      final anchors = <DateTime>[
        _lastEventFetchAnchor ?? DateTime.now(),
        ...created.map((c) => c.startTime),
      ];
      await _reloadEventsAndTasksQuiet(
        userId: userId,
        anchors: anchors,
        fullYearRange: _lastFetchFullYear,
      );
      return created;
    });

    if (result == null) {
      throw Exception(error ?? 'Failed to create events');
    }
    return result;
  }

  /// Downloads the generated image and uploads via `POST /events/{id}/images`, then refreshes the calendar.
  Future<void> attachEventCoverUrl({
    required String eventId,
    required String imageUrl,
    required String userId,
    String? declaredContentType,
  }) async {
    final result = await executeAsync(
      () async {
        await _calendarRepository.attachEventCoverUrl(
          eventId: eventId,
          imageUrl: imageUrl,
          declaredContentType: declaredContentType,
        );
        await fetchAll(
          userId: userId,
          eventRangeAnchor: _lastEventFetchAnchor ?? DateTime.now(),
          fullYearRange: _lastFetchFullYear,
          showLoading: false,
        );
        return true;
      },
      showLoading: false,
    );

    if (result == null) {
      throw Exception(error ?? 'Failed to attach cover');
    }
  }

  Future<void> createTask(TaskModel task) async {
    final result = await executeAsync(() async {
      await _calendarRepository.createTask(task);
      await fetchAll(
        userId: task.userId,
        eventRangeAnchor: _lastEventFetchAnchor ?? DateTime.now(),
        fullYearRange: _lastFetchFullYear,
        showLoading: false,
      ); // Refresh data after creation
      return true;
    });

    if (result == null && error != null) {
      throw Exception(error);
    }

    // Schedule notification if task has a due date
    if (task.dueDate != null && !task.completed) {
      await _scheduleTaskNotification(task);
    }
  }

  Future<void> updateEvent(EventModel event) async {
    final result = await executeAsync(() async {
      await _calendarRepository.updateEvent(event);
      await _reloadEventsAndTasksQuiet(
        userId: event.userId,
        anchors: <DateTime>[
          _lastEventFetchAnchor ?? DateTime.now(),
          event.startTime,
        ],
        fullYearRange: _lastFetchFullYear,
      );
      await _syncServerEventReminder(event);
      return true;
    });
    if (result == null && error != null) {
      throw Exception(error);
    }
  }

  Future<void> updateTask(TaskModel task) async {
    // Find the old task to check if due date or completion changed
    final oldTask = _tasks.firstWhere(
      (t) => t.id == task.id,
      orElse: () => task,
    );

    final result = await executeAsync(() async {
      await _calendarRepository.updateTask(task);
      await fetchAll(
        userId: task.userId,
        eventRangeAnchor: _lastEventFetchAnchor ?? DateTime.now(),
        fullYearRange: _lastFetchFullYear,
        showLoading: false,
      ); // Refresh data after update
      return true;
    });
    if (result == null && error != null) {
      throw Exception(error);
    }

    // Handle notification updates based on task changes
    if (task.completed) {
      // Task was completed - cancel the notification
      await _cancelTaskNotification(task.id);
    } else if (task.dueDate != oldTask.dueDate ||
        task.completed != oldTask.completed) {
      // Due date changed or was uncompleted - reschedule notification
      await _cancelTaskNotification(task.id);
      if (task.dueDate != null) {
        await _scheduleTaskNotification(task);
      }
    }
  }

  Future<void> deleteEvent(String eventId) async {
    final result = await executeAsync(() async {
      await _removeServerEventReminder(eventId);
      await _calendarRepository.deleteEvent(eventId);
      // Remove from local list to update UI immediately
      _events.removeWhere((event) => event.id == eventId);
      notifyListeners();
      return true;
    });

    if (result == null && error != null) {
      throw Exception(error);
    }
  }

  Future<void> deleteTask(String taskId) async {
    // Cancel notification before deleting
    await _cancelTaskNotification(taskId);

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
