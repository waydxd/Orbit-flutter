import 'package:flutter/material.dart';

import '../themes/hashtag_palette.dart';

/// Small hashtag pill for dense lists (e.g. task row).
class HashtagChipCompact extends StatelessWidget {
  const HashtagChipCompact({required this.tag, super.key});

  final String tag;

  @override
  Widget build(BuildContext context) {
    final accent = hashtagDreamColor(tag);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: hashtagSoftFillAlpha),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '#${stripLeadingHashtagForDisplay(tag)}',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: accent,
        ),
      ),
    );
  }
}

/// Selected tag on create/edit with removable close control.
class HashtagChipFilled extends StatelessWidget {
  const HashtagChipFilled({
    required this.tag,
    required this.onRemove,
    super.key,
  });

  final String tag;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final accent = hashtagDreamColor(tag);
    final onAccent = onHashtagAccentColor(accent);
    final onMuted = onHashtagAccentMutedColor(accent);
    final label = stripLeadingHashtagForDisplay(tag);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#$label',
            style: TextStyle(
              fontSize: 12,
              color: onAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 14,
              color: onMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// AI suggestion row with confidence bar, tinted by that hashtag’s dream color.
class HashtagChipSuggestion extends StatelessWidget {
  const HashtagChipSuggestion({
    required this.tag,
    required this.displayLabel,
    required this.confidence,
    required this.onTap,
    super.key,
  });

  /// Raw tag from API (used for color mapping).
  final String tag;

  /// Already formatted for display (may include `#`).
  final String displayLabel;

  final double confidence;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = hashtagDreamColor(tag);
    final conf = confidence.clamp(0.0, 1.0);
    final pct = (confidence * 100).clamp(0.0, 100.0).toStringAsFixed(0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: hashtagSoftFillAlpha),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accent.withValues(alpha: hashtagSuggestionBorderAlpha),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    displayLabel,
                    style: TextStyle(
                      fontSize: 14,
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '$pct%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.add_circle_outline,
                  size: 18,
                  color: accent.withValues(alpha: 0.75),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: conf,
                minHeight: 5,
                backgroundColor: accent.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
