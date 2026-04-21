import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../../../data/models/event_model.dart';
import '../../../data/services/suggestion_service.dart';
import '../../../generated/protos/suggestion.pbgrpc.dart';
import '../../core/themes/app_colors.dart';
import '../../auth/view_model/auth_view_model.dart';

class EventSuggestionsWidget extends StatefulWidget {
  final EventModel event;

  const EventSuggestionsWidget({required this.event, super.key});

  @override
  State<EventSuggestionsWidget> createState() => _EventSuggestionsWidgetState();
}

class _EventSuggestionsWidgetState extends State<EventSuggestionsWidget> {
  Future<List<Suggestion>>? _suggestionsFuture;
  List<Suggestion>? _cachedSuggestions;
  bool _isRegenerating = false;

  @override
  void initState() {
    super.initState();
    _fetchSuggestions();
  }

  void _fetchSuggestions({bool forceRegenerate = false}) {
    final user = Provider.of<AuthViewModel>(context, listen: false).currentUser;
    final userId = user?.id ?? '';

    final inFlight =
        OrbitSuggestionService().hasInFlightEventRequest(widget.event.id);

    if (forceRegenerate || inFlight) {
      setState(() {
        _isRegenerating = true;
      });
    }

    _suggestionsFuture = OrbitSuggestionService().getSuggestionsForEvent(
        widget.event,
        userId: userId,
        forceRegenerate: forceRegenerate)
      ..then((suggestions) {
        if (mounted) {
          setState(() {
            _cachedSuggestions = suggestions;
            _isRegenerating = false;
          });
        }
      }).catchError((e) {
        if (mounted) {
          setState(() {
            _isRegenerating = false;
          });
        }
      });
  }

  IconData _getIconForType(SuggestionType type) {
    switch (type) {
      case SuggestionType.SUGGESTION_TYPE_TRANSPORTATION:
        return Icons.directions_transit;
      case SuggestionType.SUGGESTION_TYPE_ATTIRE:
        return Icons.checkroom;
      case SuggestionType.SUGGESTION_TYPE_PREPARATION:
        return Icons.inventory_2;
      default:
        return Icons.lightbulb_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Suggestion>>(
      future: _suggestionsFuture,
      builder: (context, snapshot) {
        // Wait to show until data exists, but fall back to cache securely.
        final activeSuggestions = snapshot.data ?? _cachedSuggestions;

        final suggestions = activeSuggestions?.take(3).toList() ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'AI SUGGESTIONS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                if (_isRegenerating)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: () => _fetchSuggestions(forceRegenerate: true),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: AppColors.primary,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (activeSuggestions == null &&
                snapshot.connectionState == ConnectionState.waiting)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Generating AI Suggestions...',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.grey400,
                    ),
                  ),
                ),
              )
            else if (suggestions.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 12.0),
                child: Text(
                  'No suggestions available. Try regenerating!',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.grey400,
                  ),
                ),
              )
            else
              ...suggestions.map((s) => _buildSuggestionCard(s)),
          ],
        );
      },
    );
  }

  Widget _buildSuggestionCard(Suggestion suggestion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_getIconForType(suggestion.type), color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  suggestion.description,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
