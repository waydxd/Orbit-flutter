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
  final List<String> imageUrls;
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
    this.imageUrls = const [],
  });

  static List<String> _parseImageUrls(dynamic v) {
    if (v == null) return const [];
    if (v is List) {
      return v
          .map((e) => e.toString())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static bool _jsonBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      return s == 'true' || s == '1';
    }
    return false;
  }

  static String _jsonString(dynamic v) {
    if (v == null) return '';
    if (v is String) return v;
    return v.toString();
  }

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
      isRecurring: _jsonBool(json['is_recurring'] ?? json['isRecurring']),
      recurrenceRule:
          _jsonString(json['recurrence_rule'] ?? json['recurrenceRule']),
      recurrenceException: _jsonString(
        json['recurrence_exception'] ?? json['recurrenceException'],
      ),
      imageUrls: _parseImageUrls(json['image_url']),
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
      if (imageUrls.isNotEmpty) 'image_url': imageUrls,
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
        imageUrls,
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
    List<String>? imageUrls,
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
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
