import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/themes/app_colors.dart';
import '../../calendar/widgets/floating_nav_bar.dart';
import '../../calendar/view_model/calendar_view_model.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../../../data/models/task_model.dart';
import 'create_item_page.dart';
import '../../dashboard/view/dashboard_page.dart';
import '../../chat/view/chat_page.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      body: Consumer<CalendarViewModel>(
        builder: (context, viewModel, child) {
          final pendingTasks =
              viewModel.tasks.where((t) => !t.completed).toList();

          return Stack(
            fit: StackFit.expand,
            children: [
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: viewModel.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              children: [
                                const SizedBox(height: 20),
                                _buildSummaryCard(pendingTasks),
                                const SizedBox(height: 30),
                                ...viewModel.tasks.map(
                                  (task) => _buildTaskItem(
                                    title: task.title,
                                    subtitle: task.description,
                                    color: _getPriorityColor(task.priority),
                                    deadline: _getDeadlineText(task.dueDate),
                                    isUrgent: task.priority == 'urgent',
                                  ),
                                ),
                                const SizedBox(height: 120), // Space for FAB
                              ],
                            ),
                    ),
                  ],
                ),
              ),
              FloatingNavBar(
                currentIndex: 2,
                onHomeTap: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                onCalendarTap: () {
                  Navigator.pop(context);
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
                  // Already here
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
          );
        },
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Colors.redAccent;
      case 'high':
        return Colors.orangeAccent;
      case 'medium':
        return Colors.blueAccent;
      case 'low':
        return Colors.greenAccent;
      default:
        return Colors.grey;
    }
  }

  String? _getDeadlineText(DateTime? dueDate) {
    if (dueDate == null) return null;
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;
    if (difference < 0) return 'Overdue';
    if (difference == 0) return 'Today';
    return '$difference days';
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list_rounded, color: AppColors.black),
              const SizedBox(width: 15),
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
          const Icon(Icons.menu_rounded, color: AppColors.black, size: 28),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(List<TaskModel> pendingTasks) {
    final taskCount = pendingTasks.length;

    TaskModel? urgentTask;
    try {
      urgentTask = pendingTasks.firstWhere((t) => t.priority == 'urgent');
    } catch (_) {
      if (pendingTasks.isNotEmpty) {
        urgentTask = pendingTasks.first;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD4DAF3), Color(0xFFE2E7F5)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'You still have',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          Text(
            '$taskCount tasks',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 25),
          const Text(
            'UPCOMING',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFF8178D3),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          if (urgentTask != null)
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _getPriorityColor(urgentTask.priority),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    urgentTask.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          else
            const Text(
              'No upcoming tasks',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskItem({
    required String title,
    required Color color,
    String? subtitle,
    String? deadline,
    bool isUrgent = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: double.infinity,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.grey400, width: 2),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          if (deadline != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  Text(
                    deadline,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isUrgent ? Colors.redAccent : AppColors.black,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.access_time_rounded,
                    size: 20,
                    color: isUrgent ? Colors.redAccent : AppColors.black,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
