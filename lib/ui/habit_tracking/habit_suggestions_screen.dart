import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'habit_tracking_view_model.dart';
import 'widgets/habit_suggestion_card.dart';
import '../../utils/constants.dart';

/// Screen displaying habit suggestions and allowing accept/dismiss actions
class HabitSuggestionsScreen extends StatefulWidget {
  final String userId;

  const HabitSuggestionsScreen({
    super.key,
    required this.userId,
  });

  @override
  State<HabitSuggestionsScreen> createState() => _HabitSuggestionsScreenState();
}

class _HabitSuggestionsScreenState extends State<HabitSuggestionsScreen> {
  late final HabitTrackingViewModel _viewModel;
  int? _processingHabitId;

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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: Consumer<HabitTrackingViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading && viewModel.suggestions.isEmpty) {
              return _buildLoadingState();
            }

            if (viewModel.error != null && viewModel.suggestions.isEmpty) {
              return _buildErrorState(context, viewModel);
            }

            if (viewModel.suggestions.isEmpty) {
              return _buildEmptyState();
            }

            return _buildSuggestionsList(viewModel);
          },
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Habit Suggestions'),
      actions: [
        Consumer<HabitTrackingViewModel>(
          builder: (context, viewModel, child) {
            return IconButton(
              icon: viewModel.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: viewModel.isLoading ? null : () => viewModel.loadSuggestions(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: Constants.spacingM),
          Text('Loading suggestions...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, HabitTrackingViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Constants.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: Constants.spacingM),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: Constants.spacingS),
            Text(
              viewModel.error ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Constants.spacingL),
            ElevatedButton.icon(
              onPressed: () => viewModel.loadSuggestions(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Constants.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: Constants.spacingM),
            Text(
              'No habit suggestions yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: Constants.spacingS),
            Text(
              'Keep using the app and patterns will be detected!\n\n'
              'Events that occur 3 or more times with the same\n'
              'title, time, and day will appear here as suggestions.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsList(HabitTrackingViewModel viewModel) {
    return RefreshIndicator(
      onRefresh: () => viewModel.loadSuggestions(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: Constants.spacingM),
        itemCount: viewModel.suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = viewModel.suggestions[index];
          return HabitSuggestionCard(
            suggestion: suggestion,
            isLoading: _processingHabitId == suggestion.habitId,
            onAccept: () => _handleAccept(viewModel, suggestion.habitId),
            onDismiss: () => _handleDismiss(viewModel, suggestion.habitId),
          );
        },
      ),
    );
  }

  Future<void> _handleAccept(HabitTrackingViewModel viewModel, int habitId) async {
    setState(() => _processingHabitId = habitId);

    try {
      final eventsCreated = await viewModel.acceptSuggestion(habitId);

      if (mounted) {
        if (eventsCreated != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Created $eventsCreated recurring events for 5 years!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (viewModel.error != null) {
          _showErrorSnackBar(viewModel.error!);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _processingHabitId = null);
      }
    }
  }

  Future<void> _handleDismiss(HabitTrackingViewModel viewModel, int habitId) async {
    setState(() => _processingHabitId = habitId);

    try {
      final success = await viewModel.dismissSuggestion(habitId);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Suggestion dismissed'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (viewModel.error != null) {
          _showErrorSnackBar(viewModel.error!);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _processingHabitId = null);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $message'),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

