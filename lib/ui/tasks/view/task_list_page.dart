import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/themes/app_colors.dart';
import '../../calendar/view_model/calendar_view_model.dart';
import '../../../data/models/task_model.dart';
import '../../../core/services/notification_service.dart';
import 'task_detail_page.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
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
        child: Consumer<CalendarViewModel>(
          builder: (context, viewModel, child) {
            final pendingTasks =
                viewModel.tasks.where((t) => !t.completed).toList();

            return SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  Expanded(
                    child: viewModel.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Theme(
                            data: Theme.of(context).copyWith(
                              canvasColor: Colors.transparent,
                            ),
                            child: ReorderableListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: pendingTasks.length + 1, // +1 for summary card
                              onReorder: (oldIndex, newIndex) {
                                // Adjust indices since index 0 is summary card
                                if (oldIndex == 0 || newIndex == 0) return; 
                                int oldTaskIndex = oldIndex - 1;
                                int newTaskIndex = newIndex - 1;
                                
                                // Call view model reorder on the full tasks list
                                // Need to find original indices in viewModel.tasks
                                final oldTask = pendingTasks[oldTaskIndex];
                                final oldOriginalIndex = viewModel.tasks.indexOf(oldTask);
                                
                                // For simplicity, we just reorder in the viewModel if supported
                                viewModel.reorderTasks(oldOriginalIndex, newTaskIndex >= pendingTasks.length ? viewModel.tasks.length : viewModel.tasks.indexOf(pendingTasks[newTaskIndex]));
                              },
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return Container(
                                    key: const ValueKey('summary_card'),
                                    padding: const EdgeInsets.only(top: 20, bottom: 30),
                                    child: _buildSummaryCard(pendingTasks),
                                  );
                                }
                                
                                final task = pendingTasks[index - 1];
                                return Container(
                                  key: ValueKey(task.id),
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Dismissible(
                                      key: ValueKey('dismiss_${task.id}'),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        color: Colors.redAccent,
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(right: 20),
                                        child: const Icon(Icons.delete, color: Colors.white),
                                      ),
                                      confirmDismiss: (direction) async {
                                        return await showDialog<bool>(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: const Text('Delete Task'),
                                              content: const Text('Are you sure you want to delete this task?'),
                                              actions: <Widget>[
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(false),
                                                  child: const Text('CANCEL'),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(true),
                                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                                  child: const Text('DELETE'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      onDismissed: (direction) {
                                        viewModel.deleteTask(task.id);
                                      },
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => TaskDetailPage(task: task),
                                            ),
                                          );
                                        },
                                        child: Material(
                                          color: Colors.transparent,
                                          child: TaskItemWidget(
                                            task: task,
                                            color: _getPriorityColor(task.priority),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
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
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 15),
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
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          Text(
            '$taskCount tasks',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
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
              shadows: [
                Shadow(
                  color: Colors.black12,
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
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
}

class TaskItemWidget extends StatefulWidget {
  final TaskModel task;
  final Color color;

  const TaskItemWidget({
    super.key,
    required this.task,
    required this.color,
  });

  @override
  State<TaskItemWidget> createState() => _TaskItemWidgetState();
}

class _TaskItemWidgetState extends State<TaskItemWidget> {
  Timer? _timer;
  String _countdownText = '';
  bool _hasNotified = false;

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    if (widget.task.dueDate != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _updateCountdown();
      });
    }
  }

  @override
  void didUpdateWidget(covariant TaskItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.task.dueDate != oldWidget.task.dueDate) {
      _timer?.cancel();
      _updateCountdown();
      if (widget.task.dueDate != null) {
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          _updateCountdown();
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateCountdown() {
    if (widget.task.dueDate == null) {
      if (_countdownText != '') {
        setState(() => _countdownText = '');
      }
      return;
    }

    final now = DateTime.now();
    final difference = widget.task.dueDate!.difference(now);

    // Notify if task is due in less than 30 minutes and hasn't been notified yet
    if (!difference.isNegative && difference.inMinutes <= 30 && !_hasNotified) {
      _hasNotified = true;
      NotificationService().showNotification(
        id: widget.task.id.hashCode,
        title: 'Task Due Soon',
        body: '${widget.task.title} is due in ${difference.inMinutes} minutes.',
      );
    }

    String newText;
    if (difference.isNegative) {
      newText = 'Overdue';
    } else if (difference.inDays > 1) {
      newText = '${difference.inDays} days';
    } else if (difference.inDays == 1) {
      newText = '1 day ${difference.inHours.remainder(24)}h';
    } else {
      final hours = difference.inHours;
      final minutes = difference.inMinutes.remainder(60);
      
      if (hours > 0) {
        newText = '${hours}h ${minutes}m';
      } else if (minutes > 0) {
        newText = '${minutes}m';
      } else {
        newText = '< 1m';
      }
    }

    if (_countdownText != newText) {
      setState(() => _countdownText = newText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = widget.task.priority.toLowerCase() == 'urgent';

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        // Removed border radius and box shadow here since it's now handled by the parent container
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: double.infinity,
            decoration: BoxDecoration(
              color: widget.color,
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
                  widget.task.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                if (widget.task.description.isNotEmpty)
                  Text(
                    widget.task.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey400,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (_countdownText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  Text(
                    _countdownText,
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
