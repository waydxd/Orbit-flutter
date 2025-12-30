import 'package:flutter/material.dart';
import '../../../data/models/chat_session.dart';

/// Widget for displaying a chat session in a list
class ChatSessionTile extends StatelessWidget {
  final ChatSession session;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isSelected;

  const ChatSessionTile({
    super.key,
    required this.session,
    required this.onTap,
    required this.onDelete,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      onTap: onTap,
      selected: isSelected,
      selectedTileColor: colorScheme.primary.withOpacity(0.1),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: isSelected
            ? colorScheme.primary.withOpacity(0.3)
            : colorScheme.primary.withOpacity(0.1),
        child: Icon(
          Icons.chat_bubble_outline,
          color: colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        session.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        _buildSubtitle(),
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      trailing: IconButton(
        icon: Icon(
          Icons.delete_outline,
          size: 20,
          color: colorScheme.onSurface.withOpacity(0.5),
        ),
        onPressed: onDelete,
        tooltip: 'Delete chat',
      ),
    );
  }

  String _buildSubtitle() {
    final messageText = session.messageCount == 1
        ? '1 message'
        : '${session.messageCount} messages';
    final dateText = _formatDate(session.updatedAt);
    return '$messageText • $dateText';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) {
      return 'Today';
    } else if (dateDay == yesterday) {
      return 'Yesterday';
    } else {
      final diff = now.difference(date);
      if (diff.inDays < 7) {
        return '${diff.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    }
  }
}

