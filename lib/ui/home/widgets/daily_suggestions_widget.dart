import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/models/event_model.dart';
import '../../../data/services/suggestion_service.dart';
import '../../../generated/protos/suggestion.pbgrpc.dart';
import '../../core/themes/app_colors.dart';
import '../../calendar/view_model/calendar_view_model.dart';
import '../../auth/view_model/auth_view_model.dart';

class DailySuggestionsWidget extends StatefulWidget {
  const DailySuggestionsWidget({super.key});

  @override
  State<DailySuggestionsWidget> createState() => _DailySuggestionsWidgetState();
}

class _DailySuggestionsWidgetState extends State<DailySuggestionsWidget> {
  // Store the last known future and events list to prevent flickering
  Future<List<Suggestion>>? _suggestionsFuture;
  List<EventModel>? _lastEvents;
  int? _lastEventsHash;
  List<Suggestion>? _cachedSuggestions;
  bool _isRegenerating = false;

  int _computeHash(List<EventModel> events) {
    if (events.isEmpty) return 0;
    return events
        .map((e) => e.updatedAt.millisecondsSinceEpoch)
        .reduce((a, b) => a ^ b);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final viewModel = Provider.of<CalendarViewModel>(context);
    final currentHash = _computeHash(viewModel.events);
    // Only re-fetch if events list has changed (by hash or first time)
    if (_lastEventsHash == null || _lastEventsHash != currentHash) {
      _lastEvents = List.from(viewModel.events);
      _lastEventsHash = currentHash;
      _suggestionsFuture = _fetchSuggestions(viewModel.events)
        ..then((suggestions) {
          if (mounted) setState(() => _cachedSuggestions = suggestions);
        });
    }
  }

  void _regenerate() {
    if (_lastEvents == null) return;
    setState(() {
      _isRegenerating = true;
      _suggestionsFuture =
          _fetchSuggestions(_lastEvents!, forceRegenerate: true)
              .then((suggestions) {
        if (mounted) {
          setState(() {
            _cachedSuggestions = suggestions;
            _isRegenerating = false;
          });
        }
        return suggestions;
      }).catchError((e) {
        if (mounted) {
          setState(() => _isRegenerating = false);
        }
        return <Suggestion>[];
      });
    });
  }

  Future<List<Suggestion>> _fetchSuggestions(List<EventModel> allEvents,
      {bool forceRegenerate = false}) async {
    final user = Provider.of<AuthViewModel>(context, listen: false).currentUser;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateStr = DateFormat('yyyy-MM-dd').format(today);

    final todayEvents = allEvents.where((e) {
      final startLocal = e.startTime.toLocal();
      return startLocal.year == today.year &&
          startLocal.month == today.month &&
          startLocal.day == today.day;
    }).toList();

    final service = OrbitSuggestionService();

    if (todayEvents.isNotEmpty) {
      final List<List<Suggestion>> perEventResults = await Future.wait(
        todayEvents.map((evt) => service
            .getSuggestionsForEvent(evt,
                userId: user?.id ?? '', forceRegenerate: forceRegenerate)
            .catchError((_) => <Suggestion>[])),
      );
      final List<Suggestion> allEventSuggestions =
          perEventResults.expand((sugs) => sugs).toList();

      // Deduplicate event suggestions based on title
      final uniqueEventSuggestions = <Suggestion>[];
      final seenTitles = <String>{};
      for (var s in allEventSuggestions) {
        if (!seenTitles.contains(s.title)) {
          seenTitles.add(s.title);
          uniqueEventSuggestions.add(s);
        }
      }

      final results = uniqueEventSuggestions.take(3).toList();

      // Fetch daily suggestions and append 1
      final dailySugs = await service.getDailySuggestions(
          dateStr, user, allEvents,
          forceRegenerate: forceRegenerate);
      if (dailySugs.isNotEmpty) {
        results.add(dailySugs.first);
      }

      return results;
    } else {
      return await service.getDailySuggestions(dateStr, user, allEvents,
          forceRegenerate: forceRegenerate);
    }
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

  Widget _buildEmptyCard(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEAFFFE),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF50C8AA),
              size: 24,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Suggestion>>(
      future: _suggestionsFuture,
      builder: (context, snapshot) {
        Widget content;

        final activeSuggestions = snapshot.data ?? _cachedSuggestions;

        if (snapshot.connectionState == ConnectionState.waiting &&
            activeSuggestions == null) {
          content = _buildEmptyCard(
            'Generating Suggestions...',
            'Please wait a moment while AI builds your tips.',
            Icons.auto_awesome,
          );
        } else if (activeSuggestions == null || activeSuggestions.isEmpty) {
          content = _buildEmptyCard(
            'No suggestions available',
            'We don\'t have any tips for today yet.',
            Icons.auto_awesome,
          );
        } else {
          // Display whatever the length is, up to 4 (since we may return 3+1 now)
          final suggestions = activeSuggestions;
          content = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: suggestions
                .map((suggestion) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAFFFE),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              _getIconForType(suggestion.type),
                              color: const Color(0xFF50C8AA),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  suggestion.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  suggestion.description,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            content,
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _isRegenerating ? null : _regenerate,
                icon: _isRegenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh, size: 20),
                label: Text(_isRegenerating
                    ? 'Regenerating...'
                    : 'Regenerate Suggestions'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
