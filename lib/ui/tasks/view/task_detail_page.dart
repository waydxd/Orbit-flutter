import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../data/models/task_model.dart';
import '../../calendar/view_model/calendar_view_model.dart';
import '../../core/themes/app_colors.dart';
import '../../core/widgets/hashtag_chip.dart';
import 'create_item_page.dart';

class TaskDetailPage extends StatefulWidget {
  final TaskModel task;

  const TaskDetailPage({required this.task, super.key});

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
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

  Future<void> _handleDelete(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final viewModel = Provider.of<CalendarViewModel>(context, listen: false);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child:
                const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await viewModel.deleteTask(widget.task.id);
      if (context.mounted) {
        Navigator.pop(context);
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Task deleted successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Failed to delete task: $e')),
        );
      }
    }
  }

  void _showMoreOptions(BuildContext context) {
    final pageContext = context;
    showModalBottomSheet<void>(
      context: pageContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.edit_outlined, color: AppColors.primary),
              title: const Text(
                'Edit',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push<bool>(
                  pageContext,
                  MaterialPageRoute(
                    builder: (context) => CreateItemPage(
                      initialIsEvent: false,
                      editTask: widget.task,
                    ),
                  ),
                ).then((result) {
                  if (result == true && pageContext.mounted) {
                    Navigator.pop(pageContext);
                  }
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text(
                'Delete',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _handleDelete(pageContext);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final due = task.dueDate;
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new),
                      color: AppColors.textPrimary,
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_horiz),
                      color: AppColors.textPrimary,
                      onPressed: () => _showMoreOptions(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getPriorityColor(task.priority)
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                task.priority.toUpperCase(),
                                style: TextStyle(
                                  color: _getPriorityColor(task.priority),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildSectionLabel('DATE & TIME'),
                            const SizedBox(height: 12),
                            if (due != null) ...[
                              _buildInfoRow(
                                icon: Icons.calendar_today_rounded,
                                text:
                                    DateFormat('EEEE, d MMMM yyyy').format(due),
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                icon: Icons.access_time_rounded,
                                text: DateFormat('h:mm a').format(due),
                              ),
                            ] else
                              const Text(
                                'No due date',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppColors.grey400,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            if (task.hashtags.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              _buildSectionLabel('HASHTAGS'),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: task.hashtags
                                    .map((tag) => HashtagChipCompact(tag: tag))
                                    .toList(),
                              ),
                            ],
                            const SizedBox(height: 24),
                            _buildSectionLabel('DESCRIPTION'),
                            const SizedBox(height: 12),
                            Text(
                              task.description.isNotEmpty
                                  ? task.description
                                  : 'No description',
                              style: TextStyle(
                                fontSize: 15,
                                color: task.description.isNotEmpty
                                    ? AppColors.textSecondary
                                    : AppColors.grey400,
                                height: 1.5,
                              ),
                            ),
                            if (task.completed) ...[
                              const SizedBox(height: 24),
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF50C8AA)
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF50C8AA),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Completed',
                                        style: TextStyle(
                                          color: Color(0xFF50C8AA),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
