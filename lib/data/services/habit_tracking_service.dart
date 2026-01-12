import 'package:dio/dio.dart';
import '../models/habit_suggestion.dart';
import 'api_client.dart';
import 'local_habit_tracking_service.dart';

/// Service for habit tracking API operations
/// Falls back to local storage when backend is unavailable
class HabitTrackingService {
  final ApiClient _apiClient;
  final LocalHabitTrackingService _localService;
  final bool _useLocalOnly;

  HabitTrackingService({
    ApiClient? apiClient,
    LocalHabitTrackingService? localService,
    bool useLocalOnly = true, // Default to local for demo
  })  : _apiClient = apiClient ?? ApiClient(),
        _localService = localService ?? LocalHabitTrackingService(),
        _useLocalOnly = useLocalOnly;

  /// Record an event for habit frequency tracking
  Future<void> recordEvent({
    required String userId,
    required String title,
    String? description,
    required String startTime,
    required String endTime,
    required int dayOfWeek,
    String? location,
  }) async {
    // Always record locally first
    await _localService.recordEvent(
      userId: userId,
      title: title,
      description: description,
      startTime: startTime,
      endTime: endTime,
      dayOfWeek: dayOfWeek,
      location: location,
    );

    // Try to sync with backend if not in local-only mode
    if (!_useLocalOnly) {
      try {
        final request = RecordEventRequest(
          userId: userId,
          title: title,
          description: description,
          startTime: startTime,
          endTime: endTime,
          dayOfWeek: dayOfWeek,
          location: location,
        );

        await _apiClient.post(
          '/habits/record',
          data: request.toJson(),
        );
      } catch (e) {
        // Backend failed, but local storage succeeded
        print('Backend sync failed, using local storage: $e');
      }
    }
  }

  /// Get habit suggestions for a user (events occurring 3+ times)
  Future<List<HabitSuggestion>> getSuggestions(String userId) async {
    // Use local service for suggestions
    if (_useLocalOnly) {
      return _localService.getSuggestions(userId);
    }

    // Try backend first, fall back to local
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/habits/suggestions/$userId',
      );

      final data = response.data;
      if (data != null && data['suggestions'] != null) {
        final suggestions = data['suggestions'] as List;
        return suggestions
            .map((json) => HabitSuggestion.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Backend failed, using local suggestions: $e');
      return _localService.getSuggestions(userId);
    }
  }

  /// Accept a habit suggestion (creates 5-year recurring events)
  Future<AcceptSuggestionResponse> acceptSuggestion({
    required String userId,
    required int habitId,
  }) async {
    // Use local service
    if (_useLocalOnly) {
      return _localService.acceptSuggestion(
        userId: userId,
        habitId: habitId,
      );
    }

    // Try backend first, fall back to local
    try {
      final request = AcceptSuggestionRequest(
        userId: userId,
        habitId: habitId,
      );

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/habits/accept',
        data: request.toJson(),
      );

      if (response.data != null) {
        return AcceptSuggestionResponse.fromJson(response.data!);
      }
      throw Exception('Failed to accept suggestion: empty response');
    } catch (e) {
      print('Backend failed, using local accept: $e');
      return _localService.acceptSuggestion(
        userId: userId,
        habitId: habitId,
      );
    }
  }

  /// Dismiss a habit suggestion
  Future<void> dismissSuggestion(int habitId) async {
    // Use local service
    if (_useLocalOnly) {
      return _localService.dismissSuggestion(habitId);
    }

    // Try backend first, fall back to local
    try {
      await _apiClient.delete('/habits/dismiss/$habitId');
    } catch (e) {
      print('Backend failed, using local dismiss: $e');
      await _localService.dismissSuggestion(habitId);
    }
  }
}
