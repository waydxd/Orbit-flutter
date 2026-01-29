import 'package:flutter/material.dart';
import '../../../data/models/event_model.dart';
import '../../../data/models/suggestion_model.dart';
import '../../core/themes/app_colors.dart';
import 'suggestion_card.dart';

/// Widget displaying AI-generated suggestions for an event
class AISuggestionsSection extends StatelessWidget {
  final EventModel event;
  final SuggestionResponse suggestions;
  final bool isLoading;
  final String? error;
  final VoidCallback onRefresh;

  const AISuggestionsSection({
    super.key,
    required this.event,
    required this.suggestions,
    required this.isLoading,
    this.error,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          if (isLoading) _buildLoadingState(),
          if (error != null && !isLoading) _buildErrorState(),
          if (!isLoading && error == null) _buildContent(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Suggestions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Powered by Azure OpenAI',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (suggestions.suggestions.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: onRefresh,
            tooltip: 'Refresh suggestions',
          ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          // Animated AI processing indicator
          _buildAnimatedAIOrb(),
          const SizedBox(height: 24),
          const Text(
            'Analyzing your event...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Getting weather, nearby places, and more',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Loading chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildLoadingChip('Weather', Icons.cloud_outlined),
              _buildLoadingChip('Transport', Icons.directions_car_outlined),
              _buildLoadingChip('Places', Icons.place_outlined),
              _buildLoadingChip('Dress Code', Icons.checkroom_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedAIOrb() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow
            for (int i = 1; i <= 3; i++)
              Container(
                width: 80.0 + (i * 20) * value,
                height: 80.0 + (i * 20) * value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6366F1).withValues(alpha: 0.15 / i),
                      const Color(0xFF6366F1).withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            // Inner orb
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE0E7FF),
                    Color(0xFFC7D2FE),
                    Color(0xFF818CF8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            error ?? 'Failed to load suggestions',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (suggestions.suggestions.isEmpty) {
      return _buildEmptyState();
    }

    // Group suggestions by type
    final groupedSuggestions = _groupSuggestionsByType();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary if available
        if (suggestions.summary != null && suggestions.summary!.isNotEmpty)
          _buildSummaryCard(),

        // Suggestion cards grouped by type
        ...groupedSuggestions.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildTypeHeader(entry.key),
              const SizedBox(height: 12),
              ...entry.value.map((suggestion) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SuggestionCard(suggestion: suggestion),
                  )),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 48,
            color: AppColors.grey300,
          ),
          const SizedBox(height: 16),
          const Text(
            'No suggestions available',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the button below to get AI-powered suggestions for this event',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6366F1).withValues(alpha: 0.1),
            const Color(0xFF818CF8).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.summarize_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              SizedBox(width: 8),
              Text(
                'Summary',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            suggestions.summary!,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeHeader(SuggestionType type) {
    final icon = _getIconForType(type);
    final color = _getColorForType(type);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          type.displayName,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Map<SuggestionType, List<SuggestionModel>> _groupSuggestionsByType() {
    final grouped = <SuggestionType, List<SuggestionModel>>{};
    for (final suggestion in suggestions.suggestions) {
      final type = SuggestionType.fromString(suggestion.type);
      grouped.putIfAbsent(type, () => []).add(suggestion);
    }
    return grouped;
  }

  IconData _getIconForType(SuggestionType type) {
    switch (type) {
      case SuggestionType.weather:
        return Icons.cloud_outlined;
      case SuggestionType.transport:
        return Icons.directions_car_outlined;
      case SuggestionType.dressCode:
        return Icons.checkroom_outlined;
      case SuggestionType.nearbyPlaces:
        return Icons.place_outlined;
      case SuggestionType.nearbyRestaurants:
        return Icons.restaurant_outlined;
      case SuggestionType.schedule:
        return Icons.schedule_outlined;
      case SuggestionType.general:
        return Icons.lightbulb_outline;
    }
  }

  Color _getColorForType(SuggestionType type) {
    switch (type) {
      case SuggestionType.weather:
        return const Color(0xFF3B82F6);
      case SuggestionType.transport:
        return const Color(0xFF10B981);
      case SuggestionType.dressCode:
        return const Color(0xFFF59E0B);
      case SuggestionType.nearbyPlaces:
        return const Color(0xFFEF4444);
      case SuggestionType.nearbyRestaurants:
        return const Color(0xFFFF6B6B);
      case SuggestionType.schedule:
        return const Color(0xFF8B5CF6);
      case SuggestionType.general:
        return AppColors.primary;
    }
  }
}

