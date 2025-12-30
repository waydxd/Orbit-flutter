import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/chatbot_provider.dart';
import 'widgets/chat_session_tile.dart';
import 'chatbot_screen.dart';

/// Screen for displaying and managing chat history
class ChatHistoryScreen extends StatefulWidget {
  final String userId;
  final ChatbotProvider chatProvider;

  const ChatHistoryScreen({
    super.key,
    required this.userId,
    required this.chatProvider,
  });

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh sessions on screen load
    widget.chatProvider.loadSessions();
  }

  void _navigateToChat({String? sessionId}) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ChatbotScreen(
          userId: widget.userId,
          initialSessionId: sessionId,
        ),
      ),
    );
  }

  void _confirmDelete(String sessionId, String title) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: Text('Are you sure you want to delete "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await widget.chatProvider.deleteSession(sessionId);
              if (mounted) setState(() {});
            },
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.chatProvider,
      child: Consumer<ChatbotProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Chat History'),
              actions: [
                if (provider.isOfflineMode)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Retry connection',
                    onPressed: provider.retryConnection,
                  ),
              ],
            ),
            body: _buildBody(provider),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _navigateToChat(),
              tooltip: 'New Chat',
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(ChatbotProvider provider) {
    if (provider.isLoadingSessions) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (provider.hasError && provider.sessions.isEmpty) {
      return _buildErrorState(provider);
    }

    if (provider.sessions.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Offline banner
        if (provider.isOfflineMode) _buildOfflineBanner(provider),

        // Sessions list
        Expanded(
          child: RefreshIndicator(
            onRefresh: provider.loadSessions,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: provider.sessions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final session = provider.sessions[index];
                final isSelected = session.sessionId == provider.currentSessionId;

                return ChatSessionTile(
                  session: session,
                  isSelected: isSelected,
                  onTap: () => _navigateToChat(sessionId: session.sessionId),
                  onDelete: () => _confirmDelete(session.sessionId, session.title),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOfflineBanner(ChatbotProvider provider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: colorScheme.errorContainer.withOpacity(0.3),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off,
            color: colorScheme.error,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing cached chats. Some data may be outdated.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 40,
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No chat history yet',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a new conversation with the assistant',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _navigateToChat(),
            icon: const Icon(Icons.add),
            label: const Text('New Chat'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ChatbotProvider provider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Unable to load chat history',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.error ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: provider.loadSessions,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

