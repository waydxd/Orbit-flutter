import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../calendar/view_model/calendar_view_model.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../widgets/habit_suggestion_card.dart';
import '../../../utils/constants.dart';

/// Page displaying habit suggestions and allowing accept/dismiss actions
class HabitSuggestionsPage extends StatefulWidget {
  const HabitSuggestionsPage({super.key});

  @override
  State<HabitSuggestionsPage> createState() => _HabitSuggestionsPageState();
}

class _HabitSuggestionsPageState extends State<HabitSuggestionsPage> {
  String? _processingSuggestionId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Consumer<CalendarViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.habitSuggestions.isEmpty) {
            return _buildLoadingState();
          }

          if (viewModel.error != null && viewModel.habitSuggestions.isEmpty) {
            return _buildErrorState(context, viewModel);
          }

          if (viewModel.habitSuggestions.isEmpty) {
            return _buildEmptyState();
          }

          return _buildSuggestionsList(viewModel);
        },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Habit Suggestions'),
      actions: [
        Consumer<CalendarViewModel>(
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
              onPressed: viewModel.isLoading
                  ? null
                  : () {
                      final userId =
                          context.read<AuthViewModel>().currentUser?.id;
                      if (userId != null) {
                        viewModel.fetchAll(userId: userId);
                      }
                    },
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

  Widget _buildErrorState(
      BuildContext context, CalendarViewModel viewModel) {
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
              onPressed: () {
                final userId =
                    context.read<AuthViewModel>().currentUser?.id;
                if (userId != null) {
                  viewModel.fetchAll(userId: userId);
                }
              },
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

  Widget _buildSuggestionsList(CalendarViewModel viewModel) {
    return RefreshIndicator(
      onRefresh: () async {
        final userId = context.read<AuthViewModel>().currentUser?.id;
        if (userId != null) {
          await viewModel.fetchAll(userId: userId);
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: Constants.spacingM),
        itemCount: viewModel.habitSuggestions.length,
        itemBuilder: (context, index) {
          final suggestion = viewModel.habitSuggestions[index];
          return HabitSuggestionCard(
            suggestion: suggestion,
            isLoading: _processingSuggestionId == suggestion.id,
            onAccept: () => _handleAccept(viewModel, suggestion.id),
            onDismiss: () => _handleDismiss(viewModel, suggestion.id),
          );
        },
      ),
    );
  }

  Future<void> _handleAccept(
      CalendarViewModel viewModel, String suggestionId) async {
    setState(() => _processingSuggestionId = suggestionId);

    try {
      final userId = context.read<AuthViewModel>().currentUser?.id;
      final response = await viewModel.acceptHabitSuggestion(
        suggestionId,
        userId: userId,
      );

      if (mounted) {
        if (response != null && response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
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
        setState(() => _processingSuggestionId = null);
      }
    }
  }

  Future<void> _handleDismiss(
      CalendarViewModel viewModel, String suggestionId) async {
    setState(() => _processingSuggestionId = suggestionId);

    try {
      final success = await viewModel.dismissHabitSuggestion(suggestionId);

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
        setState(() => _processingSuggestionId = null);
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
