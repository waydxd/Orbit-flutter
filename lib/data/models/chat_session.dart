import 'package:equatable/equatable.dart';

/// Represents a chat session containing multiple messages
class ChatSession extends Equatable {
  final String sessionId;
  final String userId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;

  const ChatSession({
    required this.sessionId,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messageCount,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      sessionId: json['session_id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? 'New Chat',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      messageCount: json['message_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'session_id': sessionId,
        'user_id': userId,
        'title': title,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'message_count': messageCount,
      };

  ChatSession copyWith({
    String? sessionId,
    String? userId,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? messageCount,
  }) {
    return ChatSession(
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messageCount: messageCount ?? this.messageCount,
    );
  }

  @override
  List<Object?> get props => [
        sessionId,
        userId,
        title,
        createdAt,
        updatedAt,
        messageCount,
      ];
}
