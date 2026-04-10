import 'package:dio/dio.dart';

import '../models/event_model.dart';
import '../models/habit_suggestion.dart';
import '../models/task_model.dart';
import '../services/api_client.dart';
import '../services/txt2img_service.dart';
import '../../utils/logger.dart';

class CalendarRepository {
  CalendarRepository(this._apiClient);

  final ApiClient _apiClient;

  static const int _maxEventImageBytes = 5 * 1024 * 1024;

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

  Future<TaskModel> updateTask(TaskModel task) async {
    try {
      final response = await _apiClient.put(
        '/calendar/tasks/${task.id}',
        data: task.toJson(),
      );

      Logger.infoWithTag(
        'CalendarRepository',
        'PUT /calendar/tasks/${task.id} status: ${response.statusCode}',
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        return TaskModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to update task: ${response.statusCode}');
    } catch (e) {
      Logger.errorWithTag('CalendarRepository', 'Failed to update task: $e');
      rethrow;
    }
  }

  /// Lists stored image URLs for an event (`GET /events/{id}/images`).
  Future<List<String>> listEventImages(String eventId) async {
    try {
      final response = await _apiClient.get('/events/$eventId/images');
      Logger.infoWithTag(
        'CalendarRepository',
        'GET /events/$eventId/images status: ${response.statusCode}',
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final raw = (response.data as Map<String, dynamic>)['images'];
        if (raw is List) {
          return raw
              .map((e) => e.toString())
              .where((s) => s.isNotEmpty)
              .toList();
        }
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      Logger.errorWithTag('CalendarRepository', 'listEventImages failed: $e');
      rethrow;
    } catch (e) {
      Logger.errorWithTag('CalendarRepository', 'listEventImages failed: $e');
      rethrow;
    }
  }

  /// Uploads local image bytes (e.g. gallery) via `POST /events/{id}/images`.
  /// Returns the API path from the response (e.g. `/api/v1/assets/events/...`).
  Future<String> uploadEventImageFromBytes({
    required String eventId,
    required List<int> bytes,
    String filename = 'upload.jpg',
  }) {
    return _postEventImageMultipart(
      eventId: eventId,
      bytes: bytes,
      filename: filename,
    );
  }

  /// Downloads from [imageUrl] (e.g. fal) and uploads binary via `POST /events/{id}/images`.
  Future<String> uploadEventCoverFromGeneratedUrl({
    required String eventId,
    required String imageUrl,
    String? declaredContentType,
  }) async {
    final bytes = await Txt2ImgService.downloadImageBytes(imageUrl);
    if (bytes == null || bytes.isEmpty) {
      throw Exception('Failed to download generated image');
    }
    final filename =
        Txt2ImgService.coverFilenameForContentType(declaredContentType);
    return _postEventImageMultipart(
      eventId: eventId,
      bytes: bytes,
      filename: filename,
    );
  }

  Future<String> _postEventImageMultipart({
    required String eventId,
    required List<int> bytes,
    required String filename,
  }) async {
    if (bytes.isEmpty) {
      throw Exception('Image is empty');
    }
    if (bytes.length > _maxEventImageBytes) {
      throw Exception('Image exceeds 5 MB upload limit');
    }
    try {
      final response = await _apiClient.post(
        '/events/$eventId/images',
        data: FormData.fromMap({
          'image': MultipartFile.fromBytes(bytes, filename: filename),
        }),
      );
      Logger.infoWithTag(
        'CalendarRepository',
        'POST /events/$eventId/images status: ${response.statusCode}',
      );
      if ((response.statusCode == 201 || response.statusCode == 200) &&
          response.data is Map<String, dynamic>) {
        final u =
            (response.data as Map<String, dynamic>)['url']?.toString().trim();
        if (u != null && u.isNotEmpty) return u;
      }
      throw Exception('Failed to upload event image: ${response.statusCode}');
    } catch (e) {
      Logger.errorWithTag('CalendarRepository', 'upload event image failed: $e');
      rethrow;
    }
  }

  /// Persists a generated cover: download from CDN then `POST /events/{id}/images`.
  Future<void> attachEventCoverUrl({
    required String eventId,
    required String imageUrl,
    String? declaredContentType,
  }) async {
    await uploadEventCoverFromGeneratedUrl(
      eventId: eventId,
      imageUrl: imageUrl,
      declaredContentType: declaredContentType,
    );
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

  Future<void> deleteTask(String taskId) async {
    try {
      final response = await _apiClient.delete('/calendar/tasks/$taskId');
      Logger.infoWithTag(
        'CalendarRepository',
        'DELETE /calendar/tasks/$taskId status: ${response.statusCode}',
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete task: ${response.statusCode}');
      }
    } catch (e) {
      Logger.errorWithTag('CalendarRepository', 'Failed to delete task: $e');
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
  Future<AcceptSuggestionResponse> acceptHabitSuggestion(String id,
      {int? years, int? weeks}) async {
    try {
      final Map<String, dynamic> data = {};
      if (years != null) data['years'] = years;
      if (weeks != null) data['weeks'] = weeks;

      final response = await _apiClient.post(
        '/habit/suggestions/$id/accept',
        data: data.isNotEmpty ? data : null,
      );

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
