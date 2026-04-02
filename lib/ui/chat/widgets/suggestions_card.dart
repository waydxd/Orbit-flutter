import 'package:flutter/material.dart';

/// Suggestion card widget for the welcome page
class SuggestionsCard extends StatelessWidget {
  final Function(String) onSuggestionTap;

  const SuggestionsCard({
    required this.onSuggestionTap,
    super.key,
  });

  static const List<String> defaultSuggestions = [
    'Task creation',
    'Available time',
    'Rearrange schedules',
    'Next event',
  ];

  @override
  Widget build(BuildContext context) {
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
            children: defaultSuggestions.map((label) {
              return SuggestionChip(
                label: label,
                onTap: () => onSuggestionTap(_getPromptForSuggestion(label)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getPromptForSuggestion(String label) {
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
}

/// Individual suggestion chip widget
class SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const SuggestionChip({
    required this.label,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
}
