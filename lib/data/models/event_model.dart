import 'base_model.dart';

class EventModel extends BaseModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final List<String> hashtags;
  final bool isRecurring;
  final String recurrenceRule;
  final String recurrenceException;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EventModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.createdAt,
    required this.updatedAt,
    this.hashtags = const [],
    this.isRecurring = false,
    this.recurrenceRule = '',
    this.recurrenceException = '',
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      startTime: DateTime.parse(json['start_time'] as String).toLocal(),
      endTime: DateTime.parse(json['end_time'] as String).toLocal(),
      location: json['location'] as String? ?? '',
      hashtags: json['hashtags'] != null
          ? List<String>.from(json['hashtags'] as List)
          : const [],
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurrenceRule: json['recurrence_rule'] as String? ?? '',
      recurrenceException: json['recurrence_exception'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
      'location': location,
      'hashtags': hashtags,
      'is_recurring': isRecurring,
      'recurrence_rule': recurrenceRule,
      'recurrence_exception': recurrenceException,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        description,
        startTime,
        endTime,
        location,
        hashtags,
        isRecurring,
        recurrenceRule,
        recurrenceException,
        createdAt,
        updatedAt,
      ];

  EventModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    List<String>? hashtags,
    bool? isRecurring,
    String? recurrenceRule,
    String? recurrenceException,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      hashtags: hashtags ?? this.hashtags,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      recurrenceException: recurrenceException ?? this.recurrenceException,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
