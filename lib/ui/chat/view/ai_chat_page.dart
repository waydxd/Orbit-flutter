import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/agent_chat_message.dart';
import '../../../data/models/chat_session.dart';
import '../../../data/providers/chat_agent_provider.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/chat_exceptions.dart';

/// AI Chat Page integrated with Orbit-core chat and agent APIs
///
/// Implements the complete integration flow:
/// 1. User sends message → POST /api/v1/chat/messages
/// 2. Display AI response with optional pending action
/// 3. User can confirm/cancel pending actions for calendar events
///
/// API Endpoints:
/// - POST /api/v1/chat/messages - Send message and get AI response
/// - GET /api/v1/chat/conversations/{id} - Get conversation details
/// - POST /api/v1/chat/actions/{id}/confirm - Confirm action
/// - POST /api/v1/chat/actions/{id}/cancel - Cancel action
///
/// Error handling:
/// - 401: Redirect to login
/// - Network errors: Show retry option
/// - Other errors: Show error message
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
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late ChatAgentProvider _chatProvider;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
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
    // Redirect to login screen
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
    _showSnackBar('Session expired. Please login again.');
  }

  void _handleActionConfirmed(String? eventId) {
    _showSnackBar('Event created successfully!');
    _scrollToBottom();
  }

  void _handleActionCancelled() {
    _showSnackBar('Action cancelled.');
    _scrollToBottom();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _chatProvider.dispose();
    super.dispose();
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

    // Send message with calendar context
    await _chatProvider.sendMessage(
      content,
      context: AgentContextType.calendar,
    );

    _scrollToBottom();

    // Handle errors after send
    if (_chatProvider.state.hasError) {
      _handleError(_chatProvider.state.lastError);
    }
  }

  void _handleError(ApiException? error) {
    if (error == null) return;

    if (error is AuthException) {
      // Already handled by onAuthError callback
      return;
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

  IconData _getActionIcon(String actionType) {
    switch (actionType.toLowerCase()) {
      case 'create_event':
      case 'create':
        return Icons.add_circle_outline;
      case 'update_event':
      case 'update':
        return Icons.edit_outlined;
      case 'delete_event':
      case 'delete':
        return Icons.delete_outline;
      default:
        return Icons.event_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
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
      );
    }

    return ChangeNotifierProvider.value(
      value: _chatProvider,
      child: Consumer<ChatAgentProvider>(
        builder: (context, provider, child) {
          final hasMessages = provider.messages.isNotEmpty;

          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: Colors.white,
            drawer: _buildConversationDrawer(provider),
            body: SafeArea(
              child: Column(
                children: [
                  _buildHeader(context),
                  // Offline/Error banners
                  if (provider.isOfflineMode) _buildOfflineBanner(),
                  if (provider.hasError && !provider.isOfflineMode)
                    _buildErrorBanner(provider),
                  Expanded(
                    child: hasMessages
                        ? _buildMessagesList(provider)
                        : _buildWelcomeContent(),
                  ),
                  // Pending action card
                  if (provider.hasPendingAction)
                    _buildPendingActionCard(provider),
                  // Loading indicator
                  if (provider.isLoading)
                    const LinearProgressIndicator(
                      color: Color(0xFF6366F1),
                      backgroundColor: Color(0xFFE0E7FF),
                    ),
                  _buildInputSection(provider.isLoading || provider.isProcessingAction),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final hasMessages = _isInitialized && _chatProvider.messages.isNotEmpty;

    // Get current conversation title
    String? currentTitle;
    if (_isInitialized && _chatProvider.currentConversationId != null) {
      final currentConversation = _chatProvider.conversations.where(
        (c) => c.sessionId == _chatProvider.currentConversationId,
      ).firstOrNull;
      currentTitle = currentConversation?.title;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // Left side - Back/Close and History buttons
          Row(
            children: [
              if (hasMessages)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF6366F1), size: 28),
                  onPressed: () {
                    _chatProvider.startNewConversation();
                    _messageController.clear();
                  },
                  tooltip: 'Back to Welcome',
                )
              else
                // Close button on welcome page
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF6366F1), size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close Chat',
                ),
              // Chat history button (always visible when initialized)
              if (_isInitialized)
                IconButton(
                  icon: const Icon(Icons.history, color: Color(0xFF6366F1), size: 28),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  tooltip: 'Chat History',
                ),
            ],
          ),
          // Center - Conversation title (editable) when in conversation
          if (currentTitle != null && hasMessages)
            Expanded(
              child: GestureDetector(
                onTap: () => _showEditCurrentTitleDialog(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          // else if (!hasMessages)
          else
            const Expanded(child: SizedBox()),
          // Right side - New chat button (only when in conversation) or close button on welcome
          if (hasMessages)
            IconButton(
              icon: const Icon(Icons.add, color: Color(0xFF6366F1), size: 28),
              onPressed: () {
                _chatProvider.startNewConversation();
                _messageController.clear();
              },
              tooltip: 'New Chat',
            )
          else
            // Placeholder for alignment on welcome page
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  void _showEditCurrentTitleDialog() {
    if (_chatProvider.currentConversationId == null) return;

    final currentConversation = _chatProvider.conversations.where(
      (c) => c.sessionId == _chatProvider.currentConversationId,
    ).firstOrNull;

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

  Widget _buildConversationDrawer(ChatAgentProvider provider) {
    final conversations = provider.conversations;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Chat History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Color(0xFF6366F1)),
                    onPressed: () {
                      _chatProvider.startNewConversation();
                      _messageController.clear();
                      Navigator.of(context).pop();
                    },
                    tooltip: 'New Chat',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Conversation list
            Expanded(
              child: conversations.isEmpty
                  ? _buildEmptyHistoryState()
                  : ListView.builder(
                      itemCount: conversations.length,
                      itemBuilder: (context, index) {
                        final conversation = conversations[index];
                        final isSelected = provider.currentConversationId == conversation.sessionId;
                        return _buildConversationTile(conversation, isSelected);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHistoryState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start chatting to see your history here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationTile(ChatSession conversation, bool isSelected) {
    return ListTile(
      selected: isSelected,
      selectedTileColor: const Color(0xFFE0E7FF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6366F1)
              : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.chat,
          color: isSelected ? Colors.white : const Color(0xFF6366F1),
          size: 20,
        ),
      ),
      title: Text(
        conversation.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected
              ? const Color(0xFF6366F1)
              : const Color(0xFF1F2937),
        ),
      ),
      subtitle: Text(
        _formatTimestamp(conversation.updatedAt),
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: PopupMenuButton<String>(
        icon: Icon(
          Icons.more_vert,
          color: Colors.grey.shade600,
          size: 20,
        ),
        onSelected: (value) {
          if (value == 'delete') {
            _showDeleteConfirmation(conversation.sessionId);
          } else if (value == 'rename') {
            _showRenameDialog(conversation);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'rename',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 20, color: Color(0xFF6366F1)),
                SizedBox(width: 8),
                Text('Rename', style: TextStyle(color: Color(0xFF6366F1))),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 20, color: Colors.red),
                SizedBox(width: 8),
                Text('Delete', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
      onTap: () {
        _chatProvider.selectConversation(conversation.sessionId);
        Navigator.of(context).pop();
      },
    );
  }

  void _showRenameDialog(ChatSession conversation) {
    final TextEditingController titleController = TextEditingController(
      text: conversation.title,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.edit_outlined, color: Color(0xFF6366F1), size: 24),
            SizedBox(width: 8),
            Text('Rename'),
          ],
        ),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter new title',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E7FF)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              _chatProvider.updateConversationTitle(
                conversation.sessionId,
                value.trim(),
              );
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final newTitle = titleController.text.trim();
              if (newTitle.isNotEmpty) {
                _chatProvider.updateConversationTitle(
                  conversation.sessionId,
                  newTitle,
                );
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
  }

  void _showDeleteConfirmation(String conversationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: const Text(
          'Are you sure you want to delete this conversation? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _chatProvider.deleteConversation(conversationId);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingActionCard(ChatAgentProvider provider) {
    final action = provider.currentPendingAction;
    if (action == null) return const SizedBox.shrink();

    final isProcessing = provider.isProcessingAction;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getActionIcon(action.type),
                  color: const Color(0xFF6366F1),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getActionDisplayName(action.type),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                    const Text(
                      'Tap Confirm to proceed or Cancel to dismiss',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF5E6272),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!isProcessing)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: const Color(0xFF9CA3AF),
                  onPressed: () => _chatProvider.dismissPendingAction(),
                  tooltip: 'Dismiss',
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isProcessing ? null : () => _chatProvider.cancelPendingAction(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6B7280),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: provider.isCancellingAction
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF6B7280),
                          ),
                        )
                      : const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: isProcessing ? null : () => _chatProvider.confirmPendingAction(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: provider.isConfirmingAction
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Confirm'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getActionDisplayName(String actionType) {
    switch (actionType) {
      case 'create_event':
        return 'Create Event';
      case 'update_event':
        return 'Update Event';
      case 'delete_event':
        return 'Delete Event';
      case 'create_task':
        return 'Create Task';
      case 'update_task':
        return 'Update Task';
      case 'delete_task':
        return 'Delete Task';
      default:
        return 'Pending Action';
    }
  }

  Widget _buildWelcomeContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          const SizedBox(height: 10),
          _buildAvatar(),
          const SizedBox(height: 20),
          _buildSuggestionsCard(),
          const SizedBox(height: 30),
          _buildChatBubble('Hi, I am Orbi! \n How can I help you?'),
          const SizedBox(height: 20),
        ],
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
    final isUser = message.isUser;
    final isLoading = message.isLoading;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildSmallAvatar(),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: isUser
                        ? const Color(0xFF6366F1)
                        : const Color(0xFFF8F9FE),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 50,
                          height: 20,
                          child: Center(
                            child: SizedBox(
                              width: 40,
                              child: LinearProgressIndicator(
                                color: Color(0xFF6366F1),
                                backgroundColor: Color(0xFFE0E7FF),
                              ),
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isUser && message.agentType != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  message.agentType!.displayName,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6366F1),
                                  ),
                                ),
                              ),
                            Text(
                              message.content,
                              style: TextStyle(
                                color: isUser
                                    ? Colors.white
                                    : const Color(0xFF5E6272),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            // Show action summary if present
                            if (message.hasAction && message.actionSummary != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getActionIcon(message.actionType ?? ''),
                                        size: 16,
                                        color: const Color(0xFF6366F1),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          message.actionSummary!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF6366F1),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
                // Show action buttons for messages with pending actions
                if (message.hasAction)
                  _buildMessageActionButtons(message),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildMessageActionButtons(AgentChatMessage message) {
    final isPending = message.hasPendingAction;
    final isConfirmed = message.actionStatus == 'confirmed';
    final isCancelled = message.actionStatus == 'cancelled';
    final isProcessing = _chatProvider.isProcessingAction;

    // Show status badge for non-pending actions
    if (!isPending) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isConfirmed
                ? const Color(0xFF10B981).withValues(alpha: 0.1)
                : isCancelled
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.1)
                    : const Color(0xFFEF4444).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isConfirmed
                    ? Icons.check_circle_outline
                    : isCancelled
                        ? Icons.cancel_outlined
                        : Icons.timer_off_outlined,
                size: 14,
                color: isConfirmed
                    ? const Color(0xFF10B981)
                    : isCancelled
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFEF4444),
              ),
              const SizedBox(width: 4),
              Text(
                isConfirmed
                    ? 'Confirmed'
                    : isCancelled
                        ? 'Cancelled'
                        : 'Expired',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isConfirmed
                      ? const Color(0xFF10B981)
                      : isCancelled
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show confirm/cancel buttons for pending actions
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cancel button
          OutlinedButton.icon(
            onPressed: isProcessing
                ? null
                : () => _chatProvider.cancelMessageAction(message.actionId!),
            icon: _chatProvider.isCancellingAction
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF6B7280),
                    ),
                  )
                : const Icon(Icons.close, size: 14),
            label: const Text('Cancel'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6B7280),
              side: const BorderSide(color: Color(0xFFD1D5DB)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Confirm button
          ElevatedButton.icon(
            onPressed: isProcessing
                ? null
                : () => _chatProvider.confirmMessageAction(message.actionId!),
            icon: _chatProvider.isConfirmingAction
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check, size: 14),
            label: const Text('Confirm'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE0E7FF),
            Color(0xFFC7D2FE),
            Color(0xFF818CF8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.auto_awesome, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildAvatar() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow layers
          for (int i = 1; i <= 3; i++)
            Container(
              width: 100.0 + (i * 20),
              height: 100.0 + (i * 20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6366F1).withValues(alpha: 0.15 / i),
                    const Color(0xFF6366F1).withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          // Inner Orb
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE0E7FF),
                  Color(0xFFC7D2FE),
                  Color(0xFF818CF8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                  blurRadius: 25,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.auto_awesome, color: Colors.white, size: 36),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FE),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                color: Color(0xFF6366F1),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'You can ask me about...',
                style: TextStyle(
                  color: Color(0xFF5E6272),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildSuggestionChip('Task creation'),
              _buildSuggestionChip('Available time'),
              _buildSuggestionChip('Rearrange schedules'),
              _buildSuggestionChip('Next event'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String label) {
    return GestureDetector(
      onTap: () => _sendMessage(_getSuggestionPrompt(label)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF6366F1).withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF5E6272),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  String _getSuggestionPrompt(String label) {
    switch (label) {
      case 'Task creation':
        return 'Help me create a new task';
      case 'Available time':
        return 'What are my available time slots today?';
      case 'Rearrange schedules':
        return 'Can you help me rearrange my schedules?';
      case 'Next event':
        return 'What is my next event?';
      default:
        return label;
    }
  }

  Widget _buildChatBubble(String text) {
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

  Widget _buildInputSection(bool isLoading) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 0, 25, 25),
      child: Row(
        children: [
          // Chat mode dropdown
          _buildChatModeDropdown(),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E7FF), width: 1.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _messageController,
                        focusNode: _focusNode,
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: _chatProvider.isAgentMode
                              ? 'Create an event...'
                              : 'Ask me anything...',
                          hintStyle: const TextStyle(
                            color: Color(0xFFB0B5C3),
                            fontSize: 15,
                          ),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: isLoading ? null : (_) => _sendMessage(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 15),
          GestureDetector(
            onTap: isLoading ? null : () => _sendMessage(),
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: isLoading
                    ? const Color(0xFFE0E7FF)
                    : const Color(0xFF6366F1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send_rounded,
                color: isLoading ? const Color(0xFF6366F1) : Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatModeDropdown() {
    return Container(
      height: 54,
      width: 95,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _chatProvider.isAgentMode
            ? const Color(0xFF6366F1).withValues(alpha: 0.1)
            : const Color(0xFFF8F9FE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _chatProvider.isAgentMode
              ? const Color(0xFF6366F1)
              : const Color(0xFFE0E7FF),
          width: 1.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ChatMode>(
          value: _chatProvider.chatMode,
          isDense: true,
          isExpanded: false,
          icon: Icon(
            Icons.expand_more,
            color: _chatProvider.isAgentMode
                ? const Color(0xFF6366F1)
                : const Color(0xFF5E6272),
            size: 15,
          ),
          borderRadius: BorderRadius.circular(16),
          dropdownColor: Colors.white,
          onChanged: (ChatMode? newValue) {
            if (newValue != null) {
              _chatProvider.setChatMode(newValue);
              setState(() {});
            }
          },
          items: ChatMode.values.map<DropdownMenuItem<ChatMode>>((ChatMode mode) {
            return DropdownMenuItem<ChatMode>(
              value: mode,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    mode == ChatMode.agent
                        ? Icons.smart_toy_outlined
                        : Icons.chat_bubble_outline,
                    size: 12,
                    color: mode == ChatMode.agent
                        ? const Color(0xFF6366F1)
                        : const Color(0xFF5E6272),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    mode == ChatMode.agent ? 'Agent' : 'Ask',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: mode == ChatMode.agent
                          ? const Color(0xFF6366F1)
                          : const Color(0xFF5E6272),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
