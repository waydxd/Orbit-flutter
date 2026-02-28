import 'package:uuid/uuid.dart';
import 'base_model.dart';

class ChatMessage extends BaseModel {
  static const _uuid = Uuid();

  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  bool get isUser => role == 'user';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? _uuid.v4(),
      role: json['role'] as String,
      content: json['content'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'content': content,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, role, content, createdAt];
}
