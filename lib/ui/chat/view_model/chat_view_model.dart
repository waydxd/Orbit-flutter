import 'package:flutter/foundation.dart';
import '../../../data/providers/chat_agent_provider.dart';
import '../../../data/services/api_client.dart';
import '../../../data/models/agent_chat_message.dart';

export '../../../data/providers/chat_agent_provider.dart';
export '../../../data/models/agent_chat_message.dart' show AgentContextType;

/// ViewModel for the Chat page
///
/// This is a thin wrapper around ChatAgentProvider that provides
/// a consistent interface for the chat UI following MVVM pattern.
///
/// Features:
/// - Welcome page with suggestions
/// - Conversation history in drawer
/// - Ask mode vs Agent mode toggle
/// - Pending action confirmation/cancellation
/// - Editable conversation titles
class ChatViewModel extends ChangeNotifier {
  late final ChatAgentProvider _provider;

  // Callbacks
  final void Function()? onAuthError;
  final void Function(String? eventId)? onActionConfirmed;
  final void Function()? onActionCancelled;

  ChatViewModel({
    required ApiClient apiClient,
    this.onAuthError,
    this.onActionConfirmed,
    this.onActionCancelled,
  }) {
    _provider = ChatAgentProvider(
      apiClient: apiClient,
      onAuthError: onAuthError,
      onActionConfirmed: onActionConfirmed,
      onActionCancelled: onActionCancelled,
    );

    // Forward notifications from provider
    _provider.addListener(_onProviderChanged);
  }

  /// Factory constructor for dependency injection with existing provider
  ChatViewModel.withProvider({
    required ChatAgentProvider provider,
    this.onAuthError,
    this.onActionConfirmed,
    this.onActionCancelled,
  }) : _provider = provider {
    _provider.addListener(_onProviderChanged);
  }

  void _onProviderChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChanged);
    _provider.dispose();
    super.dispose();
  }

  /// Get the underlying provider for direct access if needed
  ChatAgentProvider get provider => _provider;

  // ============== State Getters ==============

  ChatAgentState get state => _provider.state;
  List<AgentChatMessage> get messages => _provider.messages;
  List<ChatSession> get conversations => _provider.conversations;
  String? get currentConversationId => _provider.currentConversationId;
  bool get isLoading => _provider.isLoading;
  bool get isLoadingHistory => _provider.isLoadingHistory;
  bool get isOfflineMode => _provider.isOfflineMode;
  bool get isServiceHealthy => _provider.isServiceHealthy;
  String? get errorMessage => _provider.errorMessage;
  bool get hasError => _provider.hasError;

  // Pending actions
  PendingActionInfo? get currentPendingAction => _provider.currentPendingAction;
  bool get hasPendingAction => _provider.hasPendingAction;
  bool get isConfirmingAction => _provider.isConfirmingAction;
  bool get isCancellingAction => _provider.isCancellingAction;
  bool get isProcessingAction => _provider.isProcessingAction;

  // ============== Actions ==============

  /// Initialize the view model
  Future<void> initialize() => _provider.initialize();

  /// Check chat service health
  Future<bool> checkServiceHealth() => _provider.checkServiceHealth();

  /// Send a message
  Future<void> sendMessage(String content,
          {AgentContextType context = AgentContextType.calendar}) =>
      _provider.sendMessage(content, context: context);

  /// Load chat history for a conversation
  Future<void> loadChatHistory(String conversationId) =>
      _provider.loadChatHistory(conversationId);

  /// Confirm the current pending action
  Future<void> confirmPendingAction() => _provider.confirmPendingAction();

  /// Cancel the current pending action
  Future<void> cancelPendingAction() => _provider.cancelPendingAction();

  /// Confirm a specific action by ID
  Future<void> confirmMessageAction(String actionId) =>
      _provider.confirmMessageAction(actionId);

  /// Cancel a specific action by ID
  Future<void> cancelMessageAction(String actionId) =>
      _provider.cancelMessageAction(actionId);

  /// Dismiss pending action without server call
  void dismissPendingAction() => _provider.dismissPendingAction();

  /// Start a new conversation (conversation_id created on first message)
  void startNewConversation() => _provider.startNewConversation();

  /// Clear conversation (local only)
  void clearConversation() => _provider.clearConversation();

  /// Select a conversation from history
  Future<void> selectConversation(String conversationId) =>
      _provider.selectConversation(conversationId);

  /// Update conversation title
  Future<void> updateConversationTitle(
          String conversationId, String newTitle) =>
      _provider.updateConversationTitle(conversationId, newTitle);

  /// Delete a conversation (soft delete on backend)
  Future<void> deleteConversation(String conversationId) =>
      _provider.deleteConversation(conversationId);

  /// Retry failed operation
  Future<void> retry() => _provider.retry();

  /// Clear error state
  void clearError() => _provider.clearError();
}
