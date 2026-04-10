import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/themes/app_colors.dart';
import '../../calendar/view_model/calendar_view_model.dart';
import '../../settings/view/settings_page.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/event_model.dart';
import '../../shared/widgets/card_stack_item.dart';
import '../widgets/upcoming_carousel.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
        child: SafeArea(
          child: Consumer<CalendarViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              // Prepare data
              final now = DateTime.now();

              // Past vs Total Events (Only Today)
              final todayEvents = viewModel.events.where((e) {
                return e.startTime.year == now.year &&
                    e.startTime.month == now.month &&
                    e.startTime.day == now.day;
              }).toList();
              final totalEvents = todayEvents.length;
              final pastEvents =
                  todayEvents.where((e) => e.endTime.isBefore(now)).length;

              // Tasks
              final totalTasks = viewModel.tasks.length;
              final completedTasks =
                  viewModel.tasks.where((t) => t.completed).length;

              // Upcoming tasks/events for swappable cards
              final upcomingTasks =
                  viewModel.tasks.where((t) => !t.completed).toList();
              final upcomingEvents = viewModel.events
                  .where((e) => e.startTime.isAfter(now))
                  .toList();

              // Combine and sort
              final List<dynamic> combinedUpcoming = [
                ...upcomingTasks,
                ...upcomingEvents
              ];
              combinedUpcoming.sort((a, b) {
                final dateA = a is TaskModel
                    ? (a.dueDate ?? DateTime(2099))
                    : (a as EventModel).startTime;
                final dateB = b is TaskModel
                    ? (b.dueDate ?? DateTime(2099))
                    : (b as EventModel).startTime;
                return dateA.compareTo(dateB);
              });

              return ListView(
                padding: const EdgeInsets.only(
                    bottom: 120), // Space for floating nav bar
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),

                  // 1. Swappable Cards (Upcoming Tasks/Events)
                  _buildSectionTitle('Upcoming'),
                  const SizedBox(height: 10),
                  combinedUpcoming.isEmpty
                      ? SizedBox(
                          height: 220,
                          child: _buildEmptyStateCard('No upcoming items!'),
                        )
                      : UpcomingCarousel(
                          items: combinedUpcoming
                              .take(5)
                              .map((item) {
                                if (item is TaskModel) {
                                  return CardStackItem.fromTask(
                                    id: item.id,
                                    title: item.title,
                                    description: item.description,
                                    dueDate: item.dueDate,
                                  );
                                } else {
                                  final event = item as EventModel;
                                  return CardStackItem.fromEvent(
                                    id: event.id,
                                    title: event.title,
                                    description: event.description,
                                    startTime: event.startTime,
                                    hashtags: event.hashtags,
                                  );
                                }
                              })
                              .toList(),
                          viewportFraction: 0.88,
                        ),

                  const SizedBox(height: 30),

                  // 2. AI Agent Suggestion
                  _buildSectionTitle('AI Suggestions'),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildAiSuggestionCard(),
                  ),

                  const SizedBox(height: 30),

                  // 3. Count of past event / total event
                  _buildSectionTitle('Today\'s Statistics'),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildStatsCard(
                      pastEvents,
                      totalEvents,
                      completedTasks,
                      totalTasks,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
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
                'Good Morning',
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard(String message) {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(
      int pastEvents, int totalEvents, int completedTasks, int totalTasks) {
    return Row(
      children: [
        Expanded(
          child: _buildSquareStatCard(
              'Past Events', pastEvents, totalEvents, const Color(0xFF8B80F0)),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildSquareStatCard('Tasks Done', completedTasks, totalTasks,
              const Color(0xFF50C8AA)),
        ),
      ],
    );
  }

  Widget _buildSquareStatCard(
      String label, int completed, int total, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
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
      child: _buildCircularStat(label, completed, total, color),
    );
  }

  Widget _buildCircularStat(
      String label, int completed, int total, Color color) {
    final double progress = total == 0 ? 0 : completed / total;
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 8,
                valueColor:
                    AlwaysStoppedAnimation<Color>(color.withValues(alpha: 0.2)),
              ),
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeCap: StrokeCap.round,
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$completed',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '/ $total',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildAiSuggestionCard() {
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
                  'Schedule optimization available',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Based on your recent habits, we suggest moving "Math Study" to 10:00 AM for better focus.',
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
}
