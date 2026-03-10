import '../models/event_model.dart';
import '../models/habit_suggestion.dart';
import '../models/task_model.dart';
import '../services/api_client.dart';
import '../../utils/logger.dart';

class CalendarRepository {
  final ApiClient _apiClient;

  CalendarRepository(this._apiClient);

  Future<List<EventModel>> getEvents({
    required String userId,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      final queryParams = {'user_id': userId};
      if (startTime != null) {
        queryParams['start_time'] = startTime.toUtc().toIso8601String();
      }
      if (endTime != null) {
        queryParams['end_time'] = endTime.toUtc().toIso8601String();
      }

      final response = await _apiClient.get(
        '/calendar/events',
        queryParameters: queryParams,
      );

      Logger.infoWithTag(
        'CalendarRepository',
        'GET /calendar/events status: ${response.statusCode}',
      );

      if (response.statusCode == 200 && response.data != null) {
        final dynamic rawData = response.data;
        if (rawData is List) {
          Logger.infoWithTag(
            'CalendarRepository',
            'Received ${rawData.length} events',
          );
          return rawData
              .map((json) => EventModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      Logger.errorWithTag('CalendarRepository', 'Failed to get events: $e');
      rethrow;
    }
  }

  Future<List<TaskModel>> getTasks({
    required String userId,
    bool? completed,
  }) async {
    try {
      final queryParams = {'user_id': userId};
      if (completed != null) {
        queryParams['completed'] = completed.toString();
      }

      final response = await _apiClient.get(
        '/calendar/tasks',
        queryParameters: queryParams,
      );

      Logger.infoWithTag(
        'CalendarRepository',
        'GET /calendar/tasks status: ${response.statusCode}',
      );

      if (response.statusCode == 200 && response.data != null) {
        final dynamic rawData = response.data;
        if (rawData is List) {
          Logger.infoWithTag(
            'CalendarRepository',
            'Received ${rawData.length} tasks',
          );
          return rawData
              .map((json) => TaskModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      Logger.errorWithTag('CalendarRepository', 'Failed to get tasks: $e');
      rethrow;
    }
  }

  Future<EventModel> createEvent(EventModel event) async {
    try {
      final response = await _apiClient.post(
        '/calendar/events',
        data: event.toJson(),
      );

      Logger.infoWithTag(
        'CalendarRepository',
        'POST /calendar/events status: ${response.statusCode}',
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        return EventModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to create event: ${response.statusCode}');
    } catch (e) {
      Logger.errorWithTag('CalendarRepository', 'Failed to create event: $e');
      rethrow;
    }
  }

  Future<TaskModel> createTask(TaskModel task) async {
    try {
      final response = await _apiClient.post(
        '/calendar/tasks',
        data: task.toJson(),
      );

      Logger.infoWithTag(
        'CalendarRepository',
        'POST /calendar/tasks status: ${response.statusCode}',
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        return TaskModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to create task: ${response.statusCode}');
    } catch (e) {
      Logger.errorWithTag('CalendarRepository', 'Failed to create task: $e');
      rethrow;
    }
  }

  Future<EventModel> updateEvent(EventModel event) async {
    try {
      final response = await _apiClient.put(
        '/calendar/events/${event.id}',
        data: event.toJson(),
      );

      Logger.infoWithTag(
        'CalendarRepository',
        'PUT /calendar/events/${event.id} status: ${response.statusCode}',
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        return EventModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to update event: ${response.statusCode}');
    } catch (e) {
      Logger.errorWithTag('CalendarRepository', 'Failed to update event: $e');
      rethrow;
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      final response = await _apiClient.delete('/calendar/events/$eventId');
      Logger.infoWithTag(
        'CalendarRepository',
        'DELETE /calendar/events/$eventId status: ${response.statusCode}',
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete event: ${response.statusCode}');
      }
    } catch (e) {
      Logger.errorWithTag('CalendarRepository', 'Failed to delete event: $e');
      rethrow;
    }
  }

  // ===== Habit Tracking Methods =====

  /// Get pending habit suggestions for the authenticated user.
  /// UserID is deduced from the bearer token on the backend.
  Future<List<HabitSuggestion>> getHabitSuggestions() async {
    try {
      final response = await _apiClient.get('/habit/suggestions');

      Logger.infoWithTag(
        'CalendarRepository',
        'GET /habit/suggestions status: ${response.statusCode}',
      );

      if (response.statusCode == 200 && response.data != null) {
        final dynamic rawData = response.data;
        if (rawData is List) {
          Logger.infoWithTag(
            'CalendarRepository',
            'Received ${rawData.length} habit suggestions',
          );
          return rawData
              .map((json) =>
                  HabitSuggestion.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      Logger.errorWithTag(
        'CalendarRepository',
        'Failed to get habit suggestions: $e',
      );
      // Return empty list instead of rethrowing so that the habit suggestions
      // failure does not break the entire fetchAll (events + tasks + suggestions).
      return [];
    }
  }

  /// Accept a habit suggestion and create a recurring event.
  Future<AcceptSuggestionResponse> acceptHabitSuggestion(String id) async {
    try {
      final response = await _apiClient.post('/habit/suggestions/$id/accept');

      Logger.infoWithTag(
        'CalendarRepository',
        'POST /habit/suggestions/$id/accept status: ${response.statusCode}',
      );

      if (response.statusCode == 200 && response.data != null) {
        return AcceptSuggestionResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
      throw Exception(
        'Failed to accept habit suggestion: ${response.statusCode}',
      );
    } catch (e) {
      Logger.errorWithTag(
        'CalendarRepository',
        'Failed to accept habit suggestion: $e',
      );
      rethrow;
    }
  }

  /// Reject a habit suggestion.
  Future<void> rejectHabitSuggestion(String id) async {
    try {
      final response = await _apiClient.post('/habit/suggestions/$id/reject');

      Logger.infoWithTag(
        'CalendarRepository',
        'POST /habit/suggestions/$id/reject status: ${response.statusCode}',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to reject habit suggestion: ${response.statusCode}',
        );
      }
    } catch (e) {
      Logger.errorWithTag(
        'CalendarRepository',
        'Failed to reject habit suggestion: $e',
      );
      rethrow;
    }
  }
}
