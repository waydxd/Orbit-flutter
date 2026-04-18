import 'package:equatable/equatable.dart';

/// Represents the result of parsing natural language input
/// into a structured task or event
class NlpParseResult extends Equatable {
  /// Type of the parsed result: "task" or "event"
  final String type;

  /// Extracted title for the task/event
  final String title;

  /// Optional description
  final String? description;

  /// Start time (for events)
  final DateTime? startTime;

  /// End time (for events)
  final DateTime? endTime;

  /// Due date (for tasks)
  final DateTime? dueDate;

  /// Location (primarily for events)
  final String? location;

  /// Recurrence pattern for events: "Daily", "Weekly", "Monthly", or null
  final String? recurrence;

  /// Priority level for tasks: "low", "medium", "high"
  final String priority;

  /// Confidence score of the classification (0.0 to 1.0)
  final double confidence;

  /// Original input text
  final String originalText;

  const NlpParseResult({
    required this.type,
    required this.title,
    required this.originalText,
    this.description,
    this.startTime,
    this.endTime,
    this.dueDate,
    this.location,
    this.recurrence,
    this.priority = 'medium',
    this.confidence = 0.0,
  });

  /// Returns true if this is classified as an event
  bool get isEvent => type == 'event';

  /// Returns true if this is classified as a task
  bool get isTask => type == 'task';

  factory NlpParseResult.fromJson(Map<String, dynamic> json) {
    return NlpParseResult(
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'] as String).toLocal()
          : null,
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String).toLocal()
          : null,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String).toLocal()
          : null,
      location: json['location'] as String?,
      recurrence: json['recurrence'] as String?,
      priority: json['priority'] as String? ?? 'medium',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      originalText: json['original_text'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'description': description,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'location': location,
      'recurrence': recurrence,
      'priority': priority,
      'confidence': confidence,
      'original_text': originalText,
    };
  }

  NlpParseResult copyWith({
    String? type,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? dueDate,
    String? location,
    String? recurrence,
    String? priority,
    double? confidence,
    String? originalText,
  }) {
    return NlpParseResult(
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      dueDate: dueDate ?? this.dueDate,
      location: location ?? this.location,
      recurrence: recurrence ?? this.recurrence,
      priority: priority ?? this.priority,
      confidence: confidence ?? this.confidence,
      originalText: originalText ?? this.originalText,
    );
  }

  @override
  List<Object?> get props => [
        type,
        title,
        description,
        startTime,
        endTime,
        dueDate,
        location,
        recurrence,
        priority,
        confidence,
        originalText,
      ];

  @override
  String toString() {
    return 'NlpParseResult(type: $type, title: $title, confidence: $confidence)';
  }
}
