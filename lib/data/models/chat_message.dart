import 'package:equatable/equatable.dart';
import 'chat_action.dart';

/// Role of a message sender
enum MessageRole { user, assistant, system }

/// Represents a single chat message
class ChatMessage extends Equatable {
  final String messageId;
  final String sessionId;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final List<ChatAction>? actions;
  final bool isStreaming;

  const ChatMessage({
    required this.messageId,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.actions,
    this.isStreaming = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      messageId: json['message_id'] ?? '',
      sessionId: json['session_id'] ?? '',
      role: MessageRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => MessageRole.assistant,
      ),
      content: json['content'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      actions: json['actions'] != null
          ? (json['actions'] as List)
              .map((a) => ChatAction.fromJson(Map<String, dynamic>.from(a)))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'message_id': messageId,
        'session_id': sessionId,
        'role': role.name,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'actions': actions?.map((a) => a.toJson()).toList(),
      };

  ChatMessage copyWith({
    String? messageId,
    String? sessionId,
    MessageRole? role,
    String? content,
    DateTime? timestamp,
    List<ChatAction>? actions,
    bool? isStreaming,
  }) {
    return ChatMessage(
      messageId: messageId ?? this.messageId,
      sessionId: sessionId ?? this.sessionId,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      actions: actions ?? this.actions,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  @override
  List<Object?> get props => [
        messageId,
        sessionId,
        role,
        content,
        timestamp,
        actions,
        isStreaming,
      ];
}
