import 'package:flutter/material.dart';
import '../../../data/models/agent_chat_message.dart';
import 'orbi_avatar.dart';

/// Chat message bubble widget
class ChatMessageBubble extends StatelessWidget {
  final AgentChatMessage message;
  final Widget? actionButtons;

  const ChatMessageBubble({
    required this.message,
    super.key,
    this.actionButtons,
  });

  @override
  Widget build(BuildContext context) {
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
            const SmallOrbiAvatar(),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color:
                        isUser ? const Color(0xFF6366F1) : Colors.transparent,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                    boxShadow: isUser
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
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
                      : _buildMessageContent(isUser),
                ),
                // Action buttons (confirm/cancel for agent mode)
                if (actionButtons != null) actionButtons!,
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildMessageContent(bool isUser) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Agent type label
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
        // Message content
        Text(
          message.content,
          style: TextStyle(
            color: isUser ? Colors.white : const Color(0xFF5E6272),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        // Action summary badge
        if (message.hasAction && message.actionSummary != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _buildActionSummary(),
          ),
      ],
    );
  }

  Widget _buildActionSummary() {
    return Container(
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
}

/// Action status badge for completed actions
class ActionStatusBadge extends StatelessWidget {
  final String status;

  const ActionStatusBadge({
    required this.status,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final isExecuted = normalized == 'executed' || normalized == 'confirmed';
    final isCancelled = normalized == 'cancelled' || normalized == 'canceled';

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isExecuted
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
              isExecuted
                  ? Icons.check_circle_outline
                  : isCancelled
                      ? Icons.cancel_outlined
                      : Icons.timer_off_outlined,
              size: 14,
              color: isExecuted
                  ? const Color(0xFF10B981)
                  : isCancelled
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFFEF4444),
            ),
            const SizedBox(width: 4),
            Text(
              isExecuted
                  ? 'Executed'
                  : isCancelled
                      ? 'Cancelled'
                      : 'Expired',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isExecuted
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
}

/// Action buttons (Confirm/Cancel) for pending actions
class MessageActionButtons extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool isConfirming;
  final bool isCancelling;
  final bool isDisabled;

  const MessageActionButtons({
    required this.onConfirm,
    required this.onCancel,
    super.key,
    this.isConfirming = false,
    this.isCancelling = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Confirm button
          ElevatedButton.icon(
            onPressed: isDisabled ? null : onConfirm,
            icon: isConfirming
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
          const SizedBox(width: 8),
          // Cancel button
          OutlinedButton.icon(
            onPressed: isDisabled ? null : onCancel,
            icon: isCancelling
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
        ],
      ),
    );
  }
}
