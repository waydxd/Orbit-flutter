import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/themes/app_colors.dart';
import '../../calendar/widgets/floating_nav_bar.dart';
import '../../calendar/view_model/calendar_view_model.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../../calendar/view/calendar_page.dart';
import '../../dashboard/view/dashboard_page.dart';
import '../../tasks/view/task_list_page.dart';
import '../../tasks/view/create_item_page.dart';
import '../../ai_chat/view/ai_chat_page.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/event_model.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController(viewportFraction: 0.85);

  @override
  void initState() {
    super.initState();
    // Fetch data from backend on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = context.read<AuthViewModel>();
      final userId = authViewModel.currentUser?.id;
      if (userId != null) {
        context.read<CalendarViewModel>().fetchAll(userId: userId);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
                      SizedBox(
                        height: 160,
                        child: combinedUpcoming.isEmpty
                            ? _buildEmptyStateCard('No upcoming items!')
                            : PageView.builder(
                                controller: _pageController,
                                itemCount: combinedUpcoming.length > 5
                                    ? 5
                                    : combinedUpcoming.length,
                                itemBuilder: (context, index) {
                                  final item = combinedUpcoming[index];
                                  return _buildUpcomingCard(item);
                                },
                              ),
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
                        child: _buildStatsCard(pastEvents, totalEvents,
                            completedTasks, totalTasks),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Floating Navigation Bar
            FloatingNavBar(
              currentIndex: 0,
              onHomeTap: () {
                // Already on home page
                debugPrint('Home tapped');
              },
              onCalendarTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CalendarPage(),
                  ),
                );
                debugPrint('Calendar tapped');
              },
              onCreateTaskTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateItemPage(),
                  ),
                );
                debugPrint('Create task tapped');
              },
              onCreateTaskLongPress: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AiChatPage()),
                );
                debugPrint('AI Chat long press');
              },
              onTodoListTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TaskListPage(),
                  ),
                );
                debugPrint('Todo list tapped');
              },
              onDashboardTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DashboardPage(),
                  ),
                );
                debugPrint('Dashboard tapped');
              },
            ),
          ],
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

  Widget _buildUpcomingCard(dynamic item) {
    final bool isTask = item is TaskModel;
    final String typeLabel = isTask ? 'Task' : 'Event';
    final DateTime? date =
        isTask ? item.dueDate : (item as EventModel).startTime;
    final Color typeColor =
        isTask ? AppColors.primary : const Color(0xFF8B80F0);
    return Container(
      margin: const EdgeInsets.only(right: 15, bottom: 10),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    color: typeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              if (date != null)
                Text(
                  DateFormat('MMM d, h:mm a').format(date),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          Text(
            item.description.isNotEmpty ? item.description : 'No description',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
