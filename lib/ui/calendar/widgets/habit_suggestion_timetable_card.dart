import 'package:flutter/material.dart';
import '../../../data/models/habit_suggestion.dart';

/// A compact card rendered inline in the timetable for a habit suggestion.
/// Uses a dashed border and distinct colour to differentiate from regular events.
class HabitSuggestionTimetableCard extends StatelessWidget {
  final HabitSuggestion suggestion;
  final void Function(int years, int weeks) onAccept;
  final VoidCallback onDismiss;
  final bool isProcessing;

  const HabitSuggestionTimetableCard({
    required this.suggestion,
    required this.onAccept,
    required this.onDismiss,
    super.key,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: Colors.amber.shade700,
        strokeWidth: 2.0,
        dashWidth: 6.0,
        dashSpace: 4.0,
        radius: 16.0,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.amber.shade50.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber.shade700, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    suggestion.title,
                    style: TextStyle(
                      color: Colors.amber.shade900,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            // Subtitle / message
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  suggestion.message,
                  style: TextStyle(
                    color: Colors.amber.shade800,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ActionChip(
                  label: 'Confirm',
                  icon: isProcessing ? null : Icons.check,
                  color: Colors.green.shade700,
                  filled: true,
                  isLoading: isProcessing,
                  onTap: isProcessing
                      ? null
                      : () {
                          _showRecurrenceDialog(context);
                        },
                ),
                const SizedBox(width: 8),
                _ActionChip(
                  label: 'Cancel',
                  icon: Icons.close,
                  color: Colors.grey.shade600,
                  onTap: isProcessing ? null : onDismiss,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRecurrenceDialog(BuildContext context) {
    int years = 0;
    int weeks = 0;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Recurring Event Duration'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('How long do you want to repeat this event?'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: years,
                          decoration: const InputDecoration(labelText: 'Years'),
                          items: List.generate(11, (index) => index)
                              .map((e) => DropdownMenuItem(
                                    value: e,
                                    child: Text('$e'),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => years = val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: weeks,
                          decoration: const InputDecoration(labelText: 'Weeks'),
                          items: List.generate(52, (index) => index)
                              .map((e) => DropdownMenuItem(
                                    value: e,
                                    child: Text('$e'),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => weeks = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onAccept(years, weeks);
                  },
                  child: const Text('OK'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final bool filled;
  final bool isLoading;
  final VoidCallback? onTap;

  const _ActionChip({
    required this.label,
    required this.color,
    this.icon,
    this.filled = false,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? color : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            border: filled ? null : Border.all(color: color, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: filled ? Colors.white : color,
                  ),
                )
              else if (icon != null)
                Icon(icon, size: 14, color: filled ? Colors.white : color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: filled ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints a dashed rounded-rectangle border around the widget.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromLTRBR(
      0,
      0,
      size.width,
      size.height,
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final end = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(
              distance, end.clamp(0.0, metric.length).toDouble()),
          paint,
        );
        distance = end + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      dashWidth != oldDelegate.dashWidth ||
      dashSpace != oldDelegate.dashSpace ||
      radius != oldDelegate.radius;
}
