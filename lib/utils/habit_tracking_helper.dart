import '../data/services/habit_tracking_service.dart';

/// Helper class for recording events for habit tracking
///
/// Use this helper when creating/saving events to automatically
/// record them for habit pattern detection.
///
/// Example usage:
/// ```dart
/// final helper = HabitTrackingHelper(habitTrackingService);
///
/// // After saving an event
/// await helper.recordEventForHabitTracking(
///   userId: currentUser.id,
///   title: event.title,
///   description: event.description,
///   startDateTime: event.startDateTime,
///   endDateTime: event.endDateTime,
///   location: event.location,
/// );
/// ```
class HabitTrackingHelper {
  final HabitTrackingService _service;

  HabitTrackingHelper(this._service);

  /// Factory constructor with default service
  factory HabitTrackingHelper.withDefaultService() {
    return HabitTrackingHelper(HabitTrackingService());
  }

  /// Extract time string from DateTime (HH:MM format)
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Record an event for habit tracking
  ///
  /// Call this after successfully creating/saving an event.
  /// This operation runs silently and won't fail the main event creation
  /// if there's an error recording the event for habit tracking.
  ///
  /// Parameters:
  /// - [userId]: The current user's ID
  /// - [title]: Event title
  /// - [description]: Optional event description
  /// - [startDateTime]: Event start date and time
  /// - [endDateTime]: Event end date and time
  /// - [location]: Optional event location
  Future<void> recordEventForHabitTracking({
    required String userId,
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
        // Convert DateTime.weekday (1-7, Mon-Sun) to 0-6 (Sun-Sat)
        dayOfWeek: startDateTime.weekday % 7,
        location: location,
      );
    } catch (e) {
      // Log error but don't fail the main event creation
      // This is a background operation that shouldn't affect user experience
      print('Habit tracking record failed: $e');
    }
  }

  /// Check if an event should be recorded for habit tracking
  ///
  /// Returns true if the event has valid data for habit tracking
  bool shouldRecordEvent({
    required String title,
    required DateTime startDateTime,
    required DateTime endDateTime,
  }) {
    // Must have a title
    if (title.trim().isEmpty) return false;

    // End time must be after start time
    if (!endDateTime.isAfter(startDateTime)) return false;

    return true;
  }
}

