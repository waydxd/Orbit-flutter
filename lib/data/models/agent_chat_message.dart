import 'package:equatable/equatable.dart';

/// Context types for AI agent processing
enum AgentContextType {
  calendar,
  tasks,
  general,
}

extension AgentContextTypeExtension on AgentContextType {
  String get value {
    switch (this) {
      case AgentContextType.calendar:
        return 'calendar';
      case AgentContextType.tasks:
        return 'tasks';
      case AgentContextType.general:
        return 'general';
    }
  }

  static AgentContextType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'calendar':
        return AgentContextType.calendar;
      case 'tasks':
        return AgentContextType.tasks;
      default:
        return AgentContextType.general;
    }
  }
}

/// Agent type returned from the AI agent
enum AgentType {
  calendarAssistant,
  taskAssistant,
  generalAssistant,
}

extension AgentTypeExtension on AgentType {
  String get displayName {
    switch (this) {
      case AgentType.calendarAssistant:
        return 'Orbi';
      case AgentType.taskAssistant:
        return 'Task Assistant';
      case AgentType.generalAssistant:
        return 'Assistant';
    }
  }

  static AgentType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'calendar_assistant':
        return AgentType.calendarAssistant;
      case 'task_assistant':
        return AgentType.taskAssistant;
      default:
        return AgentType.generalAssistant;
    }
  }
}

/// Extended chat message that includes agent information
class AgentChatMessage extends Equatable {
  final String id;
  final String conversationId;
  final String content;
  final bool isUser;
  final AgentType? agentType;
  final DateTime timestamp;
  final bool isLoading;
  final String? errorMessage;

  // Action-related fields for Agent mode
  final String? actionId;
  final String? actionType;
  final String? actionSummary;
  final String? actionStatus; // 'pending', 'confirmed', 'cancelled', 'expired'

  const AgentChatMessage({
    required this.id,
    required this.conversationId,
    required this.content,
    required this.isUser,
    required this.timestamp, this.agentType,
    this.isLoading = false,
    this.errorMessage,
    this.actionId,
    this.actionType,
    this.actionSummary,
    this.actionStatus,
  });

  /// Check if this message has a pending action
  bool get hasPendingAction => actionId != null && actionStatus == 'pending';

  /// Check if this message has any action
  bool get hasAction => actionId != null;

  factory AgentChatMessage.user({
    required String id,
    required String conversationId,
    required String content,
    DateTime? timestamp,
  }) {
    return AgentChatMessage(
      id: id,
      conversationId: conversationId,
      content: content,
      isUser: true,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  factory AgentChatMessage.agent({
    required String id,
    required String conversationId,
    required String content,
    required AgentType agentType,
    DateTime? timestamp,
  }) {
    return AgentChatMessage(
      id: id,
      conversationId: conversationId,
      content: content,
      isUser: false,
      agentType: agentType,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  factory AgentChatMessage.agentWithAction({
    required String id,
    required String conversationId,
    required String content,
    required AgentType agentType,
    required String actionId,
    required String actionType,
    String? actionSummary,
    String actionStatus = 'pending',
    DateTime? timestamp,
  }) {
    return AgentChatMessage(
      id: id,
      conversationId: conversationId,
      content: content,
      isUser: false,
      agentType: agentType,
      timestamp: timestamp ?? DateTime.now(),
      actionId: actionId,
      actionType: actionType,
      actionSummary: actionSummary,
      actionStatus: actionStatus,
    );
  }

  factory AgentChatMessage.loading({
    required String id,
    required String conversationId,
  }) {
    return AgentChatMessage(
      id: id,
      conversationId: conversationId,
      content: '',
      isUser: false,
      isLoading: true,
      timestamp: DateTime.now(),
    );
  }

  factory AgentChatMessage.fromJson(Map<String, dynamic> json) {
    // Support both backend format (role/sender_id) and local cache format (is_user)
    bool isUser;
    if (json.containsKey('is_user')) {
      isUser = json['is_user'] == true;
    } else if (json.containsKey('role')) {
      isUser = json['role'] == 'user';
    } else {
      isUser = json['sender_id'] != null;
    }

    return AgentChatMessage(
      id: json['id'] ?? '',
      conversationId: json['conversation_id'] ?? '',
      content: json['content'] ?? '',
      isUser: isUser,
      agentType: json['agent_type'] != null
          ? AgentTypeExtension.fromString(json['agent_type'])
          : null,
      timestamp: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      actionId: json['action_id'],
      actionType: json['action_type'],
      actionSummary: json['action_summary'],
      actionStatus: json['action_status'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversation_id': conversationId,
        'content': content,
        'is_user': isUser,
        'agent_type': agentType?.name,
        'created_at': timestamp.toIso8601String(),
        if (actionId != null) 'action_id': actionId,
        if (actionType != null) 'action_type': actionType,
        if (actionSummary != null) 'action_summary': actionSummary,
        if (actionStatus != null) 'action_status': actionStatus,
      };

  AgentChatMessage copyWith({
    String? id,
    String? conversationId,
    String? content,
    bool? isUser,
    AgentType? agentType,
    DateTime? timestamp,
    bool? isLoading,
    String? errorMessage,
    String? actionId,
    String? actionType,
    String? actionSummary,
    String? actionStatus,
  }) {
    return AgentChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      agentType: agentType ?? this.agentType,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      actionId: actionId ?? this.actionId,
      actionType: actionType ?? this.actionType,
      actionSummary: actionSummary ?? this.actionSummary,
      actionStatus: actionStatus ?? this.actionStatus,
    );
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        content,
        isUser,
        agentType,
        timestamp,
        isLoading,
        errorMessage,
        actionId,
        actionType,
        actionSummary,
        actionStatus,
      ];
}
