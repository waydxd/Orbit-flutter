import 'base_model.dart';

class TaskModel extends BaseModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime? dueDate;
  final bool completed;
  final String priority;
  final DateTime createdAt;
  final DateTime updatedAt;

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
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      completed: json['completed'] as bool? ?? false,
      priority: json['priority'] as String? ?? 'medium',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'due_date': dueDate?.toIso8601String(),
      'completed': completed,
      'priority': priority,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
