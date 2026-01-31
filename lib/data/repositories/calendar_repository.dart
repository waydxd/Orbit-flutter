import '../models/event_model.dart';
import '../models/task_model.dart';
import '../services/api_client.dart';
import '../../utils/logger.dart';

class CalendarRepository {
  final ApiClient _apiClient;

  CalendarRepository(this._apiClient);

  /// Format DateTime for API (without milliseconds)
  String _formatDateTime(DateTime dt) {
    return dt.toUtc().toIso8601String().split('.')[0] + 'Z';
  }

  Future<List<EventModel>> getEvents({
    required String userId,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      final queryParams = {'user_id': userId};
      if (startTime != null) {
        queryParams['start_time'] = _formatDateTime(startTime);
      }
      if (endTime != null) {
        queryParams['end_time'] = _formatDateTime(endTime);
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
}
