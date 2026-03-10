import 'package:flutter/material.dart';
import '../../../data/models/chat_session.dart';

/// Conversation history drawer widget
class ConversationDrawer extends StatelessWidget {
  final List<ChatSession> conversations;
  final String? currentConversationId;
  final VoidCallback onNewChat;
  final Function(String) onSelectConversation;
  final Function(ChatSession) onRenameConversation;
  final Function(String) onDeleteConversation;

  const ConversationDrawer({
    required this.conversations, required this.currentConversationId, required this.onNewChat, required this.onSelectConversation, required this.onRenameConversation, required this.onDeleteConversation, super.key,
  });

  @override
  Widget build(BuildContext context) {
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
                      onNewChat();
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
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: conversations.length,
                      itemBuilder: (context, index) {
                        final conversation = conversations[index];
                        final isSelected = currentConversationId == conversation.sessionId;
                        return ConversationTile(
                          conversation: conversation,
                          isSelected: isSelected,
                          onTap: () {
                            onSelectConversation(conversation.sessionId);
                            Navigator.of(context).pop();
                          },
                          onRename: () => onRenameConversation(conversation),
                          onDelete: () => onDeleteConversation(conversation.sessionId),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
}

/// Individual conversation tile in the drawer
class ConversationTile extends StatelessWidget {
  final ChatSession conversation;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const ConversationTile({
    required this.conversation, required this.isSelected, required this.onTap, required this.onRename, required this.onDelete, super.key,
  });

  @override
  Widget build(BuildContext context) {
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
            onDelete();
          } else if (value == 'rename') {
            onRename();
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
      onTap: onTap,
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
}

/// Dialog for renaming a conversation
class RenameConversationDialog extends StatelessWidget {
  final ChatSession conversation;
  final Function(String, String) onRename;

  const RenameConversationDialog({
    required this.conversation, required this.onRename, super.key,
  });

  @override
  Widget build(BuildContext context) {
    final titleController = TextEditingController(text: conversation.title);

    return AlertDialog(
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
            onRename(conversation.sessionId, value.trim());
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
              onRename(conversation.sessionId, newTitle);
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
    );
  }
}

/// Dialog for confirming conversation deletion
class DeleteConversationDialog extends StatelessWidget {
  final String conversationId;
  final VoidCallback onDelete;

  const DeleteConversationDialog({
    required this.conversationId, required this.onDelete, super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
            onDelete();
            Navigator.of(context).pop();
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}

