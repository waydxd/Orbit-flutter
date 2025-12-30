import 'package:flutter/material.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/models/chat_action.dart';

/// Widget for displaying a single chat message bubble
class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final Function(ChatAction)? onActionTap;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.onActionTap,
  });

  bool get isUser => message.role == MessageRole.user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.isStreaming && message.content.isEmpty)
                    _buildTypingIndicator(colorScheme)
                  else
                    SelectableText(
                      message.content,
                      style: TextStyle(
                        color: isUser
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  if (message.isStreaming && message.content.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isUser
                              ? colorScheme.onPrimary.withOpacity(0.7)
                              : colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (message.actions != null && message.actions!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: message.actions!.map((action) {
                    return ActionChip(
                      label: Text(
                        action.label,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      onPressed: () => onActionTap?.call(action),
                      avatar: _getActionIcon(action.actionType, colorScheme),
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      side: BorderSide(
                        color: colorScheme.outline.withOpacity(0.3),
                      ),
                    );
                  }).toList(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Text(
                _formatTime(message.timestamp),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return _TypingDot(
          delay: Duration(milliseconds: index * 200),
          color: colorScheme.onSurface.withOpacity(0.5),
        );
      }),
    );
  }

  Widget? _getActionIcon(ActionType type, ColorScheme colorScheme) {
    IconData iconData;
    switch (type) {
      case ActionType.createEvent:
        iconData = Icons.add_circle_outline;
      case ActionType.modifyEvent:
        iconData = Icons.edit_outlined;
      case ActionType.deleteEvent:
        iconData = Icons.delete_outline;
      case ActionType.showCalendar:
        iconData = Icons.calendar_today;
      case ActionType.setSuggestion:
        iconData = Icons.lightbulb_outline;
      case ActionType.openLink:
        iconData = Icons.open_in_new;
    }
    return Icon(iconData, size: 18, color: colorScheme.primary);
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Animated typing indicator dot
class _TypingDot extends StatefulWidget {
  final Duration delay;
  final Color color;

  const _TypingDot({
    required this.delay,
    required this.color,
  });

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(_animation.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

