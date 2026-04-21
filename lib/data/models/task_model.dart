import 'base_model.dart';

class TaskModel extends BaseModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime? dueDate;
  final bool completed;
  final String priority;
  final List<String> hashtags;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Parses API [due_date]; returns null for missing values or Go/sql zero sentinels.
  static DateTime? _parseDueDateFromJson(dynamic raw) {
    if (raw == null) return null;
    if (raw is! String || raw.isEmpty) return null;
    final dt = DateTime.parse(raw).toLocal();
    if (dt.year < 1970) return null;
    return dt;
  }

  const TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.dueDate,
    this.completed = false,
    this.priority = 'medium',
    this.hashtags = const [],
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      dueDate: _parseDueDateFromJson(json['due_date']),
      completed: json['completed'] as bool? ?? false,
      priority: json['priority'] as String? ?? 'medium',
      hashtags: json['hashtags'] != null
          ? List<String>.from(json['hashtags'] as List)
          : const [],
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
      'due_date': dueDate?.toUtc().toIso8601String(),
      'completed': completed,
      'priority': priority,
      'hashtags': hashtags,
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
        dueDate,
        completed,
        priority,
        hashtags,
        createdAt,
        updatedAt,
      ];

  TaskModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? completed,
    String? priority,
    List<String>? hashtags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      completed: completed ?? this.completed,
      priority: priority ?? this.priority,
      hashtags: hashtags ?? this.hashtags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
