import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/agent_chat_message.dart';
import '../../../data/providers/chat_agent_provider.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/chat_exceptions.dart';
import '../widgets/chat_widgets.dart';
import '../../calendar/view_model/calendar_view_model.dart';
import '../../auth/view_model/auth_view_model.dart';

/// AI Chat Page integrated with Orbit-core chat and agent APIs
///
/// Features:
/// 1. Welcome page with Orbi avatar and suggestion chips
/// 2. Conversation page with message history
/// 3. Chat mode dropdown (Ask mode / Agent mode)
/// 4. Conversation history drawer
/// 5. Pending action confirmation/cancellation in Agent mode
/// 6. Editable conversation titles
/// 7. Service health check on initialization
///
/// API Endpoints used (from chat.yaml):
/// - GET /api/v1/chat/health - Check service health
/// - POST /api/v1/chat/conversations - Create a new conversation
/// - GET /api/v1/chat/conversations/{id} - Get conversation details
/// - DELETE /api/v1/chat/conversations/{id} - Soft delete conversation
/// - POST /api/v1/chat/messages - Send message and get AI response
/// - GET /api/v1/chat/actions/{id} - Get action details
/// - POST /api/v1/chat/actions/{id}/confirm - Confirm action
/// - POST /api/v1/chat/actions/{id}/cancel - Cancel action
/// - GET /api/v1/chat/metrics - Get chat metrics
class AiChatPage extends StatefulWidget {
  final String? initialConversationId;

  const AiChatPage({
    super.key,
    this.initialConversationId,
  });

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  static const BoxDecoration _pageBackgroundDecoration = BoxDecoration(
    color: Colors.white,
  );

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late ChatAgentProvider _chatProvider;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final apiClient = ApiClient();

    _chatProvider = ChatAgentProvider(
      apiClient: apiClient,
      onAuthError: _handleAuthError,
      onActionConfirmed: _handleActionConfirmed,
      onActionCancelled: _handleActionCancelled,
    );

    await _chatProvider.initialize();

    if (widget.initialConversationId != null) {
      await _chatProvider.loadChatHistory(widget.initialConversationId!);
    }

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _handleAuthError() {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    _showSnackBar('Session expired. Please login again.');
  }

  void _handleActionConfirmed(String? eventId) {
    _showSnackBar('Event created successfully!');
    _scrollToBottom();
    // Refresh the calendar view from the database since an event was created
    final userId = context.read<AuthViewModel>().currentUser?.id;
    if (userId != null) {
      context.read<CalendarViewModel>().fetchAll(userId: userId);
    }
  }

  void _handleActionCancelled() {
    _showSnackBar('Action cancelled.');
    _scrollToBottom();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _chatProvider.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {});
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage([String? suggestedMessage]) async {
    final content = suggestedMessage ?? _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    _focusNode.unfocus();

    await _chatProvider.sendMessage(
      content,
      context: AgentContextType.calendar,
    );

    _scrollToBottom();

    if (_chatProvider.state.hasError) {
      _handleError(_chatProvider.state.lastError);
    }
  }

  void _handleError(ApiException? error) {
    if (error == null) return;

    if (error is AuthException) {
      return; // Already handled by onAuthError callback
    }

    if (error is NetworkException) {
      _showRetrySnackBar(error.message);
      return;
    }

    _showSnackBar(error.message);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showRetrySnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () => _chatProvider.retry(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        body: Container(
          decoration: _pageBackgroundDecoration,
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, hasMessages: false),
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ChangeNotifierProvider.value(
      value: _chatProvider,
      child: Consumer<ChatAgentProvider>(
        builder: (context, provider, child) {
          final hasMessages = provider.messages.isNotEmpty;

          return Scaffold(
            key: _scaffoldKey,
            endDrawer: ConversationDrawer(
              conversations: provider.conversations,
              currentConversationId: provider.currentConversationId,
              onNewChat: () {
                _messageController.clear();
                _chatProvider.startNewConversation();
              },
              onSelectConversation: (id) =>
                  _chatProvider.selectConversation(id),
              onRenameConversation: _showRenameDialog,
              onDeleteConversation: _showDeleteConfirmation,
            ),
            body: Container(
              decoration: _pageBackgroundDecoration,
              child: SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context, hasMessages: hasMessages),
                    // Offline/Error banners
                    if (provider.isOfflineMode) _buildOfflineBanner(),
                    if (provider.hasError && !provider.isOfflineMode)
                      _buildErrorBanner(provider),
                    Expanded(
                      child: hasMessages
                          ? _buildMessagesList(provider)
                          : _buildWelcomeContent(),
                    ),
                    _buildInputSection(
                        provider.isLoading || provider.isProcessingAction),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {required bool hasMessages}) {
    String? currentTitle;
    if (_isInitialized && _chatProvider.currentConversationId != null) {
      final matchingConversations = _chatProvider.conversations.where(
        (c) => c.sessionId == _chatProvider.currentConversationId,
      );
      final currentConversation =
          matchingConversations.isNotEmpty ? matchingConversations.first : null;
      currentTitle = currentConversation?.title;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // Left side buttons
          Row(
            children: [
              IconButton(
                  icon: const Icon(Icons.close,
                      color: Color(0xFF6366F1), size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close Chat'),
            ],
          ),
          // Center - Editable conversation title
          if (currentTitle != null && hasMessages)
            Expanded(
              child: GestureDetector(
                onTap: () => _showEditCurrentTitleDialog(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          currentTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: Color(0xFF9CA3AF),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            const Expanded(child: SizedBox()),
          // Right side button
          if (_isInitialized)
            IconButton(
              icon:
                  const Icon(Icons.history, color: Color(0xFF6366F1), size: 28),
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
              tooltip: 'Chat History',
            ),
        ],
      ),
    );
  }

  void _showEditCurrentTitleDialog() {
    if (_chatProvider.currentConversationId == null) return;

    final currentConversation = _chatProvider.conversations
        .where(
          (c) => c.sessionId == _chatProvider.currentConversationId,
        )
        .firstOrNull;

    if (currentConversation != null) {
      _showRenameDialog(currentConversation);
    }
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      color: const Color(0xFFFFF3E0),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'You are offline. Some features may be limited.',
              style: TextStyle(color: Colors.orange, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () => _chatProvider.retry(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(ChatAgentProvider provider) {
    final canRetry = provider.state.canRetry;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      color: const Color(0xFFFFEBEE),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              provider.errorMessage ?? 'An error occurred',
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
          if (canRetry)
            TextButton(
              onPressed: () => _chatProvider.retry(),
              child: const Text('Retry'),
            )
          else
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => _chatProvider.clearError(),
            ),
        ],
      ),
    );
  }

  Widget _buildWelcomeContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          const SizedBox(height: 10),
          const OrbiAvatar(),
          const SizedBox(height: 20),
          SuggestionsCard(
            onSuggestionTap: _sendMessage,
          ),
          const SizedBox(height: 30),
          _buildWelcomeBubble('Hi, I am Orbi! \n How can I help you?'),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildWelcomeBubble(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF5E6272),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMessagesList(ChatAgentProvider provider) {
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: provider.messages.length,
      itemBuilder: (context, index) {
        final message = provider.messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(AgentChatMessage message) {
    Widget? actionButtons;

    if (message.hasAction) {
      if (message.hasPendingAction) {
        actionButtons = MessageActionButtons(
          onConfirm: () =>
              _chatProvider.confirmMessageAction(message.actionId!),
          onCancel: () => _chatProvider.cancelMessageAction(message.actionId!),
          isConfirming: _chatProvider.isConfirmingAction,
          isCancelling: _chatProvider.isCancellingAction,
          isDisabled: _chatProvider.isProcessingAction,
        );
      } else {
        actionButtons =
            ActionStatusBadge(status: message.actionStatus ?? 'unknown');
      }
    }

    return ChatMessageBubble(
      message: message,
      actionButtons: actionButtons,
    );
  }

  Widget _buildInputSection(bool isLoading) {
    final isFocused = _focusNode.hasFocus;
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 0, 25, 25),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(27),
          border: Border.all(
            color:
                isFocused ? const Color(0xFF6366F1) : const Color(0xFFE0E7FF),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 10),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  enabled: !isLoading,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    filled: true,
                    fillColor: Colors.transparent,
                    hintText: 'Ask me anything...',
                    hintStyle: TextStyle(
                      color: Color(0xFFB0B5C3),
                      fontSize: 15,
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: isLoading ? null : (_) => _sendMessage(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: GestureDetector(
                onTap: isLoading ? null : () => _sendMessage(),
                child: Container(
                  width: 44,
                  height: 44,
                  color: Colors.transparent,
                  child: Icon(
                    Icons.send_rounded,
                    color: isLoading
                        ? const Color(0xFFE0E7FF)
                        : const Color(0xFF6366F1),
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(ChatSession conversation) {
    showDialog(
      context: context,
      builder: (context) => RenameConversationDialog(
        conversation: conversation,
        onRename: (id, newTitle) =>
            _chatProvider.updateConversationTitle(id, newTitle),
      ),
    );
  }

  void _showDeleteConfirmation(String conversationId) {
    showDialog(
      context: context,
      builder: (context) => DeleteConversationDialog(
        conversationId: conversationId,
        onDelete: () => _chatProvider.deleteConversation(conversationId),
      ),
    );
  }
}
