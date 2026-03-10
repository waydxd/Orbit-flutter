import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../calendar/view_model/calendar_view_model.dart';
import '../view/habit_suggestions_page.dart';

/// A badge widget that shows the number of pending habit suggestions
///
/// Uses the shared [CalendarViewModel] from the Provider tree so that the
/// badge count stays in sync with the calendar timetable.
///
/// Example usage:
/// ```dart
/// HabitSuggestionsBadge(
///   child: Icon(Icons.lightbulb_outline),
/// )
/// ```
class HabitSuggestionsBadge extends StatelessWidget {
  final Widget child;
  final bool navigateOnTap;

  const HabitSuggestionsBadge({
    required this.child,
    super.key,
    this.navigateOnTap = true,
  });

  void _navigateToSuggestions(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HabitSuggestionsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarViewModel>(
      builder: (context, viewModel, _) {
        final count = viewModel.habitSuggestionsCount;
        final showBadge = count > 0 && !viewModel.isLoading;

        final Widget badgeChild = Badge(
          isLabelVisible: showBadge,
          label: Text(
            count > 99 ? '99+' : count.toString(),
            style: const TextStyle(fontSize: 10),
          ),
          child: child,
        );

        if (navigateOnTap) {
          return GestureDetector(
            onTap: () => _navigateToSuggestions(context),
            child: badgeChild,
          );
        }

        return badgeChild;
      },
    );
  }
}

/// A simple icon button with habit suggestions badge
///
/// Convenience widget that wraps [HabitSuggestionsBadge] with a lightbulb icon
/// and handles navigation to the suggestions screen.
///
/// Example usage:
/// ```dart
/// // In your app bar actions:
/// HabitSuggestionsIconButton()
/// ```
class HabitSuggestionsIconButton extends StatelessWidget {
  final Color? iconColor;
  final double? iconSize;
  final String? tooltip;

  const HabitSuggestionsIconButton({
    super.key,
    this.iconColor,
    this.iconSize,
    this.tooltip = 'Habit Suggestions',
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: HabitSuggestionsBadge(
        navigateOnTap: false,
        child: Icon(
          Icons.lightbulb_outline,
          color: iconColor,
          size: iconSize,
        ),
      ),
      tooltip: tooltip,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const HabitSuggestionsPage(),
          ),
        );
      },
    );
  }
}

