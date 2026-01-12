import 'base_model.dart';

/// Model representing a habit suggestion detected from recurring events
class HabitSuggestion extends BaseModel {
  final int habitId;
  final String title;
  final String? description;
  final String startTime;
  final String endTime;
  final int dayOfWeek;
  final String dayOfWeekName;
  final String? location;
  final int frequency;
  final DateTime lastOccurrence;

  const HabitSuggestion({
    required this.habitId,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.dayOfWeek,
    required this.dayOfWeekName,
    this.location,
    required this.frequency,
    required this.lastOccurrence,
  });

  factory HabitSuggestion.fromJson(Map<String, dynamic> json) {
    return HabitSuggestion(
      habitId: json['habit_id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      dayOfWeek: json['day_of_week'] as int,
      dayOfWeekName: json['day_of_week_name'] as String,
      location: json['location'] as String?,
      frequency: json['frequency'] as int,
      lastOccurrence: DateTime.parse(json['last_occurrence'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'habit_id': habitId,
      'title': title,
      'description': description,
      'start_time': startTime,
      'end_time': endTime,
      'day_of_week': dayOfWeek,
      'day_of_week_name': dayOfWeekName,
      'location': location,
      'frequency': frequency,
      'last_occurrence': lastOccurrence.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        habitId,
        title,
        description,
        startTime,
        endTime,
        dayOfWeek,
        dayOfWeekName,
        location,
        frequency,
        lastOccurrence,
      ];
}

/// Request model for recording an event
class RecordEventRequest {
  final String userId;
  final String title;
  final String? description;
  final String startTime;
  final String endTime;
  final int dayOfWeek;
  final String? location;

  const RecordEventRequest({
    required this.userId,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.dayOfWeek,
    this.location,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'title': title,
      'description': description,
      'start_time': startTime,
      'end_time': endTime,
      'day_of_week': dayOfWeek,
      'location': location,
    };
  }
}

/// Request model for accepting a habit suggestion
class AcceptSuggestionRequest {
  final String userId;
  final int habitId;

  const AcceptSuggestionRequest({
    required this.userId,
    required this.habitId,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'habit_id': habitId,
    };
  }
}

/// Response model for accept suggestion
class AcceptSuggestionResponse {
  final String message;
  final int eventsCreated;

  const AcceptSuggestionResponse({
    required this.message,
    required this.eventsCreated,
  });

  factory AcceptSuggestionResponse.fromJson(Map<String, dynamic> json) {
    return AcceptSuggestionResponse(
      message: json['message'] as String,
      eventsCreated: json['events_created'] as int,
    );
  }
}

