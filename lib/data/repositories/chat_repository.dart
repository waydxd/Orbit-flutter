import '../services/chat_api_service.dart';
import '../models/agent_chat_message.dart';
import '../../utils/logger.dart';

/// Repository for chat functionality
///
/// Wraps ChatApiService to provide a clean interface for the ChatAgentProvider.
/// Handles API calls according to the Orbit-core chat API (chat.yaml).
class ChatRepository {
  final ChatApiService _apiService;

  ChatRepository(this._apiService);

  /// Initialize the repository (no-op, for interface consistency)
  Future<void> initialize() async {
    // No initialization needed for now
    Logger.infoWithTag('ChatRepository', 'Repository initialized');
  }

  /// Send a chat message to the backend
  ///
  /// POST /api/v1/chat/messages
  /// Returns ChatMessageResponse containing conversation_id, reply, and action info
  Future<ChatMessageResponse> sendChatMessage({
    required String content,
    String? conversationId,
    Map<String, dynamic>? context,
  }) async {
    return _apiService.sendChatMessage(
      content: content,
      conversationId: conversationId,
      context: context,
    );
  }

  /// Get conversation details including messages and pending actions
  ///
  /// GET /api/v1/chat/conversations/{conversation_id}
  Future<ConversationDetailResponse> getConversationDetail({
    required String conversationId,
  }) async {
    return _apiService.getConversation(
      conversationId: conversationId,
    );
  }

  /// Get chat history for a conversation and convert to AgentChatMessage list
  ///
  /// This uses the GET /api/v1/chat/conversations/{id} endpoint
  /// and transforms the messages to AgentChatMessage format
  Future<List<AgentChatMessage>> getChatHistory({
    required String conversationId,
  }) async {
    final response = await _apiService.getConversation(
      conversationId: conversationId,
    );

    return response.messages.map((msg) {
      if (msg.isUser) {
        return AgentChatMessage.user(
          id: '${conversationId}_${msg.timestamp.millisecondsSinceEpoch}',
          conversationId: conversationId,
          content: msg.content,
          timestamp: msg.timestamp,
        );
      } else {
        return AgentChatMessage.agent(
          id: '${conversationId}_${msg.timestamp.millisecondsSinceEpoch}',
          conversationId: conversationId,
          content: msg.content,
          agentType: AgentType.calendarAssistant,
          timestamp: msg.timestamp,
        );
      }
    }).toList();
  }

  /// Get action details
  ///
  /// GET /api/v1/chat/actions/{action_id}
  Future<ActionDetailResponse> getAction({
    required String actionId,
  }) async {
    return _apiService.getAction(actionId: actionId);
  }

  /// Confirm a pending action
  ///
  /// POST /api/v1/chat/actions/{action_id}/confirm
  Future<ActionConfirmResponse> confirmAction({
    required String actionId,
    String? idempotencyKey,
  }) async {
    return _apiService.confirmAction(
      actionId: actionId,
      idempotencyKey: idempotencyKey,
    );
  }

  /// Cancel a pending action
  ///
  /// POST /api/v1/chat/actions/{action_id}/cancel
  /// Returns true if successfully cancelled
  Future<bool> cancelAction({
    required String actionId,
  }) async {
    final response = await _apiService.cancelAction(actionId: actionId);
    return response.success;
  }

  /// Get chat metrics
  ///
  /// GET /api/v1/chat/metrics
  Future<ChatMetrics> getMetrics() async {
    return _apiService.getMetrics();
  }
}
