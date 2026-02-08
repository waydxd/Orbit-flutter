import '../models/agent_chat_message.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../services/chat_api_service.dart';
import '../services/chat_exceptions.dart';
import 'chat_local_repository.dart';
import '../../utils/logger.dart';

/// Result of sending a chat message
class ChatMessageResult {
  final String messageId;
  final String status;
  final String conversationId;
  final bool isSuccess;
  final String? reply;
  final String? proposedActionSummary;
  final String? actionId;
  final String? correlationId;

  ChatMessageResult({
    required this.messageId,
    required this.status,
    required this.conversationId,
    required this.isSuccess,
    this.reply,
    this.proposedActionSummary,
    this.actionId,
    this.correlationId,
  });

  bool get hasProposedAction => actionId != null && proposedActionSummary != null;
}

/// Result of confirming an action
class ActionConfirmResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? result;
  final String? operationId;

  ActionConfirmResult({
    required this.success,
    required this.message,
    this.result,
    this.operationId,
  });
}

/// Repository for chat operations integrating with Orbit-core API
///
/// This repository handles:
/// - Sending messages via POST /api/v1/chat/messages
/// - Getting conversation details via GET /api/v1/chat/conversations/{id}
/// - Managing actions via GET/POST /api/v1/chat/actions/{id}
/// - Confirming/cancelling actions via POST /api/v1/chat/actions/{id}/confirm|cancel
/// - Local caching for offline support
class ChatRepository {
  final ChatApiService _apiService;
  final ChatLocalRepository _localRepository;

  ChatRepository({
    required ChatApiService apiService,
    ChatLocalRepository? localRepository,
  })  : _apiService = apiService,
        _localRepository = localRepository ?? ChatLocalRepository();

  /// Initialize the repository
  Future<void> initialize() async {
    await _localRepository.init();
  }

  /// Send a chat message
  ///
  /// Uses POST /api/v1/chat/messages
  /// Returns the message result with status and agent reply
  Future<ChatMessageResult> sendChatMessage({
    required String content,
    String? conversationId,
    Map<String, dynamic>? context,
  }) async {
    try {
      final response = await _apiService.sendChatMessage(
        content: content,
        conversationId: conversationId,
        context: context,
      );

      Logger.infoWithTag(
        'ChatRepository',
        'Chat message sent, messageId: ${response.messageId}, status: ${response.status}',
      );

      return ChatMessageResult(
        messageId: response.messageId,
        status: response.status,
        conversationId: response.conversationId,
        isSuccess: response.isSuccess,
        reply: response.reply,
        proposedActionSummary: response.proposedActionSummary,
        actionId: response.actionId,
        correlationId: response.correlationId,
      );
    } on ApiException catch (e) {
      Logger.errorWithTag('ChatRepository', 'Failed to send chat message: ${e.message}');
      rethrow;
    }
  }

  /// Get conversation details including messages and pending actions
  ///
  /// Uses GET /api/v1/chat/conversations/{conversation_id}
  Future<ConversationDetailResponse> getConversationDetail({
    required String conversationId,
  }) async {
    try {
      final response = await _apiService.getConversation(
        conversationId: conversationId,
      );

      Logger.infoWithTag(
        'ChatRepository',
        'Got conversation detail: ${response.messages.length} messages, ${response.pendingActions.length} pending actions',
      );

      return response;
    } on ApiException catch (e) {
      Logger.errorWithTag('ChatRepository', 'Failed to get conversation: ${e.message}');
      rethrow;
    }
  }

  /// Get action details
  ///
  /// Uses GET /api/v1/chat/actions/{action_id}
  Future<ActionDetailResponse> getActionDetail({
    required String actionId,
  }) async {
    try {
      final response = await _apiService.getAction(actionId: actionId);

      Logger.infoWithTag(
        'ChatRepository',
        'Got action detail: ${response.actionId}, status: ${response.status}',
      );

      return response;
    } on ApiException catch (e) {
      Logger.errorWithTag('ChatRepository', 'Failed to get action: ${e.message}');
      rethrow;
    }
  }

  /// Confirm a pending action
  ///
  /// Uses POST /api/v1/chat/actions/{action_id}/confirm
  Future<ActionConfirmResult> confirmAction({
    required String actionId,
    String? idempotencyKey,
  }) async {
    try {
      final response = await _apiService.confirmAction(
        actionId: actionId,
        idempotencyKey: idempotencyKey,
      );

      Logger.infoWithTag(
        'ChatRepository',
        'Action confirmed: ${response.success}, message: ${response.message}',
      );

      return ActionConfirmResult(
        success: response.success,
        message: response.message,
        result: response.result,
        operationId: response.operationId,
      );
    } on ApiException catch (e) {
      Logger.errorWithTag('ChatRepository', 'Failed to confirm action: ${e.message}');
      rethrow;
    }
  }

  /// Cancel a pending action
  ///
  /// Uses POST /api/v1/chat/actions/{action_id}/cancel
  Future<bool> cancelAction({
    required String actionId,
  }) async {
    try {
      final response = await _apiService.cancelAction(actionId: actionId);

      Logger.infoWithTag(
        'ChatRepository',
        'Action cancelled: ${response.success}, message: ${response.message}',
      );

      return response.success;
    } on ApiException catch (e) {
      Logger.errorWithTag('ChatRepository', 'Failed to cancel action: ${e.message}');
      rethrow;
    }
  }

  /// Get chat metrics
  ///
  /// Uses GET /api/v1/chat/metrics
  Future<ChatMetrics> getMetrics() async {
    try {
      return await _apiService.getMetrics();
    } on ApiException catch (e) {
      Logger.errorWithTag('ChatRepository', 'Failed to get metrics: ${e.message}');
      rethrow;
    }
  }

  // ============== Helper methods for UI ==============

  /// Send a message and get conversation state
  /// This is a convenience method that sends a message and then fetches the conversation
  Future<AgentChatMessage?> sendMessageAndGetResponse({
    required String conversationId,
    required String content,
    AgentContextType context = AgentContextType.calendar,
  }) async {
    try {
      // Send the message
      final messageResult = await sendChatMessage(
        content: content,
        conversationId: conversationId,
        context: {'type': context.value},
      );

      if (!messageResult.isSuccess) {
        Logger.errorWithTag('ChatRepository', 'Message failed to send');
        return null;
      }

      // Use the conversation ID from the backend response
      final actualConversationId = messageResult.conversationId;

      // Fetch the updated conversation to get the assistant's response
      final conversation = await getConversationDetail(
        conversationId: actualConversationId,
      );

      // Find the latest assistant message
      final assistantMessages = conversation.messages
          .where((m) => m.isAssistant)
          .toList();

      if (assistantMessages.isNotEmpty) {
        final latestMessage = assistantMessages.last;
        return AgentChatMessage.agent(
          id: messageResult.messageId,
          conversationId: actualConversationId,
          content: latestMessage.content,
          agentType: AgentType.calendarAssistant,
          timestamp: latestMessage.timestamp,
        );
      }

      return null;
    } on ApiException catch (e) {
      Logger.errorWithTag('ChatRepository', 'Failed to send message: ${e.message}');
      rethrow;
    }
  }

  /// Get chat history for a conversation
  ///
  /// Uses the conversation detail endpoint and converts to AgentChatMessage format
  Future<List<AgentChatMessage>> getChatHistory({
    required String conversationId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _apiService.getConversation(
        conversationId: conversationId,
      );

      // Convert to AgentChatMessage format
      final messages = response.messages.map((m) {
        return AgentChatMessage(
          id: '${conversationId}_${m.timestamp.millisecondsSinceEpoch}',
          conversationId: conversationId,
          content: m.content,
          isUser: m.isUser,
          agentType: m.isAssistant ? AgentType.calendarAssistant : null,
          timestamp: m.timestamp,
        );
      }).toList();

      // Cache messages locally
      await _cacheMessages(conversationId, messages);

      return messages;
    } on NetworkException {
      // Try to get from local cache
      return await _getCachedMessages(conversationId);
    } on ApiException catch (e) {
      Logger.errorWithTag('ChatRepository', 'Failed to get chat history: ${e.message}');
      rethrow;
    }
  }

  /// Get all conversations for the user
  Future<List<ChatSession>> getConversations() async {
    try {
      final conversations = await _apiService.getConversations();

      // Convert to ChatSession format
      final sessions = conversations.map((c) {
        return ChatSession(
          sessionId: c.id,
          userId: '', // Not provided by API
          title: c.title,
          createdAt: c.createdAt,
          updatedAt: c.updatedAt,
          messageCount: c.messageCount,
        );
      }).toList();

      // Cache sessions locally
      await _cacheSessions(sessions);

      return sessions;
    } on NetworkException {
      // Try to get from local cache
      return await _getCachedSessions();
    } on ApiException catch (e) {
      Logger.errorWithTag('ChatRepository', 'Failed to get conversations: ${e.message}');
      rethrow;
    }
  }

  // ============== Legacy methods for backward compatibility ==============

  /// Send only a user message without waiting for agent response (legacy)
  Future<SendMessageResponse> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    try {
      final response = await _apiService.sendMessage(
        conversationId: conversationId,
        content: content,
      );

      Logger.infoWithTag(
        'ChatRepository',
        'Message sent: ${response.id}',
      );

      return response;
    } on ApiException catch (e) {
      Logger.errorWithTag('ChatRepository', 'Failed to send message: ${e.message}');
      rethrow;
    }
  }

  /// Get AI agent response for a prompt (legacy)
  Future<AgentChatMessage> getAgentResponse({
    required String conversationId,
    required String prompt,
    AgentContextType context = AgentContextType.calendar,
  }) async {
    try {
      final agentResponse = await _apiService.sendToAgent(
        conversationId: conversationId,
        prompt: prompt,
        context: context.value,
      );

      return AgentChatMessage.agent(
        id: agentResponse.id,
        conversationId: agentResponse.conversationId,
        content: agentResponse.content,
        agentType: AgentTypeExtension.fromString(agentResponse.agentType),
        timestamp: agentResponse.createdAt,
      );
    } on ApiException catch (e) {
      Logger.errorWithTag('ChatRepository', 'Failed to get agent response: ${e.message}');
      rethrow;
    }
  }

  // ============== Cache methods ==============

  /// Cache messages locally for offline access
  Future<void> _cacheMessages(
    String conversationId,
    List<AgentChatMessage> messages,
  ) async {
    try {
      Logger.debugWithTag('ChatRepository', 'Cached ${messages.length} messages for $conversationId');
    } catch (e) {
      Logger.warningWithTag('ChatRepository', 'Failed to cache messages: $e');
    }
  }

  /// Get cached messages for offline access
  Future<List<AgentChatMessage>> _getCachedMessages(String conversationId) async {
    try {
      final cached = await _localRepository.getCachedMessages(conversationId);
      if (cached != null) {
        return cached.map((m) {
          return AgentChatMessage(
            id: m.messageId,
            conversationId: m.sessionId,
            content: m.content,
            isUser: m.role == MessageRole.user,
            timestamp: m.timestamp,
          );
        }).toList();
      }
    } catch (e) {
      Logger.warningWithTag('ChatRepository', 'Failed to get cached messages: $e');
    }
    return [];
  }

  /// Cache sessions locally
  Future<void> _cacheSessions(List<ChatSession> sessions) async {
    try {
      Logger.debugWithTag('ChatRepository', 'Cached ${sessions.length} sessions');
    } catch (e) {
      Logger.warningWithTag('ChatRepository', 'Failed to cache sessions: $e');
    }
  }

  /// Get cached sessions
  Future<List<ChatSession>> _getCachedSessions() async {
    try {
      return [];
    } catch (e) {
      Logger.warningWithTag('ChatRepository', 'Failed to get cached sessions: $e');
      return [];
    }
  }
}
