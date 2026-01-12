import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../habit_tracking_view_model.dart';
import '../habit_suggestions_screen.dart';

/// A badge widget that shows the number of pending habit suggestions
///
/// Use this widget in your app bar or navigation to show users
/// when they have habit suggestions available.
///
/// Example usage:
/// ```dart
/// HabitSuggestionsBadge(
///   userId: currentUser.id,
///   child: Icon(Icons.lightbulb_outline),
/// )
/// ```
class HabitSuggestionsBadge extends StatefulWidget {
  final String userId;
  final Widget child;
  final bool navigateOnTap;

  const HabitSuggestionsBadge({
    super.key,
    required this.userId,
    required this.child,
    this.navigateOnTap = true,
  });

  @override
  State<HabitSuggestionsBadge> createState() => _HabitSuggestionsBadgeState();
}

class _HabitSuggestionsBadgeState extends State<HabitSuggestionsBadge> {
  late final HabitTrackingViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = HabitTrackingViewModel(userId: widget.userId);
    _viewModel.loadSuggestions();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _navigateToSuggestions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HabitSuggestionsScreen(userId: widget.userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<HabitTrackingViewModel>(
        builder: (context, viewModel, child) {
          final count = viewModel.suggestionsCount;
          final showBadge = count > 0 && !viewModel.isLoading;

          Widget badgeChild = Badge(
            isLabelVisible: showBadge,
            label: Text(
              count > 99 ? '99+' : count.toString(),
              style: const TextStyle(fontSize: 10),
            ),
            child: widget.child,
          );

          if (widget.navigateOnTap) {
            return GestureDetector(
              onTap: _navigateToSuggestions,
              child: badgeChild,
            );
          }

          return badgeChild;
        },
      ),
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
/// HabitSuggestionsIconButton(userId: currentUser.id)
/// ```
class HabitSuggestionsIconButton extends StatelessWidget {
  final String userId;
  final Color? iconColor;
  final double? iconSize;
  final String? tooltip;

  const HabitSuggestionsIconButton({
    super.key,
    required this.userId,
    this.iconColor,
    this.iconSize,
    this.tooltip = 'Habit Suggestions',
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: HabitSuggestionsBadge(
        userId: userId,
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
            builder: (context) => HabitSuggestionsScreen(userId: userId),
          ),
        );
      },
    );
  }
}

