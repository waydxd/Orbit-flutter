import 'package:flutter/material.dart';
import '../../../data/providers/chat_agent_provider.dart';

/// Pending action card widget for Agent mode
class PendingActionCard extends StatelessWidget {
  final PendingActionInfo action;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final VoidCallback onDismiss;
  final bool isConfirming;
  final bool isCancelling;

  const PendingActionCard({
    required this.action, required this.onConfirm, required this.onCancel, required this.onDismiss, super.key,
    this.isConfirming = false,
    this.isCancelling = false,
  });

  bool get isProcessing => isConfirming || isCancelling;

  @override
  Widget build(BuildContext context) {
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
                  onPressed: onDismiss,
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
                  onPressed: isProcessing ? null : onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6B7280),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isCancelling
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
                  onPressed: isProcessing ? null : onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: isConfirming
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
      case 'create_task':
        return Icons.task_outlined;
      case 'update_task':
        return Icons.edit_note_outlined;
      case 'delete_task':
        return Icons.delete_sweep_outlined;
      default:
        return Icons.event_outlined;
    }
  }

  String _getActionDisplayName(String actionType) {
    switch (actionType.toLowerCase()) {
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
}

