import 'package:flutter/material.dart';
import '../../../data/providers/chat_agent_provider.dart';

/// Chat mode dropdown widget for switching between Ask and Agent modes
class ChatModeDropdown extends StatelessWidget {
  final ChatMode currentMode;
  final ValueChanged<ChatMode> onModeChanged;

  const ChatModeDropdown({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  bool get isAgentMode => currentMode == ChatMode.agent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      width: 95,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isAgentMode
            ? const Color(0xFF6366F1).withValues(alpha: 0.1)
            : const Color(0xFFF8F9FE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAgentMode
              ? const Color(0xFF6366F1)
              : const Color(0xFFE0E7FF),
          width: 1.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ChatMode>(
          value: currentMode,
          isDense: true,
          isExpanded: false,
          icon: Icon(
            Icons.expand_more,
            color: isAgentMode
                ? const Color(0xFF6366F1)
                : const Color(0xFF5E6272),
            size: 15,
          ),
          borderRadius: BorderRadius.circular(16),
          dropdownColor: Colors.white,
          onChanged: (ChatMode? newValue) {
            if (newValue != null) {
              onModeChanged(newValue);
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

