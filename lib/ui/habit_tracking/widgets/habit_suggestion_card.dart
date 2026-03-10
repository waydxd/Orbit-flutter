import 'package:flutter/material.dart';
import '../../../data/models/habit_suggestion.dart';
import '../../../utils/constants.dart';

/// Card widget displaying a habit suggestion with accept/dismiss actions
class HabitSuggestionCard extends StatelessWidget {
  final HabitSuggestion suggestion;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;
  final bool isLoading;

  const HabitSuggestionCard({
    required this.suggestion,
    required this.onAccept,
    required this.onDismiss,
    super.key,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: Constants.spacingM,
        vertical: Constants.spacingS,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Constants.radiusL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Constants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: Constants.spacingS),
            _buildTitle(context),
            const SizedBox(height: Constants.spacingS),
            _buildInfoSection(context),
            const SizedBox(height: Constants.spacingM),
            _buildPromptText(context),
            const SizedBox(height: Constants.spacingS),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.lightbulb, color: Colors.amber, size: Constants.iconM),
        const SizedBox(width: Constants.spacingS),
        Text(
          'Detected Pattern',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.amber[700],
                fontWeight: FontWeight.bold,
              ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Constants.spacingS,
            vertical: Constants.spacingXS,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(Constants.radiusM),
          ),
          child: Text(
            suggestion.status,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      suggestion.title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Column(
      children: [
        _buildInfoRow(
          context,
          Icons.calendar_today,
          'Every ${suggestion.dayOfWeek}',
        ),
        _buildInfoRow(
          context,
          Icons.access_time,
          '${suggestion.timeOfDay} (${suggestion.durationMinutes} min)',
        ),
        if (suggestion.location != null && suggestion.location!.isNotEmpty)
          _buildInfoRow(
            context,
            Icons.location_on,
            suggestion.location!,
          ),
        if (suggestion.description != null &&
            suggestion.description!.isNotEmpty)
          _buildInfoRow(
            context,
            Icons.description,
            suggestion.description!,
          ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Constants.spacingXS),
      child: Row(
        children: [
          Icon(
            icon,
            size: Constants.iconS,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: Constants.spacingS),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptText(BuildContext context) {
    return Text(
      suggestion.message,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
            fontStyle: FontStyle.italic,
          ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: isLoading ? null : onDismiss,
          child: Text(
            'Dismiss',
            style: TextStyle(color: colorScheme.outline),
          ),
        ),
        const SizedBox(width: Constants.spacingS),
        ElevatedButton.icon(
          onPressed: isLoading ? null : onAccept,
          icon: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check, size: 18),
          label: const Text('Accept'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
        ),
      ],
    );
  }
}

