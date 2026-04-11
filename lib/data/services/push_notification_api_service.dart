import '../../utils/logger.dart';
import 'api_client.dart';

/// Service for interacting with the Orbit-core push notification API.
/// Handles subscribing/unsubscribing to event and task reminders.
class PushNotificationApiService {
  final ApiClient _api;

  PushNotificationApiService(this._api);

  /// Subscribe to push reminders for a calendar event.
  ///
  /// [eventId] - the event UUID.
  /// [eventStartAt] - ISO-8601 start time of the event.
  /// [location] - optional event location string for ETA-based scheduling.
  /// [offsetMinutes] - optional override (negative = before start).
  Future<bool> subscribeToEvent(
    String eventId, {
    required DateTime eventStartAt,
    String? location,
    int? offsetMinutes,
  }) async {
    try {
      final body = <String, dynamic>{
        'event_start_at': eventStartAt.toUtc().toIso8601String(),
      };
      if (location != null) body['location'] = location;
      if (offsetMinutes != null) body['offset_minutes'] = offsetMinutes;

      await _api.post('/events/$eventId/notify', data: body);
      Logger.infoWithTag('PushAPI', 'Subscribed to event $eventId');
      return true;
    } catch (e) {
      Logger.errorWithTag('PushAPI', 'Subscribe event failed', e);
      return false;
    }
  }

  /// Unsubscribe from push reminders for a calendar event.
  Future<bool> unsubscribeFromEvent(String eventId) async {
    try {
      await _api.delete('/events/$eventId/notify');
      Logger.infoWithTag('PushAPI', 'Unsubscribed from event $eventId');
      return true;
    } catch (e) {
      Logger.errorWithTag('PushAPI', 'Unsubscribe event failed', e);
      return false;
    }
  }

  /// Subscribe to push reminders for a task.
  ///
  /// [taskId] - the task UUID.
  /// [taskDueAt] - ISO-8601 due time of the task.
  /// [offsetMinutes] - optional override (negative = before due).
  Future<bool> subscribeToTask(
    String taskId, {
    required DateTime taskDueAt,
    int? offsetMinutes,
  }) async {
    try {
      final body = <String, dynamic>{
        'task_due_at': taskDueAt.toUtc().toIso8601String(),
      };
      if (offsetMinutes != null) body['offset_minutes'] = offsetMinutes;

      await _api.post('/tasks/$taskId/notify', data: body);
      Logger.infoWithTag('PushAPI', 'Subscribed to task $taskId');
      return true;
    } catch (e) {
      Logger.errorWithTag('PushAPI', 'Subscribe task failed', e);
      return false;
    }
  }

  /// Unsubscribe from push reminders for a task.
  Future<bool> unsubscribeFromTask(String taskId) async {
    try {
      await _api.delete('/tasks/$taskId/notify');
      Logger.infoWithTag('PushAPI', 'Unsubscribed from task $taskId');
      return true;
    } catch (e) {
      Logger.errorWithTag('PushAPI', 'Unsubscribe task failed', e);
      return false;
    }
  }
}
