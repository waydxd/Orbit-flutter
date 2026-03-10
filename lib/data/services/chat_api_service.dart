import 'package:dio/dio.dart';
import '../models/chat_message.dart';
import 'api_client.dart';
import 'chat_exceptions.dart';
import '../../utils/logger.dart';

/// Response model for sending chat messages
/// POST /api/v1/chat/messages
/// Based on backend PostMessageResponse schema from service.go
class ChatMessageResponse {
  final String conversationId;
  final String reply;
  final String? proposedActionSummary;
  final String? actionId;
  final String correlationId;
  final Map<String, dynamic>? metadata;
  final ChatError? error;

  ChatMessageResponse({
    required this.conversationId,
    required this.reply,
    required this.correlationId, this.proposedActionSummary,
    this.actionId,
    this.metadata,
    this.error,
  });

  factory ChatMessageResponse.fromJson(Map<String, dynamic> json) {
    return ChatMessageResponse(
      conversationId: json['conversation_id'] ?? '',
      reply: json['reply'] ?? '',
      proposedActionSummary: json['proposed_action_summary'],
      actionId: json['action_id'],
      correlationId: json['correlation_id'] ?? '',
      metadata: json['metadata'] as Map<String, dynamic>?,
      error: json['error'] != null
          ? ChatError.fromJson(json['error'] as Map<String, dynamic>)
          : null,
    );
  }

  // For backwards compatibility
  String get messageId => correlationId;
  String get status => error == null ? 'sent' : 'failed';
  bool get isSuccess => error == null;
  bool get isFailed => status == 'failed';
  bool get hasProposedAction => actionId != null && proposedActionSummary != null;
}

/// Error model from backend ChatError schema
class ChatError {
  final int code;
  final String message;

  ChatError({
    required this.code,
    required this.message,
  });

  factory ChatError.fromJson(Map<String, dynamic> json) {
    return ChatError(
      code: json['code'] ?? 0,
      message: json['message'] ?? '',
    );
  }
}

/// Message model for conversation history
/// Based on backend ConversationResponse.messages schema
class ConversationMessage {
  final String id;
  final String conversationId;
  final String? userId;
  final String role; // 'user' or 'assistant'
  final String content;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  ConversationMessage({
    required this.id,
    required this.conversationId,
    required this.role, required this.content, required this.timestamp, this.userId,
    this.metadata,
  });

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      id: json['id'] ?? '',
      conversationId: json['conversation_id'] ?? '',
      userId: json['user_id'],
      role: json['role'] ?? 'user',
      content: json['content'] ?? '',
      metadata: json['metadata'] as Map<String, dynamic>?,
      timestamp: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}

/// Pending action model for conversation
/// Based on backend ConversationResponse.pending_actions schema
class ConversationPendingAction {
  final String actionId;
  final String? userId;
  final String? conversationId;
  final Map<String, dynamic>? proposedAction;
  final String type; // action_type e.g. 'create_event'
  final String? idempotencyKey;
  final String status; // 'pending', 'confirmed', 'cancelled', 'expired'
  final int? version;
  final String? correlationId;
  final Map<String, dynamic>? agentMetadata;
  final String? errorMessage;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;
  final ChatError? error;

  ConversationPendingAction({
    required this.actionId,
    required this.type, required this.status, this.userId,
    this.conversationId,
    this.proposedAction,
    this.idempotencyKey,
    this.version,
    this.correlationId,
    this.agentMetadata,
    this.errorMessage,
    this.createdAt,
    this.updatedAt,
    this.expiresAt,
    this.error,
  });

  factory ConversationPendingAction.fromJson(Map<String, dynamic> json) {
    return ConversationPendingAction(
      actionId: json['action_id'] ?? '',
      userId: json['user_id'],
      conversationId: json['conversation_id'],
      proposedAction: json['proposed_action'] as Map<String, dynamic>?,
      type: json['action_type'] ?? json['type'] ?? '',
      idempotencyKey: json['idempotency_key'],
      status: json['status'] ?? 'pending',
      version: json['version'],
      correlationId: json['correlation_id'],
      agentMetadata: json['agent_metadata'] as Map<String, dynamic>?,
      errorMessage: json['error_message'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      error: json['error'] != null
          ? ChatError.fromJson(json['error'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';
  bool get isExpired => status == 'expired';

  /// Get proposed action title if available
  String? get proposedTitle => proposedAction?['title'];

  /// Get proposed action start time if available
  int? get proposedStartTime => proposedAction?['start_time'];

  /// Get proposed action end time if available
  int? get proposedEndTime => proposedAction?['end_time'];
}

/// Response model for getting conversation details
/// GET /api/v1/chat/conversations/{conversation_id}
/// Based on backend ConversationResponse schema
class ConversationDetailResponse {
  final String conversationId;
  final String? userId;
  final List<ConversationMessage> messages;
  final List<ConversationPendingAction> pendingActions;
  final String status;

  ConversationDetailResponse({
    required this.conversationId,
    required this.messages, required this.pendingActions, this.userId,
    this.status = 'active',
  });

  factory ConversationDetailResponse.fromJson(Map<String, dynamic> json) {
    final messagesList = json['messages'] as List? ?? [];
    final actionsList = json['pending_actions'] as List? ?? [];

    return ConversationDetailResponse(
      conversationId: json['conversation_id'] ?? '',
      userId: json['user_id'],
      messages: messagesList
          .map((m) => ConversationMessage.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
      pendingActions: actionsList
          .map((a) => ConversationPendingAction.fromJson(Map<String, dynamic>.from(a)))
          .toList(),
      status: json['status'] ?? 'active',
    );
  }

  bool get hasPendingActions => pendingActions.any((a) => a.isPending);

  /// Get the first pending action that is still in 'pending' status
  ConversationPendingAction? get firstPendingAction {
    try {
      return pendingActions.firstWhere((a) => a.isPending);
    } catch (_) {
      return null;
    }
  }
}

/// Response model for getting action details
/// GET /api/v1/chat/actions/{action_id}
/// Based on backend ActionResponse schema from chat.yaml
class ActionDetailResponse {
  final String actionId;
  final String status;
  final String? actionType;
  final Map<String, dynamic>? proposedAction;
  final String? idempotencyKey;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final ChatError? error;

  ActionDetailResponse({
    required this.actionId,
    required this.status,
    this.actionType,
    this.proposedAction,
    this.idempotencyKey,
    this.createdAt,
    this.expiresAt,
    this.error,
  });

  factory ActionDetailResponse.fromJson(Map<String, dynamic> json) {
    return ActionDetailResponse(
      actionId: json['action_id'] ?? '',
      status: json['status'] ?? 'pending',
      actionType: json['action_type'],
      proposedAction: json['proposed_action'] as Map<String, dynamic>?,
      idempotencyKey: json['idempotency_key'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      error: json['error'] != null
          ? ChatError.fromJson(json['error'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';
  bool get isExpired => status == 'expired';
  bool get isFailed => status == 'failed';
}

/// Response model for confirming an action
/// POST /api/v1/chat/actions/{action_id}/confirm
/// Based on backend ConfirmActionResponse schema from chat.yaml
class ActionConfirmResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? result;
  final String? operationId;

  ActionConfirmResponse({
    required this.success,
    required this.message,
    this.result,
    this.operationId,
  });

  factory ActionConfirmResponse.fromJson(Map<String, dynamic> json) {
    return ActionConfirmResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      result: json['result'] as Map<String, dynamic>?,
      operationId: json['operation_id'],
    );
  }
}

/// Response model for cancelling an action
/// POST /api/v1/chat/actions/{action_id}/cancel
class ActionCancelResponse {
  final bool success;
  final String message;

  ActionCancelResponse({
    required this.success,
    required this.message,
  });

  factory ActionCancelResponse.fromJson(Map<String, dynamic> json) {
    return ActionCancelResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }
}

/// Response model for health check
/// GET /api/v1/chat/health
class ChatHealthResponse {
  final String status;
  final String? error;

  ChatHealthResponse({
    required this.status,
    this.error,
  });

  factory ChatHealthResponse.fromJson(Map<String, dynamic> json) {
    return ChatHealthResponse(
      status: json['status'] ?? 'unknown',
      error: json['error'],
    );
  }

  bool get isHealthy => status == 'healthy';
}

/// Response model for creating a conversation
/// POST /api/v1/chat/conversations
class CreateConversationResponse {
  final String conversationId;
  final String status;

  CreateConversationResponse({
    required this.conversationId,
    required this.status,
  });

  factory CreateConversationResponse.fromJson(Map<String, dynamic> json) {
    return CreateConversationResponse(
      conversationId: json['conversation_id'] ?? '',
      status: json['status'] ?? 'active',
    );
  }
}

/// Response model for deleting a conversation
/// DELETE /api/v1/chat/conversations/{conversation_id}
class DeleteConversationResponse {
  final bool success;
  final String message;

  DeleteConversationResponse({
    required this.success,
    required this.message,
  });

  factory DeleteConversationResponse.fromJson(Map<String, dynamic> json) {
    return DeleteConversationResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }
}

/// Chat metrics response
/// GET /api/v1/chat/metrics
/// Based on backend ChatMetrics schema
class ChatMetrics {
  final int paths;
  final int totalMessages;
  final int totalConversations;
  final int totalPendingActions;
  final int totalConfirmedActions;
  final int totalCancelledActions;
  final int totalExpiredActions;
  final int totalFailedActions;
  final int avgMessageLatencyMs;
  final int avgActionLatencyMs;
  final int confirmationRatePct;
  final double successRatePct;
  final int totalErrors;
  final int validationErrors;
  final int policyViolations;
  final int conflictErrors;
  final int messagesPerMinute;
  final double actionsPerMinute;

  ChatMetrics({
    required this.paths,
    required this.totalMessages,
    required this.totalConversations,
    required this.totalPendingActions,
    required this.totalConfirmedActions,
    required this.totalCancelledActions,
    required this.totalExpiredActions,
    required this.totalFailedActions,
    required this.avgMessageLatencyMs,
    required this.avgActionLatencyMs,
    required this.confirmationRatePct,
    required this.successRatePct,
    required this.totalErrors,
    required this.validationErrors,
    required this.policyViolations,
    required this.conflictErrors,
    required this.messagesPerMinute,
    required this.actionsPerMinute,
  });

  factory ChatMetrics.fromJson(Map<String, dynamic> json) {
    return ChatMetrics(
      paths: json['paths'] ?? 0,
      totalMessages: json['total_messages'] ?? 0,
      totalConversations: json['total_conversations'] ?? 0,
      totalPendingActions: json['total_pending_actions'] ?? 0,
      totalConfirmedActions: json['total_confirmed_actions'] ?? 0,
      totalCancelledActions: json['total_cancelled_actions'] ?? 0,
      totalExpiredActions: json['total_expired_actions'] ?? 0,
      totalFailedActions: json['total_failed_actions'] ?? 0,
      avgMessageLatencyMs: json['avg_message_latency_ms'] ?? 0,
      avgActionLatencyMs: json['avg_action_latency_ms'] ?? 0,
      confirmationRatePct: json['confirmation_rate_pct'] ?? 0,
      successRatePct: (json['success_rate_pct'] ?? 0).toDouble(),
      totalErrors: (json['total_errors'] ?? 0).toInt(),
      validationErrors: json['validation_errors'] ?? 0,
      policyViolations: json['policy_violations'] ?? 0,
      conflictErrors: json['conflict_errors'] ?? 0,
      messagesPerMinute: json['messages_per_minute'] ?? 0,
      actionsPerMinute: (json['actions_per_minute'] ?? 0).toDouble(),
    );
  }
}

// Keep legacy response models for backward compatibility
/// Response model for sent messages (legacy)
class SendMessageResponse {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String messageType;
  final DateTime createdAt;

  SendMessageResponse({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.messageType,
    required this.createdAt,
  });

  factory SendMessageResponse.fromJson(Map<String, dynamic> json) {
    return SendMessageResponse(
      id: json['id'] ?? '',
      conversationId: json['conversation_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      content: json['content'] ?? '',
      messageType: json['message_type'] ?? 'text',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}

/// Response model for agent responses (legacy)
class AgentResponse {
  final String id;
  final String conversationId;
  final String content;
  final String agentType;
  final DateTime createdAt;

  AgentResponse({
    required this.id,
    required this.conversationId,
    required this.content,
    required this.agentType,
    required this.createdAt,
  });

  factory AgentResponse.fromJson(Map<String, dynamic> json) {
    return AgentResponse(
      id: json['id'] ?? '',
      conversationId: json['conversation_id'] ?? '',
      content: json['content'] ?? '',
      agentType: json['agent_type'] ?? 'calendar_assistant',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}

/// Response model for chat history
class ChatHistoryResponse {
  final List<ChatMessage> messages;
  final int total;
  final int limit;
  final int offset;

  ChatHistoryResponse({
    required this.messages,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory ChatHistoryResponse.fromJson(Map<String, dynamic> json) {
    final messagesList = json['messages'] as List? ?? [];
    return ChatHistoryResponse(
      messages: messagesList
          .map((m) => _mapApiMessageToChatMessage(Map<String, dynamic>.from(m)))
          .toList(),
      total: json['total'] ?? 0,
      limit: json['limit'] ?? 50,
      offset: json['offset'] ?? 0,
    );
  }

  static ChatMessage _mapApiMessageToChatMessage(Map<String, dynamic> json) {
    return ChatMessage(
      messageId: json['id'] ?? '',
      sessionId: json['conversation_id'] ?? '',
      role: json['role'] == 'user' ? MessageRole.user : MessageRole.assistant,
      content: json['content'] ?? '',
      timestamp: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}

/// Conversation model for listing conversations
class Conversation {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;

  Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messageCount,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] ?? json['conversation_id'] ?? '',
      title: json['title'] ?? 'Untitled',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      messageCount: json['message_count'] ?? 0,
    );
  }
}

/// Service for chat API communication with Orbit-core
///
/// Implements the chat endpoints according to Orbit-core API specification (chat.yaml):
/// - GET /api/v1/chat/health - Check service health
/// - POST /api/v1/chat/conversations - Create a new conversation
/// - GET /api/v1/chat/conversations/{conversation_id} - Get conversation details
/// - DELETE /api/v1/chat/conversations/{conversation_id} - Soft delete a conversation
/// - POST /api/v1/chat/messages - Send a chat message
/// - GET /api/v1/chat/actions/{action_id} - Get action details
/// - POST /api/v1/chat/actions/{action_id}/confirm - Confirm a pending action
/// - POST /api/v1/chat/actions/{action_id}/cancel - Cancel a pending action
/// - GET /api/v1/chat/metrics - Get chat metrics
class ChatApiService {
  final ApiClient _apiClient;

  ChatApiService(this._apiClient);

  /// Check chat service health
  ///
  /// GET /api/v1/chat/health
  /// Response: { status: "healthy" } or { status: "unhealthy", error: "..." }
  Future<ChatHealthResponse> checkHealth() async {
    try {
      final response = await _apiClient.get('/chat/health');

      if (response.statusCode == 200) {
        return ChatHealthResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      return ChatHealthResponse(status: 'unhealthy', error: 'Unexpected status: ${response.statusCode}');
    } on DioException catch (e) {
      // For health check, return unhealthy instead of throwing
      Logger.warningWithTag('ChatApiService', 'Health check failed: ${e.message}');
      return ChatHealthResponse(status: 'unhealthy', error: e.message);
    }
  }

  /// Create a new conversation
  ///
  /// POST /api/v1/chat/conversations
  /// Response (201): { conversation_id, status }
  Future<CreateConversationResponse> createConversation() async {
    try {
      final response = await _apiClient.post('/chat/conversations');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return CreateConversationResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      throw ApiException(
        'Failed to create conversation',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Soft delete a conversation
  ///
  /// DELETE /api/v1/chat/conversations/{conversation_id}
  /// Response (200): { success, message }
  Future<DeleteConversationResponse> deleteConversation({
    required String conversationId,
  }) async {
    try {
      final response = await _apiClient.delete(
        '/chat/conversations/$conversationId',
      );

      if (response.statusCode == 200) {
        return DeleteConversationResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      throw ApiException(
        'Failed to delete conversation',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Send a chat message
  ///
  /// POST /api/v1/chat/messages
  /// Request (PostMessageRequest): { message, conversation_id, context }
  /// Response (PostMessageResponse): { message_id, status, conversation_id, reply, action_id, etc. }
  Future<ChatMessageResponse> sendChatMessage({
    required String content,
    String? conversationId,
    Map<String, dynamic>? context,
  }) async {
    try {
      final response = await _apiClient.post(
        '/chat/messages',
        data: {
          'message': content,
          if (conversationId != null) 'conversation_id': conversationId,
          if (context != null) 'context': context,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ChatMessageResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      throw ApiException(
        'Failed to send message',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Get conversation details including messages and pending actions
  ///
  /// GET /api/v1/chat/conversations/{conversation_id}
  /// Response (ConversationResponse): { conversation_id, messages, pending_actions }
  Future<ConversationDetailResponse> getConversation({
    required String conversationId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/chat/conversations/$conversationId',
      );

      if (response.statusCode == 200) {
        return ConversationDetailResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      throw ApiException(
        'Failed to get conversation',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Get action details
  ///
  /// GET /api/v1/chat/actions/{action_id}
  /// Response (ActionResponse): { action_id, status, error? }
  Future<ActionDetailResponse> getAction({
    required String actionId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/chat/actions/$actionId',
      );

      if (response.statusCode == 200) {
        return ActionDetailResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      throw ApiException(
        'Failed to get action',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Confirm a pending action
  ///
  /// POST /api/v1/chat/actions/{action_id}/confirm
  /// Request (ConfirmActionRequest): { action_id }
  /// Response (ConfirmActionResponse): { success, message, result?, operation_id? }
  Future<ActionConfirmResponse> confirmAction({
    required String actionId,
    String? idempotencyKey,
  }) async {
    try {
      final response = await _apiClient.post(
        '/chat/actions/$actionId/confirm',
        data: {
          'action_id': actionId,
          if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ActionConfirmResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      throw ApiException(
        'Failed to confirm action',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Cancel a pending action
  ///
  /// POST /api/v1/chat/actions/{action_id}/cancel
  /// Response: { success, message }
  Future<ActionCancelResponse> cancelAction({
    required String actionId,
  }) async {
    try {
      final response = await _apiClient.post(
        '/chat/actions/$actionId/cancel',
      );

      if (response.statusCode == 200) {
        return ActionCancelResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      throw ApiException(
        'Failed to cancel action',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Get chat metrics
  ///
  /// GET /api/v1/chat/metrics
  /// Response (ChatMetrics): { total_messages, total_conversations, ... }
  Future<ChatMetrics> getMetrics() async {
    try {
      final response = await _apiClient.get('/chat/metrics');

      if (response.statusCode == 200) {
        return ChatMetrics.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      throw ApiException(
        'Failed to get metrics',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  // ============== Legacy methods for backward compatibility ==============

  /// Send a chat message (legacy)
  Future<SendMessageResponse> sendMessage({
    required String conversationId,
    required String content,
    String messageType = 'text',
  }) async {
    try {
      final response = await _apiClient.post(
        '/chat/send',
        data: {
          'conversation_id': conversationId,
          'content': content,
          'message_type': messageType,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return SendMessageResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      throw ApiException(
        'Failed to send message',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Send message to AI agent for processing (legacy)
  Future<AgentResponse> sendToAgent({
    required String conversationId,
    required String prompt,
    String context = 'calendar',
  }) async {
    try {
      final response = await _apiClient.post(
        '/chat/agent',
        data: {
          'conversation_id': conversationId,
          'prompt': prompt,
          'context': context,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AgentResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      throw ApiException(
        'Failed to get agent response',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Retrieve chat history for a conversation (legacy)
  Future<ChatHistoryResponse> getChatHistory({
    required String conversationId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.get(
        '/chat/history',
        queryParameters: {
          'conversation_id': conversationId,
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200) {
        return ChatHistoryResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      throw ApiException(
        'Failed to get chat history',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// List all conversations for the authenticated user (legacy)
  Future<List<Conversation>> getConversations() async {
    try {
      final response = await _apiClient.get('/chat/conversations');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final conversationsList = data['conversations'] as List? ?? [];
        return conversationsList
            .map((c) => Conversation.fromJson(Map<String, dynamic>.from(c)))
            .toList();
      }

      throw ApiException(
        'Failed to get conversations',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Convert DioException to appropriate custom exception
  ApiException _handleDioException(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    String message = 'An error occurred';
    if (responseData is Map<String, dynamic>) {
      // Handle backend ChatError format
      if (responseData['error'] is Map) {
        message = (responseData['error'] as Map)['message'] ?? message;
      } else {
        message = responseData['message'] ??
                  responseData['error'] ??
                  message;
      }
    }

    Logger.errorWithTag(
      'ChatApiService',
      'Request failed: $message (Status: $statusCode)',
    );

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          'Connection timeout. Please check your internet connection.',
          statusCode: statusCode,
        );
      case DioExceptionType.connectionError:
        return NetworkException(
          'No internet connection. Please check your network.',
          statusCode: statusCode,
        );
      case DioExceptionType.badResponse:
        return _handleBadResponse(statusCode, message, responseData);
      case DioExceptionType.cancel:
        return ApiException('Request was cancelled', statusCode: statusCode);
      default:
        return ApiException(
          'An unexpected error occurred. Please try again.',
          statusCode: statusCode,
        );
    }
  }

  /// Handle bad response errors based on status code
  ApiException _handleBadResponse(
    int? statusCode,
    String message,
    dynamic responseData,
  ) {
    switch (statusCode) {
      case 400:
        Map<String, dynamic>? errors;
        if (responseData is Map<String, dynamic>) {
          errors = responseData['errors'] as Map<String, dynamic>?;
        }
        return ValidationException(
          message.isNotEmpty ? message : 'Invalid request. Please check your input.',
          statusCode: statusCode,
          errors: errors,
        );
      case 401:
        return AuthException(
          'Session expired. Please login again.',
          statusCode: statusCode,
        );
      case 403:
        return AuthException(
          'Access denied.',
          statusCode: statusCode,
        );
      case 404:
        return NotFoundException(
          message.isNotEmpty ? message : 'Resource not found.',
          statusCode: statusCode,
        );
      case 409:
        return ConflictException(
          message.isNotEmpty ? message : 'Action already processed or not pending.',
          statusCode: statusCode,
        );
      case 410:
        // 410 Gone - Action expired
        return ActionExpiredException(
          message.isNotEmpty ? message : 'Action has expired.',
          statusCode: statusCode,
        );
      case 429:
        Duration? retryAfter;
        if (responseData is Map<String, dynamic>) {
          final retrySeconds = responseData['retry_after'] as int?;
          if (retrySeconds != null) {
            retryAfter = Duration(seconds: retrySeconds);
          }
        }
        return RateLimitException(
          'Too many requests. Please try again later.',
          statusCode: statusCode,
          retryAfter: retryAfter,
        );
      case 500:
      case 502:
      case 503:
      case 504:
        return ServerException(
          'Server error. Please try again later.',
          statusCode: statusCode,
        );
      default:
        return ApiException(
          message.isNotEmpty ? message : 'An error occurred',
          statusCode: statusCode,
        );
    }
  }
}
