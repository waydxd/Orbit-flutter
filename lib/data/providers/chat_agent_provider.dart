import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/agent_chat_message.dart';
import '../models/chat_session.dart';
import '../services/api_client.dart';
import '../services/chat_api_service.dart';
import '../services/chat_exceptions.dart';
import '../repositories/chat_repository.dart';
import '../repositories/chat_local_repository.dart';
import '../../utils/logger.dart';

export '../models/chat_session.dart';



/// Pending action info for UI display
class PendingActionInfo {
  final String actionId;
  final String type;
  final String status;
  final String? idempotencyKey;

  PendingActionInfo({
    required this.actionId,
    required this.type,
    required this.status,
    this.idempotencyKey,
  });

  bool get isPending => status == 'pending';
}

/// State class for chat with agent functionality
class ChatAgentState {
  final List<AgentChatMessage> messages;
  final List<ChatSession> conversations;
  final String? currentConversationId;
  final bool isLoading;
  final bool isLoadingHistory;
  final bool isOfflineMode;
  final bool isServiceHealthy;
  final String? errorMessage;
  final ApiException? lastError;

  // Pending action support
  final PendingActionInfo? currentPendingAction;
  final bool isConfirmingAction;
  final bool isCancellingAction;

  const ChatAgentState({
    this.messages = const [],
    this.conversations = const [],
    this.currentConversationId,
    this.isLoading = false,
    this.isLoadingHistory = false,
    this.isOfflineMode = false,
    this.isServiceHealthy = true,
    this.errorMessage,
    this.lastError,
    this.currentPendingAction,
    this.isConfirmingAction = false,
    this.isCancellingAction = false,
  });

  ChatAgentState copyWith({
    List<AgentChatMessage>? messages,
    List<ChatSession>? conversations,
    String? currentConversationId,
    bool? isLoading,
    bool? isLoadingHistory,
    bool? isOfflineMode,
    bool? isServiceHealthy,
    String? errorMessage,
    ApiException? lastError,
    PendingActionInfo? currentPendingAction,
    bool? isConfirmingAction,
    bool? isCancellingAction,
    bool clearError = false,
    bool clearPendingAction = false,
    bool clearConversationId = false,
  }) {
    return ChatAgentState(
      messages: messages ?? this.messages,
      conversations: conversations ?? this.conversations,
      currentConversationId: clearConversationId ? null : (currentConversationId ?? this.currentConversationId),
      isLoading: isLoading ?? this.isLoading,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
      isServiceHealthy: isServiceHealthy ?? this.isServiceHealthy,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastError: clearError ? null : (lastError ?? this.lastError),
      currentPendingAction: clearPendingAction ? null : (currentPendingAction ?? this.currentPendingAction),
      isConfirmingAction: isConfirmingAction ?? this.isConfirmingAction,
      isCancellingAction: isCancellingAction ?? this.isCancellingAction,
    );
  }

  bool get hasError => errorMessage != null;
  bool get isAuthError => lastError is AuthException;
  bool get isNetworkError => lastError is NetworkException;
  bool get isServerError => lastError is ServerException;
  bool get canRetry => lastError is NetworkException || lastError is ServerException;
  bool get hasPendingAction => currentPendingAction != null && currentPendingAction!.isPending;
  bool get isProcessingAction => isConfirmingAction || isCancellingAction;
}

/// Provider for chat with AI agent functionality
///
/// Integrates with Orbit-core chat endpoints (chat.yaml):
/// - GET /api/v1/chat/health - Check service health
/// - POST /api/v1/chat/conversations - Create a new conversation
/// - GET /api/v1/chat/conversations/{id} - Get conversation details
/// - DELETE /api/v1/chat/conversations/{id} - Soft delete a conversation
/// - POST /api/v1/chat/messages - Send message
/// - GET /api/v1/chat/actions/{id} - Get action details
/// - POST /api/v1/chat/actions/{id}/confirm - Confirm pending action
/// - POST /api/v1/chat/actions/{id}/cancel - Cancel pending action
/// - GET /api/v1/chat/metrics - Get chat metrics
class ChatAgentProvider extends ChangeNotifier {
  final ChatRepository _repository;
  final ChatLocalRepository _localRepository;
  final Uuid _uuid = const Uuid();

  ChatAgentState _state = const ChatAgentState();
  ChatAgentState get state => _state;

  // Convenience getters
  List<AgentChatMessage> get messages => _state.messages;
  List<ChatSession> get conversations => _state.conversations;
  String? get currentConversationId => _state.currentConversationId;
  bool get isLoading => _state.isLoading;
  bool get isLoadingHistory => _state.isLoadingHistory;
  bool get isOfflineMode => _state.isOfflineMode;
  bool get isServiceHealthy => _state.isServiceHealthy;
  String? get errorMessage => _state.errorMessage;
  bool get hasError => _state.hasError;


  // Pending action getters
  PendingActionInfo? get currentPendingAction => _state.currentPendingAction;
  bool get hasPendingAction => _state.hasPendingAction;
  bool get isConfirmingAction => _state.isConfirmingAction;
  bool get isCancellingAction => _state.isCancellingAction;
  bool get isProcessingAction => _state.isProcessingAction;

  /// Callback for handling auth errors (e.g., redirect to login)
  final void Function()? onAuthError;

  /// Callback when an action is successfully confirmed
  final void Function(String? eventId)? onActionConfirmed;

  /// Callback when an action is cancelled
  final void Function()? onActionCancelled;

  ChatAgentProvider({
    required ApiClient apiClient,
    ChatLocalRepository? localRepository,
    this.onAuthError,
    this.onActionConfirmed,
    this.onActionCancelled,
  })  : _repository = ChatRepository(ChatApiService(apiClient)),
        _localRepository = localRepository ?? ChatLocalRepository();

  /// Factory constructor for dependency injection
  ChatAgentProvider.withRepository({
    required ChatRepository repository,
    ChatLocalRepository? localRepository,
    this.onAuthError,
    this.onActionConfirmed,
    this.onActionCancelled,
  })  : _repository = repository,
        _localRepository = localRepository ?? ChatLocalRepository();

  void _updateState(ChatAgentState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Initialize the provider
  Future<void> initialize() async {
    await _repository.initialize();
    await _localRepository.init();
    await loadConversations();
  }

  /// Check chat service health (optional, not called on startup)
  ///
  /// GET /api/v1/chat/health
  /// Note: This endpoint may be unavailable. A failed health check does NOT
  /// block other chat operations.
  Future<bool> checkServiceHealth() async {
    try {
      final health = await _repository.checkHealth();
      _updateState(_state.copyWith(
        isServiceHealthy: health.isHealthy,
      ));
      Logger.infoWithTag('ChatAgentProvider', 'Service health: ${health.status}');
      return health.isHealthy;
    } catch (e) {
      _updateState(_state.copyWith(
        isServiceHealthy: false,
      ));
      Logger.warningWithTag('ChatAgentProvider', 'Health check failed: $e');
      return false;
    }
  }

  /// Load all conversations from local cache
  ///
  /// Sessions are persisted to Hive so they survive page navigation.
  /// The backend doesn't provide a list-all-conversations endpoint,
  /// so local cache is the source of truth for the sidebar list.
  Future<void> loadConversations() async {
    try {
      final cachedSessions = await _localRepository.getCachedSessions(_localSessionsKey);
      if (cachedSessions != null && cachedSessions.isNotEmpty) {
        _updateState(_state.copyWith(
          conversations: cachedSessions,
          isLoadingHistory: false,
          clearError: true,
        ));
        Logger.infoWithTag('ChatAgentProvider', 'Loaded ${cachedSessions.length} conversations from cache');
      } else {
        _updateState(_state.copyWith(
          isLoadingHistory: false,
          clearError: true,
        ));
      }
    } catch (e) {
      Logger.warningWithTag('ChatAgentProvider', 'Failed to load cached conversations: $e');
      _updateState(_state.copyWith(
        isLoadingHistory: false,
        clearError: true,
      ));
    }
  }

  /// Key used to store sessions list in Hive
  static const String _localSessionsKey = 'chat_sessions_list';

  /// Load chat history for a conversation
  ///
  /// Tries the backend first (GET /api/v1/chat/conversations/{id}),
  /// falls back to locally cached messages from Hive if the backend is unreachable.
  Future<void> loadChatHistory(String conversationId) async {
    _updateState(_state.copyWith(
      isLoadingHistory: true,
      currentConversationId: conversationId,
      clearError: true,
      clearPendingAction: true,
    ));

    try {
      final messages = await _repository.getChatHistory(
        conversationId: conversationId,
      );

      // Also load conversation details to get pending actions
      final conversationDetail = await _repository.getConversationDetail(
        conversationId: conversationId,
      );

      // Get the first pending action if any
      PendingActionInfo? pendingAction;
      final firstPending = conversationDetail.firstPendingAction;
      if (firstPending != null) {
        pendingAction = PendingActionInfo(
          actionId: firstPending.actionId,
          type: firstPending.type,
          status: firstPending.status,
          idempotencyKey: firstPending.idempotencyKey,
        );
      }

      _updateState(_state.copyWith(
        messages: messages,
        isLoadingHistory: false,
        isOfflineMode: false,
        currentPendingAction: pendingAction,
      ));

      // Update local cache with fresh data from backend
      await _localRepository.cacheAgentMessages(conversationId, messages);
    } on AuthException catch (e) {
      _handleAuthError(e);
    } on NetworkException catch (e) {
      // Fall back to locally cached messages
      await _loadCachedMessages(conversationId, e);
    } on NotFoundException catch (e) {
      // Conversation not found on backend — try local cache
      final cached = await _localRepository.getCachedAgentMessages(conversationId);
      if (cached != null && cached.isNotEmpty) {
        _updateState(_state.copyWith(
          messages: cached,
          isLoadingHistory: false,
        ));
      } else {
        _updateState(_state.copyWith(
          isLoadingHistory: false,
          messages: [],
          errorMessage: e.message,
          lastError: e,
        ));
      }
    } on ApiException catch (e) {
      // For other API errors, also try local cache
      await _loadCachedMessages(conversationId, e);
    }
  }

  /// Helper: load messages from Hive cache when backend fails
  Future<void> _loadCachedMessages(String conversationId, ApiException error) async {
    final cached = await _localRepository.getCachedAgentMessages(conversationId);
    if (cached != null && cached.isNotEmpty) {
      _updateState(_state.copyWith(
        messages: cached,
        isLoadingHistory: false,
        isOfflineMode: error is NetworkException,
      ));
      Logger.infoWithTag('ChatAgentProvider', 'Loaded ${cached.length} messages from cache for $conversationId');
    } else {
      _updateState(_state.copyWith(
        isLoadingHistory: false,
        isOfflineMode: error is NetworkException,
        errorMessage: error.message,
        lastError: error,
      ));
    }
  }

  /// Send a message and get AI agent response
  ///
  /// If no conversation exists yet, one is created first via
  /// POST /api/v1/chat/conversations. The returned conversation_id is then
  /// used for all subsequent messages until the conversation is deleted.
  Future<void> sendMessage(
    String content, {
    AgentContextType context = AgentContextType.calendar,
  }) async {
    // If no conversation exists, create one first
    String? conversationId = _state.currentConversationId;

    if (conversationId == null) {
      try {
        final createResponse = await _repository.createConversation();
        conversationId = createResponse.conversationId;

        // Save to local history for sidebar
        final session = ChatSession(
          sessionId: conversationId,
          userId: '',
          title: 'New Chat',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          messageCount: 0,
        );
        final updatedConversations = [session, ..._state.conversations];

        _updateState(_state.copyWith(
          currentConversationId: conversationId,
          conversations: updatedConversations,
        ));

        Logger.infoWithTag('ChatAgentProvider', 'Auto-created conversation: $conversationId');
      } on AuthException catch (e) {
        _handleAuthError(e);
        return;
      } on ApiException catch (e) {
        _updateState(_state.copyWith(
          errorMessage: 'Failed to start conversation: ${e.message}',
          lastError: e,
        ));
        return;
      }
    }

    // Create user message
    final userMessage = AgentChatMessage.user(
      id: _uuid.v4(),
      conversationId: conversationId,
      content: content,
    );

    // Create loading placeholder for agent response
    final loadingMessage = AgentChatMessage.loading(
      id: _uuid.v4(),
      conversationId: conversationId,
    );

    // Add messages to state immediately
    _updateState(_state.copyWith(
      messages: [..._state.messages, userMessage, loadingMessage],
      isLoading: true,
      clearError: true,
      clearPendingAction: true,
    ));

    if (_state.isOfflineMode) {
      // Remove loading message and show error
      _updateState(_state.copyWith(
        messages: _state.messages.where((m) => !m.isLoading).toList(),
        isLoading: false,
        errorMessage: 'Cannot send messages in offline mode. Please check your connection.',
      ));
      return;
    }

    try {
      // Send message with the guaranteed conversation_id
      final result = await _repository.sendChatMessage(
        content: content,
        conversationId: conversationId,
        context: {'type': context.value},
      );

      if (!result.isSuccess) {
        _updateState(_state.copyWith(
          messages: _state.messages.where((m) => !m.isLoading).toList(),
          isLoading: false,
          errorMessage: 'Failed to send message',
        ));
        return;
      }

      // Use the reply directly from the sendChatMessage result
      final assistantReply = result.reply;

      // Replace loading message
      final updatedMessages = _state.messages
          .where((m) => !m.isLoading)
          .toList();

      if (assistantReply.isNotEmpty) {
        // Attach action info to the message if there's a proposed action
        if (result.hasProposedAction && result.actionId != null) {
          updatedMessages.add(AgentChatMessage.agentWithAction(
            id: result.messageId,
            conversationId: conversationId,
            content: assistantReply,
            agentType: AgentType.calendarAssistant,
            actionId: result.actionId!,
            actionType: result.proposedActionSummary ?? 'create_event',
            actionSummary: result.proposedActionSummary,
            actionStatus: 'pending',
          ));
        } else {
          updatedMessages.add(AgentChatMessage.agent(
            id: result.messageId,
            conversationId: conversationId,
            content: assistantReply,
            agentType: AgentType.calendarAssistant,
          ));
        }
      }

      // Check for pending actions from the result (for backwards compatibility)
      PendingActionInfo? pendingAction;
      if (result.hasProposedAction && result.actionId != null) {
        pendingAction = PendingActionInfo(
          actionId: result.actionId!,
          type: result.proposedActionSummary ?? 'pending',
          status: 'pending',
        );
      }

      // Save conversation to local history for sidebar display
      await _saveConversationToHistory(conversationId, content, assistantReply);

      _updateState(_state.copyWith(
        messages: updatedMessages,
        isLoading: false,
        currentPendingAction: pendingAction,
      ));

      Logger.infoWithTag(
        'ChatAgentProvider',
        'Message sent and response received${pendingAction != null ? " with pending action" : ""}',
      );
    } on AuthException catch (e) {
      _removeLoadingAndSetError(e);
      _handleAuthError(e);
    } on NetworkException catch (e) {
      _removeLoadingAndSetError(e);
      _updateState(_state.copyWith(isOfflineMode: true));
    } on ValidationException catch (e) {
      _removeLoadingAndSetError(e);
    } on ServerException catch (e) {
      _removeLoadingAndSetError(e);
    } on ApiException catch (e) {
      _removeLoadingAndSetError(e);
    }
  }

  /// Confirm the current pending action
  Future<void> confirmPendingAction() async {
    final action = _state.currentPendingAction;
    if (action == null || !action.isPending) {
      Logger.warningWithTag('ChatAgentProvider', 'No pending action to confirm');
      return;
    }

    await confirmMessageAction(action.actionId, idempotencyKey: action.idempotencyKey);
  }

  /// Confirm an action by action ID (used in Agent mode for per-message actions)
  Future<void> confirmMessageAction(String actionId, {String? idempotencyKey}) async {
    _updateState(_state.copyWith(
      isConfirmingAction: true,
      clearError: true,
    ));

    try {
      final result = await _repository.confirmAction(
        actionId: actionId,
        idempotencyKey: idempotencyKey,
      );

      if (result.success) {
        // Update the message with the action to show confirmed status
        final updatedMessages = _state.messages.map((m) {
          if (m.actionId == actionId) {
            return m.copyWith(actionStatus: 'confirmed');
          }
          return m;
        }).toList();

        // Add confirmation message to chat
        final confirmMessage = AgentChatMessage.agent(
          id: _uuid.v4(),
          conversationId: _state.currentConversationId ?? '',
          content: result.message.isNotEmpty ? result.message : 'Action confirmed successfully!',
          agentType: AgentType.calendarAssistant,
        );

        _updateState(_state.copyWith(
          messages: [...updatedMessages, confirmMessage],
          isConfirmingAction: false,
          clearPendingAction: true,
        ));

        // Trigger callback
        onActionConfirmed?.call(result.operationId);

        // Persist updated messages to cache
        if (_state.currentConversationId != null) {
          await _persistMessages(_state.currentConversationId!);
        }

        Logger.infoWithTag('ChatAgentProvider', 'Action confirmed successfully');
      } else {
        _updateState(_state.copyWith(
          isConfirmingAction: false,
          errorMessage: result.message,
        ));
      }
    } on AuthException catch (e) {
      _updateState(_state.copyWith(
        isConfirmingAction: false,
        errorMessage: e.message,
        lastError: e,
      ));
      _handleAuthError(e);
    } on ActionExpiredException catch (e) {
      // Update message status to expired
      final updatedMessages = _state.messages.map((m) {
        if (m.actionId == actionId) {
          return m.copyWith(actionStatus: 'expired');
        }
        return m;
      }).toList();

      _updateState(_state.copyWith(
        messages: updatedMessages,
        isConfirmingAction: false,
        errorMessage: e.message,
        lastError: e,
        clearPendingAction: true,
      ));
    } on ConflictException catch (e) {
      _updateState(_state.copyWith(
        isConfirmingAction: false,
        errorMessage: e.message,
        lastError: e,
        clearPendingAction: true,
      ));
    } on ApiException catch (e) {
      _updateState(_state.copyWith(
        isConfirmingAction: false,
        errorMessage: e.message,
        lastError: e,
      ));
    }
  }

  /// Cancel the current pending action
  Future<void> cancelPendingAction() async {
    final action = _state.currentPendingAction;
    if (action == null || !action.isPending) {
      Logger.warningWithTag('ChatAgentProvider', 'No pending action to cancel');
      return;
    }

    await cancelMessageAction(action.actionId);
  }

  /// Cancel an action by action ID (used in Agent mode for per-message actions)
  Future<void> cancelMessageAction(String actionId) async {
    _updateState(_state.copyWith(
      isCancellingAction: true,
      clearError: true,
    ));

    try {
      final success = await _repository.cancelAction(
        actionId: actionId,
      );

      if (success) {
        // Update the message with the action to show cancelled status
        final updatedMessages = _state.messages.map((m) {
          if (m.actionId == actionId) {
            return m.copyWith(actionStatus: 'cancelled');
          }
          return m;
        }).toList();

        // Add cancellation message to chat
        final cancelMessage = AgentChatMessage.agent(
          id: _uuid.v4(),
          conversationId: _state.currentConversationId ?? '',
          content: 'Action cancelled. Let me know if you need anything else.',
          agentType: AgentType.calendarAssistant,
        );

        _updateState(_state.copyWith(
          messages: [...updatedMessages, cancelMessage],
          isCancellingAction: false,
          clearPendingAction: true,
        ));

        // Trigger callback
        onActionCancelled?.call();

        // Persist updated messages to cache
        if (_state.currentConversationId != null) {
          await _persistMessages(_state.currentConversationId!);
        }

        Logger.infoWithTag('ChatAgentProvider', 'Action cancelled successfully');
      } else {
        _updateState(_state.copyWith(
          isCancellingAction: false,
          errorMessage: 'Failed to cancel action',
        ));
      }
    } on AuthException catch (e) {
      _updateState(_state.copyWith(
        isCancellingAction: false,
        errorMessage: e.message,
        lastError: e,
      ));
      _handleAuthError(e);
    } on ActionExpiredException catch (e) {
      // Update message status to expired
      final updatedMessages = _state.messages.map((m) {
        if (m.actionId == actionId) {
          return m.copyWith(actionStatus: 'expired');
        }
        return m;
      }).toList();

      _updateState(_state.copyWith(
        messages: updatedMessages,
        isCancellingAction: false,
        errorMessage: e.message,
        lastError: e,
        clearPendingAction: true,
      ));
    } on ConflictException catch (e) {
      _updateState(_state.copyWith(
        isCancellingAction: false,
        errorMessage: e.message,
        lastError: e,
        clearPendingAction: true,
      ));
    } on ApiException catch (e) {
      _updateState(_state.copyWith(
        isCancellingAction: false,
        errorMessage: e.message,
        lastError: e,
      ));
    }
  }

  /// Dismiss the pending action without cancelling on the server
  void dismissPendingAction() {
    _updateState(_state.copyWith(clearPendingAction: true));
  }

  /// Remove loading message and set error state
  void _removeLoadingAndSetError(ApiException error) {
    final messagesWithoutLoading = _state.messages
        .where((m) => !m.isLoading)
        .toList();

    _updateState(_state.copyWith(
      messages: messagesWithoutLoading,
      isLoading: false,
      errorMessage: error.message,
      lastError: error,
    ));
  }

  /// Handle authentication errors
  void _handleAuthError(AuthException error) {
    _updateState(_state.copyWith(
      isLoading: false,
      isLoadingHistory: false,
      isConfirmingAction: false,
      isCancellingAction: false,
      errorMessage: error.message,
      lastError: error,
    ));

    // Trigger callback for navigation to login
    onAuthError?.call();
  }

  /// Retry the last failed operation
  Future<void> retry() async {
    if (!_state.canRetry) return;

    _updateState(_state.copyWith(clearError: true, isOfflineMode: false));

    // Reload conversations or history based on current state
    if (_state.currentConversationId != null) {
      await loadChatHistory(_state.currentConversationId!);
    } else {
      await loadConversations();
    }
  }


  /// Update conversation title
  Future<void> updateConversationTitle(String conversationId, String newTitle) async {
    try {
      final existingIndex = _state.conversations.indexWhere(
        (c) => c.sessionId == conversationId,
      );

      if (existingIndex >= 0) {
        final updatedSession = _state.conversations[existingIndex].copyWith(
          title: newTitle,
          updatedAt: DateTime.now(),
        );

        final updatedConversations = List<ChatSession>.from(_state.conversations);
        updatedConversations[existingIndex] = updatedSession;

        _updateState(_state.copyWith(conversations: updatedConversations));
        await _persistSessions();
        Logger.infoWithTag('ChatAgentProvider', 'Updated conversation title: $newTitle');
      }
    } catch (e) {
      Logger.errorWithTag('ChatAgentProvider', 'Failed to update conversation title: $e');
    }
  }

  /// Start a new conversation
  ///
  /// Clears local state so the next message will trigger a new conversation
  /// creation via POST /api/v1/chat/conversations. The returned conversation_id
  /// is then used for all subsequent messages until deleted.
  void startNewConversation() {
    _updateState(_state.copyWith(
      messages: [],
      clearError: true,
      clearPendingAction: true,
      clearConversationId: true,
    ));
    Logger.infoWithTag('ChatAgentProvider', 'Ready for new conversation');
  }

  /// Clear the current conversation (local only, no backend call)
  void clearConversation() {
    _updateState(_state.copyWith(
      messages: [],
      clearError: true,
      clearPendingAction: true,
      clearConversationId: true,
    ));
  }

  /// Clear error state
  void clearError() {
    _updateState(_state.copyWith(clearError: true));
  }

  /// Select a conversation from history
  Future<void> selectConversation(String conversationId) async {
    await loadChatHistory(conversationId);
  }

  /// Delete a conversation from history
  ///
  /// Soft deletes the conversation on the backend via
  /// DELETE /api/v1/chat/conversations/{conversation_id}
  /// and removes it from local state.
  Future<void> deleteConversation(String conversationId) async {
    try {
      // Remove from local state immediately for responsiveness
      final updatedConversations = _state.conversations
          .where((c) => c.sessionId != conversationId)
          .toList();

      _updateState(_state.copyWith(conversations: updatedConversations));

      // If this was the current conversation, clear it
      if (_state.currentConversationId == conversationId) {
        _updateState(_state.copyWith(
          messages: [],
          clearPendingAction: true,
          clearConversationId: true,
        ));
      }

      // Soft delete on backend
      if (!_state.isOfflineMode) {
        try {
          final response = await _repository.deleteConversation(
            conversationId: conversationId,
          );
          if (response.success) {
            Logger.infoWithTag('ChatAgentProvider', 'Deleted conversation on backend: $conversationId');
          } else {
            Logger.warningWithTag('ChatAgentProvider', 'Backend delete returned: ${response.message}');
          }
        } on NotFoundException {
          // Already deleted or doesn't exist - that's fine
          Logger.infoWithTag('ChatAgentProvider', 'Conversation already deleted on backend: $conversationId');
        } on AuthException catch (e) {
          _handleAuthError(e);
          return;
        } on ApiException catch (e) {
          Logger.warningWithTag('ChatAgentProvider', 'Backend delete failed: ${e.message}');
          // Local state already updated, don't revert
        }
      }

      Logger.infoWithTag('ChatAgentProvider', 'Deleted conversation: $conversationId');

      // Persist updated sessions and clean up cached messages
      await _persistSessions();
      await _localRepository.deleteCachedAgentMessages(conversationId);
    } catch (e) {
      Logger.errorWithTag('ChatAgentProvider', 'Failed to delete conversation: $e');
    }
  }

  /// Save conversation to local history for sidebar display
  Future<void> _saveConversationToHistory(String conversationId, String userMessage, String? reply) async {
    try {
      // Generate a title from the first message (truncated)
      final title = userMessage.length > 30
          ? '${userMessage.substring(0, 30)}...'
          : userMessage;

      // Check if conversation already exists
      final existingIndex = _state.conversations.indexWhere(
        (c) => c.sessionId == conversationId,
      );

      final now = DateTime.now();
      final session = ChatSession(
        sessionId: conversationId,
        userId: '', // User ID will be filled by auth context if needed
        title: title,
        createdAt: existingIndex >= 0
            ? _state.conversations[existingIndex].createdAt
            : now,
        updatedAt: now,
        messageCount: existingIndex >= 0
            ? _state.conversations[existingIndex].messageCount + 2
            : 2,
      );

      List<ChatSession> updatedConversations;
      if (existingIndex >= 0) {
        // Update existing conversation
        updatedConversations = List.from(_state.conversations);
        updatedConversations[existingIndex] = session;
      } else {
        // Add new conversation at the beginning
        updatedConversations = [session, ..._state.conversations];
      }

      _updateState(_state.copyWith(conversations: updatedConversations));

      // Persist sessions and messages to Hive
      await _persistSessions();
      await _persistMessages(conversationId);
    } catch (e) {
      Logger.warningWithTag('ChatAgentProvider', 'Failed to save conversation to history: $e');
    }
  }

  /// Persist the current sessions list to Hive
  Future<void> _persistSessions() async {
    try {
      await _localRepository.cacheSessions(_localSessionsKey, _state.conversations);
    } catch (e) {
      Logger.warningWithTag('ChatAgentProvider', 'Failed to persist sessions to cache: $e');
    }
  }

  /// Persist messages for a conversation to Hive
  Future<void> _persistMessages(String conversationId) async {
    try {
      final messages = _state.messages
          .where((m) => m.conversationId == conversationId && !m.isLoading)
          .toList();
      await _localRepository.cacheAgentMessages(conversationId, messages);
    } catch (e) {
      Logger.warningWithTag('ChatAgentProvider', 'Failed to persist messages to cache: $e');
    }
  }
}
