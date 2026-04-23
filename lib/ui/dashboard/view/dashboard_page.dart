import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/daily_heatmap_record.dart';
import '../widgets/heatmap_calendar_widget.dart';
import '../widgets/location_card_widget.dart';
import '../../calendar/view_model/calendar_view_model.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../../settings/view/settings_page.dart';
import '../../../data/models/event_model.dart';

import '../../core/themes/app_colors.dart';
import '../../core/themes/hashtag_palette.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DateTime _focusedDate = DateTime.now();
  String? _initialFetchedUserId;
  List<DailyHeatmapRecord> _heatmapRecords = const [];
  int _heatmapRequestId = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fetchHeatmapMonth(_focusedDate);
    });
  }

  String _inferCategory(EventModel event) {
    final title = event.title.toLowerCase();
    final desc = event.description.toLowerCase();
    final combined = '$title $desc';

    if (combined.contains('work') ||
        combined.contains('meeting') ||
        combined.contains('sync') ||
        combined.contains('office') ||
        combined.contains('interview')) {
      return 'Work';
    }
    if (combined.contains('study') ||
        combined.contains('class') ||
        combined.contains('lecture') ||
        combined.contains('exam') ||
        combined.contains('assignment')) {
      return 'Study';
    }
    if (combined.contains('gym') ||
        combined.contains('exercise') ||
        combined.contains('workout') ||
        combined.contains('run') ||
        combined.contains('sport')) {
      return 'Exercise';
    }
    if (combined.contains('personal') ||
        combined.contains('dinner') ||
        combined.contains('lunch') ||
        combined.contains('friend') ||
        combined.contains('family')) {
      return 'Personal';
    }
    return 'Other';
  }

  /// Heatmap bucket: first event hashtag (display form) when present, else inferred category.
  String _heatmapCategoryForEvent(EventModel event) {
    if (event.hashtags.isNotEmpty) {
      return stripLeadingHashtagForDisplay(event.hashtags.first);
    }
    return _inferCategory(event);
  }

  List<DailyHeatmapRecord> _generateRecordsFromEvents(List<EventModel> events) {
    final Map<DateTime, Map<String, int>> dayCategoryDurations = {};

    for (final event in events) {
      final dateKey = DateTime(
          event.startTime.year, event.startTime.month, event.startTime.day);
      final category = _heatmapCategoryForEvent(event);
      final durationMinutes =
          event.endTime.difference(event.startTime).inMinutes;

      if (durationMinutes <= 0) continue;

      dayCategoryDurations.putIfAbsent(dateKey, () => {});
      dayCategoryDurations[dateKey]![category] =
          (dayCategoryDurations[dateKey]![category] ?? 0) + durationMinutes;
    }

    return dayCategoryDurations.entries.map((e) {
      return DailyHeatmapRecord(
        date: e.key,
        categoryDurations: e.value,
      );
    }).toList();
  }

  Future<void> _fetchHeatmapMonth(DateTime focusedDay) async {
    final userId = context.read<AuthViewModel>().currentUser?.id;
    if (userId == null) return;

    final anchor = DateTime(focusedDay.year, focusedDay.month, focusedDay.day);
    final requestId = ++_heatmapRequestId;
    final events = await context.read<CalendarViewModel>().loadEventsForRange(
          userId: userId,
          eventRangeAnchor: anchor,
          mergeEventAnchors: [
            anchor.subtract(const Duration(days: 1)),
            anchor.add(const Duration(days: 1)),
          ],
          fullYearRange: false,
        );

    if (!mounted || requestId != _heatmapRequestId) return;
    setState(() {
      _heatmapRecords = _generateRecordsFromEvents(events);
    });
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, MMM d').format(DateTime.now()),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Text(
                'Dashboard',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.black,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  static const _gradientDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFEAFFFE), Color(0xFFCDC9F1)],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFCDC9F1),
      body: SizedBox.expand(
        child: DecoratedBox(
          decoration: _gradientDecoration,
          child: SafeArea(
            child: Builder(
              builder: (context) {
                final userId = context.watch<AuthViewModel>().currentUser?.id;
                if (userId != null && _initialFetchedUserId != userId) {
                  _initialFetchedUserId = userId;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    _fetchHeatmapMonth(_focusedDate);
                  });
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      HeatmapCalendarWidget(
                        records: _heatmapRecords,
                        focusedDate: _focusedDate,
                        onPageChanged: (focusedDay) {
                          setState(() {
                            _focusedDate = focusedDay;
                          });
                          _fetchHeatmapMonth(focusedDay);
                        },
                      ),
                      const SizedBox(height: 20),
                      const LocationCardWidget(),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
