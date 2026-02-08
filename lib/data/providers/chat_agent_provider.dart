import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/agent_chat_message.dart';
import '../models/chat_session.dart';
import '../services/api_client.dart';
import '../services/chat_api_service.dart';
import '../services/chat_exceptions.dart';
import '../repositories/chat_repository.dart';
import '../../utils/logger.dart';

/// Chat mode enum for Ask mode and Agent mode
enum ChatMode {
  ask,   // Normal conversation mode
  agent, // Agent mode that allows creating calendar events
}

extension ChatModeExtension on ChatMode {
  String get displayName {
    switch (this) {
      case ChatMode.ask:
        return 'Ask Mode';
      case ChatMode.agent:
        return 'Agent Mode';
    }
  }

  String get description {
    switch (this) {
      case ChatMode.ask:
        return 'Normal conversation';
      case ChatMode.agent:
        return 'Create calendar events';
    }
  }
}

/// Pending action info for UI display
class PendingActionInfo {
  final String actionId;
  final String type;
  final String status;

  PendingActionInfo({
    required this.actionId,
    required this.type,
    required this.status,
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
  final String? errorMessage;
  final ApiException? lastError;

  // Chat mode support
  final ChatMode chatMode;

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
    this.errorMessage,
    this.lastError,
    this.chatMode = ChatMode.ask,
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
    String? errorMessage,
    ApiException? lastError,
    ChatMode? chatMode,
    PendingActionInfo? currentPendingAction,
    bool? isConfirmingAction,
    bool? isCancellingAction,
    bool clearError = false,
    bool clearPendingAction = false,
  }) {
    return ChatAgentState(
      messages: messages ?? this.messages,
      conversations: conversations ?? this.conversations,
      currentConversationId: currentConversationId ?? this.currentConversationId,
      isLoading: isLoading ?? this.isLoading,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastError: clearError ? null : (lastError ?? this.lastError),
      chatMode: chatMode ?? this.chatMode,
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
  bool get isAgentMode => chatMode == ChatMode.agent;
}

/// Provider for chat with AI agent functionality
///
/// Integrates with Orbit-core chat endpoints (chat.yaml):
/// - POST /api/v1/chat/messages - Send message
/// - GET /api/v1/chat/conversations/{id} - Get conversation details
/// - GET /api/v1/chat/actions/{id} - Get action details
/// - POST /api/v1/chat/actions/{id}/confirm - Confirm pending action
/// - POST /api/v1/chat/actions/{id}/cancel - Cancel pending action
class ChatAgentProvider extends ChangeNotifier {
  final ChatRepository _repository;
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
  String? get errorMessage => _state.errorMessage;
  bool get hasError => _state.hasError;

  // Chat mode getters
  ChatMode get chatMode => _state.chatMode;
  bool get isAgentMode => _state.isAgentMode;

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
    this.onAuthError,
    this.onActionConfirmed,
    this.onActionCancelled,
  }) : _repository = ChatRepository(
          apiService: ChatApiService(apiClient),
        );

  /// Factory constructor for dependency injection
  ChatAgentProvider.withRepository({
    required ChatRepository repository,
    this.onAuthError,
    this.onActionConfirmed,
    this.onActionCancelled,
  }) : _repository = repository;

  void _updateState(ChatAgentState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Initialize the provider
  Future<void> initialize() async {
    await _repository.initialize();
    await loadConversations();
  }

  /// Load all conversations for the user
  /// Note: Backend doesn't provide GET /conversations endpoint, so we use local state only
  Future<void> loadConversations() async {
    // The backend doesn't have a GET /conversations endpoint to list all conversations
    // Conversations are tracked locally in state and persisted when messages are sent
    // This is intentional as per the backend API spec (chat.yaml)
    _updateState(_state.copyWith(
      isLoadingHistory: false,
      clearError: true,
    ));
  }

  /// Load chat history for a conversation
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
        );
      }

      _updateState(_state.copyWith(
        messages: messages,
        isLoadingHistory: false,
        isOfflineMode: false,
        currentPendingAction: pendingAction,
      ));
    } on AuthException catch (e) {
      _handleAuthError(e);
    } on NetworkException catch (e) {
      _updateState(_state.copyWith(
        isLoadingHistory: false,
        isOfflineMode: true,
        errorMessage: e.message,
        lastError: e,
      ));
    } on NotFoundException catch (e) {
      _updateState(_state.copyWith(
        isLoadingHistory: false,
        messages: [],
        errorMessage: e.message,
        lastError: e,
      ));
    } on ApiException catch (e) {
      _updateState(_state.copyWith(
        isLoadingHistory: false,
        errorMessage: e.message,
        lastError: e,
      ));
    }
  }

  /// Send a message and get AI agent response
  Future<void> sendMessage(
    String content, {
    AgentContextType context = AgentContextType.calendar,
  }) async {
    // Use existing conversation ID or null for new conversations
    // The backend will create a new conversation if ID is null or not found
    final conversationId = _state.currentConversationId;

    // Create temporary conversation ID for UI messages (will be updated with backend ID)
    final tempConversationId = conversationId ?? 'temp-${_uuid.v4()}';

    // Create user message
    final userMessage = AgentChatMessage.user(
      id: _uuid.v4(),
      conversationId: tempConversationId,
      content: content,
    );

    // Create loading placeholder for agent response
    final loadingMessage = AgentChatMessage.loading(
      id: _uuid.v4(),
      conversationId: tempConversationId,
    );

    // Add messages to state immediately
    _updateState(_state.copyWith(
      messages: [..._state.messages, userMessage, loadingMessage],
      currentConversationId: tempConversationId,
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
      // Send message using new API
      // Don't send conversation_id if it's a temp ID - let backend create a new one
      final result = await _repository.sendChatMessage(
        content: content,
        conversationId: conversationId, // null for new conversations, actual ID for existing
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

      // Use the conversation ID returned from the backend
      // The backend creates a new conversation if conversationId was null
      final actualConversationId = result.conversationId;

      // Use the reply directly from the sendChatMessage result
      // The backend returns the AI response in the reply field
      final assistantReply = result.reply;

      // Replace loading message and update conversation IDs with actual backend ID
      final updatedMessages = _state.messages
          .where((m) => !m.isLoading)
          .map((m) => m.conversationId == tempConversationId
              ? m.copyWith(conversationId: actualConversationId)
              : m)
          .toList();

      if (assistantReply != null && assistantReply.isNotEmpty) {
        // In agent mode, attach action info to the message if there's a proposed action
        if (_state.isAgentMode && result.hasProposedAction && result.actionId != null) {
          updatedMessages.add(AgentChatMessage.agentWithAction(
            id: result.messageId,
            conversationId: actualConversationId,
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
            conversationId: actualConversationId,
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
      await _saveConversationToHistory(actualConversationId, content, assistantReply);

      _updateState(_state.copyWith(
        messages: updatedMessages,
        currentConversationId: actualConversationId,
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

    await confirmMessageAction(action.actionId);
  }

  /// Confirm an action by action ID (used in Agent mode for per-message actions)
  Future<void> confirmMessageAction(String actionId) async {
    _updateState(_state.copyWith(
      isConfirmingAction: true,
      clearError: true,
    ));

    try {
      final result = await _repository.confirmAction(
        actionId: actionId,
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

  /// Set the chat mode
  void setChatMode(ChatMode mode) {
    if (_state.chatMode != mode) {
      _updateState(_state.copyWith(chatMode: mode));
      Logger.infoWithTag('ChatAgentProvider', 'Chat mode changed to: ${mode.displayName}');
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
        Logger.infoWithTag('ChatAgentProvider', 'Updated conversation title: $newTitle');
      }
    } catch (e) {
      Logger.errorWithTag('ChatAgentProvider', 'Failed to update conversation title: $e');
    }
  }

  /// Start a new conversation
  void startNewConversation() {
    _updateState(_state.copyWith(
      messages: [],
      currentConversationId: null,
      clearError: true,
      clearPendingAction: true,
    ));
  }

  /// Clear the current conversation
  void clearConversation() {
    _updateState(_state.copyWith(
      messages: [],
      currentConversationId: null,
      clearError: true,
      clearPendingAction: true,
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
  Future<void> deleteConversation(String conversationId) async {
    try {
      // Remove from local state
      final updatedConversations = _state.conversations
          .where((c) => c.sessionId != conversationId)
          .toList();

      _updateState(_state.copyWith(conversations: updatedConversations));

      // If this was the current conversation, clear it
      if (_state.currentConversationId == conversationId) {
        startNewConversation();
      }

      Logger.infoWithTag('ChatAgentProvider', 'Deleted conversation: $conversationId');
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
    } catch (e) {
      Logger.warningWithTag('ChatAgentProvider', 'Failed to save conversation to history: $e');
    }
  }
}
