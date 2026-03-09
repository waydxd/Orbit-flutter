import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../calendar/widgets/floating_nav_bar.dart';
import '../../tasks/view/task_list_page.dart';
import '../../tasks/view/create_item_page.dart';
import '../../ai_chat/view/ai_chat_page.dart';
import '../models/daily_heatmap_record.dart';
import '../widgets/heatmap_calendar_widget.dart';
import '../widgets/location_card_widget.dart';
import '../../calendar/view_model/calendar_view_model.dart';
import '../../../data/models/event_model.dart';

import '../../core/themes/app_colors.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DateTime _focusedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
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

  List<DailyHeatmapRecord> _generateRecordsFromEvents(List<EventModel> events) {
    final Map<DateTime, Map<String, int>> dayCategoryDurations = {};

    for (final event in events) {
      final dateKey = DateTime(
          event.startTime.year, event.startTime.month, event.startTime.day);
      final category = _inferCategory(event);
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
          Stack(
            children: [
              const Icon(
                Icons.notifications_outlined,
                color: AppColors.black,
                size: 28,
              ),
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF8B80F0),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAFFFE), Color(0xFFCDC9F1)],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            SafeArea(
              child: Consumer<CalendarViewModel>(
                builder: (context, viewModel, child) {
                  final records = _generateRecordsFromEvents(viewModel.events);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 20),
                        HeatmapCalendarWidget(
                          records: records,
                          focusedDate: _focusedDate,
                          onPageChanged: (focusedDay) {
                            setState(() {
                              _focusedDate = focusedDay;
                            });
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

            // Navigation Bar
            FloatingNavBar(
              currentIndex: 3, // Dashboard is index 3
              onHomeTap: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              onCalendarTap: () {
                // Depending on where we came from, but generally we can push or pop.
                // Let's pop if we came from calendar, otherwise push.
                // For simplicity, we can just pop until first, then push Calendar.
                // Wait, Home is usually first. Calendar is separate.
                // Let's match TaskListPage:
                Navigator.pop(context);
              },
              onCreateTaskTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateItemPage(),
                  ),
                );
              },
              onCreateTaskLongPress: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AiChatPage()),
                );
                debugPrint('AI Chat long press');
              },
              onTodoListTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TaskListPage(),
                  ),
                );
              },
              onDashboardTap: () {
                // Already on dashboard page
              },
            ),
          ],
        ),
      ),
    );
  }
}
