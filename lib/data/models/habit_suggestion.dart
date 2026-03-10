import 'base_model.dart';

/// Model representing a habit suggestion from the backend API
class HabitSuggestion extends BaseModel {
  final String id;
  final String title;
  final String? description;
  final String? location;
  final int durationMinutes;
  final String timeOfDay;
  final String dayOfWeek;
  final String status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String message;

  const HabitSuggestion({
    required this.id,
    required this.title,
    required this.durationMinutes,
    required this.timeOfDay,
    required this.dayOfWeek,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.message,
    this.description,
    this.location,
  });

  factory HabitSuggestion.fromJson(Map<String, dynamic> json) {
    return HabitSuggestion(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      durationMinutes: json['duration_minutes'] as int? ?? 0,
      timeOfDay: json['time_of_day'] as String? ?? '',
      dayOfWeek: json['day_of_week'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      expiresAt: DateTime.parse(json['expires_at'] as String).toLocal(),
      message: json['message'] as String? ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'duration_minutes': durationMinutes,
      'time_of_day': timeOfDay,
      'day_of_week': dayOfWeek,
      'status': status,
      'created_at': createdAt.toUtc().toIso8601String(),
      'expires_at': expiresAt.toUtc().toIso8601String(),
      'message': message,
    };
  }

  /// Parse timeOfDay string (e.g. "7:30 AM") into minutes from midnight
  int get timeOfDayMinutes {
    try {
      final cleaned = timeOfDay.trim().toUpperCase();
      final match = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)?').firstMatch(cleaned);
      if (match == null) return 0;

      int hours = int.parse(match.group(1)!);
      final int minutes = int.parse(match.group(2)!);
      final String? period = match.group(3);

      if (period != null) {
        if (period == 'PM' && hours != 12) hours += 12;
        if (period == 'AM' && hours == 12) hours = 0;
      }

      return hours * 60 + minutes;
    } catch (_) {
      return 0;
    }
  }

  /// Parse dayOfWeek string (e.g. "Monday") into weekday int (DateTime.monday=1 .. DateTime.sunday=7)
  int get dayOfWeekIndex {
    const map = {
      'monday': DateTime.monday,
      'tuesday': DateTime.tuesday,
      'wednesday': DateTime.wednesday,
      'thursday': DateTime.thursday,
      'friday': DateTime.friday,
      'saturday': DateTime.saturday,
      'sunday': DateTime.sunday,
    };
    return map[dayOfWeek.trim().toLowerCase()] ?? DateTime.monday;
  }

  /// Get the start hour as a double for timetable positioning
  double get startHour {
    final mins = timeOfDayMinutes;
    return mins / 60.0;
  }

  /// Get the end hour as a double for timetable positioning
  double get endHour {
    final mins = timeOfDayMinutes + durationMinutes;
    return mins / 60.0;
  }

  /// Check if this suggestion matches a given date's day of week
  bool matchesDate(DateTime date) {
    return date.weekday == dayOfWeekIndex;
  }

  /// Whether this suggestion is still valid (not expired)
  bool get isValid => expiresAt.isAfter(DateTime.now());

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        location,
        durationMinutes,
        timeOfDay,
        dayOfWeek,
        status,
        createdAt,
        expiresAt,
        message,
      ];
}

/// Response model for accepting a habit suggestion
class AcceptSuggestionResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? recurringEvent;

  const AcceptSuggestionResponse({
    required this.success,
    required this.message,
    this.recurringEvent,
  });

  factory AcceptSuggestionResponse.fromJson(Map<String, dynamic> json) {
    return AcceptSuggestionResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      recurringEvent: json['recurring_event'] as Map<String, dynamic>?,
    );
  }
}

