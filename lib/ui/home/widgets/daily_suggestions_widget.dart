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
  Future<List<Suggestion>> _getSuggestions(BuildContext context) async {
    final viewModel = Provider.of<CalendarViewModel>(context, listen: false);
    final user = Provider.of<AuthViewModel>(context, listen: false).currentUser;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final allEvents = viewModel.events;
    final todayEvents = allEvents.where((e) {
      return e.startTime.year == today.year &&
          e.startTime.month == today.month &&
          e.startTime.day == today.day;
    }).toList();

    if (todayEvents.isNotEmpty) {
      List<Suggestion> allEventSuggestions = [];
      final userId = user?.id ?? '';
      for (final event in todayEvents) {
        final suggestions = await OrbitSuggestionService().getSuggestionsForEvent(event, userId);
        allEventSuggestions.addAll(suggestions);
      }
      return allEventSuggestions;
    } else {
      final dateStr = DateFormat('yyyy-MM-dd').format(today);
      final recentEvents = allEvents.where((e) => e.startTime.isBefore(now)).take(10).toList();
      return await OrbitSuggestionService().getDailySuggestions(dateStr, user, recentEvents);
    }
  }

  IconData _getIconForType(SuggestionType type) {
    switch (type) {
      case SuggestionType.TRANSPORTATION:
        return Icons.directions_transit;
      case SuggestionType.ATTIRE:
        return Icons.checkroom;
      case SuggestionType.PREPARATION:
        return Icons.inventory_2;
      default:
        return Icons.lightbulb_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Suggestion>>(
      future: _getSuggestions(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ));
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
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
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Color(0xFF50C8AA),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 15),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No suggestions available',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'We don\'t have any tips for today yet.',
                        style: TextStyle(
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

        final suggestions = snapshot.data!;

        return Column(
          children: suggestions.map((suggestion) => Container(
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
          )).toList(),
        );
      },
    );
  }
}
