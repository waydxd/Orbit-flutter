import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/chat_action.dart';
import '../../data/models/chat_context.dart';
import '../../data/providers/chatbot_provider.dart';
import 'widgets/chat_message_bubble.dart';
import 'widgets/chat_input_field.dart';
import 'chat_history_screen.dart';

/// Main chatbot screen for AI assistant conversations
class ChatbotScreen extends StatefulWidget {
  final String userId;
  final String? initialSessionId;

  const ChatbotScreen({
    super.key,
    required this.userId,
    this.initialSessionId,
  });

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final ScrollController _scrollController = ScrollController();
  late ChatbotProvider _chatProvider;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    _chatProvider = ChatbotProvider(userId: widget.userId);
    await _chatProvider.initialize();
    await _chatProvider.initSession(sessionId: widget.initialSessionId);

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
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

  void _handleSendMessage(String content) {
    // Build context from current calendar data
    final context = ChatContext(
      currentDate: DateTime.now(),
      upcomingEvents: [], // TODO: Get from calendar provider
      userPreferences: {}, // TODO: Get from user preferences
    );

    // Use regular HTTP endpoint (backend doesn't support WebSocket streaming)
    _chatProvider.sendMessage(content, context: context);
    _scrollToBottom();
  }

  void _handleAction(ChatAction action) {
    switch (action.actionType) {
      case ActionType.createEvent:
        // TODO: Navigate to create event screen with payload data
        _showSnackBar('Creating event...');
        break;
      case ActionType.modifyEvent:
        // TODO: Navigate to edit event screen
        _showSnackBar('Opening event editor...');
        break;
      case ActionType.deleteEvent:
        // TODO: Confirm and delete event
        _showSnackBar('Deleting event...');
        break;
      case ActionType.showCalendar:
        // TODO: Navigate to calendar view
        Navigator.of(context).pop();
        break;
      case ActionType.setSuggestion:
        // TODO: Apply suggestion
        _showSnackBar('Applying suggestion...');
        break;
      case ActionType.openLink:
        // TODO: Open URL
        _showSnackBar('Opening link...');
        break;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatHistoryScreen(
          userId: widget.userId,
          chatProvider: _chatProvider,
        ),
      ),
    ).then((_) {
      // Refresh on return
      if (mounted) setState(() {});
    });
  }

  void _startNewChat() async {
    _chatProvider.clearChat();
    await _chatProvider.initSession();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Orbit Assistant'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return ChangeNotifierProvider.value(
      value: _chatProvider,
      child: Consumer<ChatbotProvider>(
        builder: (context, provider, _) {
          // Auto-scroll when messages change
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (provider.messages.isNotEmpty) {
              _scrollToBottom();
            }
          });

          return Scaffold(
            appBar: _buildAppBar(provider),
            body: Column(
              children: [
                // Offline/Error banner
                if (provider.isOfflineMode || provider.hasError)
                  _buildStatusBanner(provider),

                // Messages list
                Expanded(
                  child: provider.messages.isEmpty
                      ? _buildEmptyState()
                      : _buildMessageList(provider),
                ),

                // Input field
                ChatInputField(
                  onSend: _handleSendMessage,
                  isLoading: provider.isLoading,
                  enabled: !provider.isOfflineMode,
                  hintText: provider.isOfflineMode
                      ? 'Offline - Cannot send messages'
                      : 'Ask about your schedule, create events...',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  AppBar _buildAppBar(ChatbotProvider provider) {
    final theme = Theme.of(context);

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Orbit Assistant'),
          if (provider.isOfflineMode)
            Text(
              'Offline',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.history),
          tooltip: 'Chat History',
          onPressed: _navigateToHistory,
        ),
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'New Chat',
          onPressed: _startNewChat,
        ),
      ],
    );
  }

  Widget _buildStatusBanner(ChatbotProvider provider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isOffline = provider.isOfflineMode;
    final hasError = provider.hasError && !isOffline;

    return Material(
      color: isOffline
          ? colorScheme.errorContainer.withOpacity(0.3)
          : colorScheme.errorContainer,
      child: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                isOffline ? Icons.cloud_off : Icons.error_outline,
                color: colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isOffline
                      ? 'You\'re offline. Messages will sync when connected.'
                      : provider.error ?? 'An error occurred',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ),
              if (isOffline)
                TextButton(
                  onPressed: provider.retryConnection,
                  child: const Text('Retry'),
                )
              else if (hasError)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: provider.clearError,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList(ChatbotProvider provider) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: provider.messages.length,
      itemBuilder: (context, index) {
        return ChatMessageBubble(
          message: provider.messages[index],
          onActionTap: _handleAction,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 40,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Start a conversation',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Ask me to help with scheduling, finding free time, or managing your events.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip('What\'s on my calendar today?'),
                _buildSuggestionChip('Schedule a meeting tomorrow'),
                _buildSuggestionChip('Find free time this week'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ActionChip(
      label: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: colorScheme.primary,
        ),
      ),
      onPressed: () => _handleSendMessage(text),
      backgroundColor: colorScheme.primary.withOpacity(0.1),
      side: BorderSide(
        color: colorScheme.primary.withOpacity(0.3),
      ),
    );
  }
}

