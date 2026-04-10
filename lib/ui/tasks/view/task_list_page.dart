import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/themes/app_colors.dart';
import '../../core/widgets/hashtag_chip.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../../calendar/view_model/calendar_view_model.dart';
import '../../../data/models/task_model.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/hooks/use_countdown.dart';
import 'task_detail_page.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  bool _showCompleted = true;

  /// `null` = all priorities; otherwise matches [TaskModel.priority] case-insensitively.
  String? _priorityFilter;

  Future<void> _refreshTasks() async {
    final userId = context.read<AuthViewModel>().currentUser?.id;
    if (userId == null) return;
    await context.read<CalendarViewModel>().refreshTasks(userId: userId);
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
        child: Consumer<CalendarViewModel>(
          builder: (context, viewModel, child) {
            final filteredTasks = viewModel.tasks.where((t) {
              if (_priorityFilter == null) return true;
              return t.priority.toLowerCase() == _priorityFilter!.toLowerCase();
            }).toList();
            final pendingTasks =
                filteredTasks.where((t) => !t.completed).toList();
            final completedTasks =
                filteredTasks.where((t) => t.completed).toList();

            return SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  Expanded(
                    child: viewModel.isLoading && viewModel.tasks.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : RefreshIndicator(
                            onRefresh: _refreshTasks,
                            color: const Color(0xFF8B80F0),
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                canvasColor: Colors.transparent,
                              ),
                              child: ReorderableListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: 1 + // summary
                                    pendingTasks.length +
                                    (completedTasks.isNotEmpty
                                        ? 1
                                        : 0) + // completed header
                                    (_showCompleted
                                        ? completedTasks.length
                                        : 0),
                                onReorder: (oldIndex, newIndex) {
                                  // Skip reorder if involving summary or completed sections
                                  const summaryCardIndex = 0;
                                  final pendingStartIndex = 1;
                                  final completedHeaderIndex =
                                      pendingStartIndex + pendingTasks.length;
                                  final completedStartIndex =
                                      completedHeaderIndex + 1;

                                  if (oldIndex == summaryCardIndex ||
                                      newIndex == summaryCardIndex) return;
                                  if (oldIndex == completedHeaderIndex ||
                                      newIndex == completedHeaderIndex) return;
                                  if (oldIndex >= completedStartIndex ||
                                      newIndex >= completedStartIndex) return;

                                  // Adjust indices since index 0 is summary card
                                  final int oldTaskIndex =
                                      oldIndex - pendingStartIndex;
                                  final int newTaskIndex =
                                      newIndex <= completedHeaderIndex
                                          ? newIndex - pendingStartIndex
                                          : pendingTasks.length;
                                  // Call view model reorder on the full tasks list
                                  final oldTask = pendingTasks[oldTaskIndex];
                                  final oldOriginalIndex =
                                      viewModel.tasks.indexOf(oldTask);

                                  // For simplicity, we just reorder in the viewModel if supported
                                  viewModel.reorderTasks(
                                      oldOriginalIndex,
                                      newTaskIndex >= pendingTasks.length
                                          ? viewModel.tasks.length
                                          : viewModel.tasks.indexOf(
                                              pendingTasks[newTaskIndex]));
                                },
                                itemBuilder: (context, index) {
                                  // Summary card
                                  if (index == 0) {
                                    return Container(
                                      key: const ValueKey('summary_card'),
                                      padding: const EdgeInsets.only(
                                          top: 20, bottom: 30),
                                      child: _buildSummaryCard(pendingTasks),
                                    );
                                  }

                                  // Pending tasks
                                  final pendingStartIndex = 1;
                                  if (index >= pendingStartIndex &&
                                      index <
                                          pendingStartIndex +
                                              pendingTasks.length) {
                                    final taskIndex = index - pendingStartIndex;
                                    final task = pendingTasks[taskIndex];
                                    return Container(
                                      key: ValueKey(task.id),
                                      padding:
                                          const EdgeInsets.only(bottom: 16),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.05),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: Dismissible(
                                          key: ValueKey('dismiss_${task.id}'),
                                          direction:
                                              DismissDirection.horizontal,
                                          background: Container(
                                            color: const Color(0xFF50C8AA),
                                            alignment: Alignment.centerLeft,
                                            padding:
                                                const EdgeInsets.only(left: 20),
                                            child: const Row(
                                              children: [
                                                Icon(Icons.check,
                                                    color: Colors.white),
                                                SizedBox(width: 8),
                                                Text('Complete',
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                          secondaryBackground: Container(
                                            color: Colors.redAccent,
                                            alignment: Alignment.centerRight,
                                            padding: const EdgeInsets.only(
                                                right: 20),
                                            child: const Icon(Icons.delete,
                                                color: Colors.white),
                                          ),
                                          confirmDismiss: (direction) async {
                                            if (direction ==
                                                DismissDirection.startToEnd) {
                                              return await _showCompleteConfirmation(
                                                  context);
                                            } else {
                                              return await _showDeleteConfirmation(
                                                  context);
                                            }
                                          },
                                          onDismissed: (direction) {
                                            if (direction ==
                                                DismissDirection.startToEnd) {
                                              _markTaskComplete(
                                                  task.id, viewModel);
                                            } else {
                                              viewModel.deleteTask(task.id);
                                            }
                                          },
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      TaskDetailPage(
                                                          task: task),
                                                ),
                                              );
                                            },
                                            child: Material(
                                              color: Colors.transparent,
                                              child: TaskItemWidget(
                                                task: task,
                                                color: _getPriorityColor(
                                                    task.priority),
                                                onCheckboxTap: () async {
                                                  if (await _showCompleteConfirmation(
                                                      context)) {
                                                    _markTaskComplete(
                                                        task.id, viewModel);
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  // Completed section header
                                  final completedHeaderIndex =
                                      pendingStartIndex + pendingTasks.length;
                                  if (completedTasks.isNotEmpty &&
                                      index == completedHeaderIndex) {
                                    return Container(
                                      key: const ValueKey('completed_header'),
                                      child: _buildCompletedSectionHeader(
                                          completedTasks.length),
                                    );
                                  }

                                  // Completed tasks (collapsible)
                                  if (index > completedHeaderIndex) {
                                    final completedIndex =
                                        index - completedHeaderIndex - 1;
                                    if (completedIndex <
                                        completedTasks.length) {
                                      final task =
                                          completedTasks[completedIndex];
                                      return AnimatedOpacity(
                                        key: ValueKey(task.id),
                                        opacity: _showCompleted ? 1.0 : 0.0,
                                        duration:
                                            const Duration(milliseconds: 800),
                                        curve: Curves.easeInOutCubic,
                                        child: AnimatedSlide(
                                          offset: _showCompleted
                                              ? Offset.zero
                                              : const Offset(0, 0.5),
                                          duration:
                                              const Duration(milliseconds: 800),
                                          curve: Curves.easeInOutCubic,
                                          child: _buildCompletedTaskCard(task),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  }

                                  // Fallback - should never reach here with correct itemCount
                                  return const SizedBox.shrink();
                                },
                              ),
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
    final filterActive = _priorityFilter != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            tooltip: 'Filter by priority',
            onPressed: () => _showPriorityFilterSheet(context),
            icon: Icon(
              Icons.filter_list_rounded,
              color: filterActive ? const Color(0xFF8B80F0) : AppColors.black,
              size: 28,
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refreshTasks,
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.black,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  void _showPriorityFilterSheet(BuildContext context) {
    const options = <(String label, String? value)>[
      ('All priorities', null),
      ('Urgent', 'urgent'),
      ('High', 'high'),
      ('Medium', 'medium'),
      ('Low', 'low'),
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.grey400.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    'Filter by priority',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                ...options.map((opt) {
                  final selected = _priorityFilter == opt.$2;
                  return ListTile(
                    title: Text(
                      opt.$1,
                      style: TextStyle(
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                        color: selected
                            ? const Color(0xFF8B80F0)
                            : AppColors.textPrimary,
                      ),
                    ),
                    trailing: selected
                        ? const Icon(Icons.check_rounded,
                            color: Color(0xFF8B80F0))
                        : null,
                    onTap: () {
                      setState(() => _priorityFilter = opt.$2);
                      Navigator.of(sheetContext).pop();
                    },
                  );
                }),
              ],
            ),
          ),
        ),
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

  Widget _buildCompletedTaskCard(TaskModel task) {
    return Container(
      height: 42,
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () async {
              if (await _showRevertConfirmation(context)) {
                _markTaskIncomplete(task.id, context.read<CalendarViewModel>());
              }
            },
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFF50C8AA),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 12),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              task.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                decoration: TextDecoration.lineThrough,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildCompletedSectionHeader(int count) {
    return GestureDetector(
      onTapDown: (_) => setState(() {}),
      onTapUp: (_) {
        setState(() {
          _showCompleted = !_showCompleted;
        });
      },
      onTapCancel: () => setState(() {}),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Color.lerp(
            AppColors.white.withValues(alpha: 0.85),
            AppColors.white,
            _showCompleted ? 1.0 : 0.0,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(alpha: _showCompleted ? 0.08 : 0.12),
              blurRadius: _showCompleted ? 8 : 12,
              offset: Offset(0, _showCompleted ? 2 : 4),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _showCompleted
                    ? Icons.check_circle
                    : Icons.check_circle_outline,
                key: ValueKey(_showCompleted),
                color: const Color(0xFF50C8AA),
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Completed ($count)',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            AnimatedRotation(
              turns: _showCompleted ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showCompleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFECF9FB), Color(0xFFE9E7FF)],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.9),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.15),
                    blurRadius: 36,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Complete Task?',
                    style: Theme.of(dialogContext)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mark this task as complete.',
                    style:
                        Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          style: TextButton.styleFrom(
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Complete',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFECF9FB), Color(0xFFE9E7FF)],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.9),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.error.withValues(alpha: 0.15),
                    blurRadius: 36,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.delete_rounded,
                      color: AppColors.error,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Delete Task?',
                    style: Theme.of(dialogContext)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This action cannot be undone.',
                    style:
                        Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          style: TextButton.styleFrom(
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Delete',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }

  Future<bool> _showRevertConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFECF9FB), Color(0xFFE9E7FF)],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.9),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    blurRadius: 36,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.undo_rounded,
                      color: AppColors.warning,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Revert Task?',
                    style: Theme.of(dialogContext)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Move this task back to pending.',
                    style:
                        Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          style: TextButton.styleFrom(
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.warning,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Revert',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }

  Future<void> _markTaskComplete(
      String taskId, CalendarViewModel viewModel) async {
    final task = viewModel.tasks.firstWhere((t) => t.id == taskId);
    await viewModel.updateTask(task.copyWith(completed: true));
  }

  Future<void> _markTaskIncomplete(
      String taskId, CalendarViewModel viewModel) async {
    final task = viewModel.tasks.firstWhere((t) => t.id == taskId);
    await viewModel.updateTask(task.copyWith(completed: false));
  }
}

class TaskItemWidget extends StatefulWidget {
  final TaskModel task;
  final Color color;
  final VoidCallback? onCheckboxTap;

  const TaskItemWidget({
    required this.task,
    required this.color,
    this.onCheckboxTap,
    super.key,
  });

  @override
  State<TaskItemWidget> createState() => _TaskItemWidgetState();
}

class _TaskItemWidgetState extends State<TaskItemWidget> {
  late final CountdownController _countdownController;

  @override
  void initState() {
    super.initState();
    _countdownController = CountdownController(
      config: CountdownConfig(
        dueDate: widget.task.dueDate,
        onWarning: () {
          final difference = widget.task.dueDate!.difference(DateTime.now());
          NotificationService().showNotification(
            id: widget.task.id.hashCode,
            title: 'Task Due Soon',
            body:
                '${widget.task.title} is due in ${difference.inMinutes} minutes.',
          );
        },
        onTick: (_) {
          if (mounted) setState(() {});
        },
      ),
    );
    _countdownController.start();
  }

  @override
  void didUpdateWidget(covariant TaskItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.task.dueDate != oldWidget.task.dueDate) {
      _countdownController.updateDueDate(widget.task.dueDate);
    }
  }

  @override
  void dispose() {
    _countdownController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = widget.task.priority.toLowerCase() == 'urgent';

    return Container(
      height: 70,
      decoration: const BoxDecoration(
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
          GestureDetector(
            onTap: widget.onCheckboxTap,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: widget.task.completed
                    ? const Color(0xFF50C8AA)
                    : Colors.transparent,
                border: Border.all(
                  color: widget.task.completed
                      ? const Color(0xFF50C8AA)
                      : AppColors.grey400,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: widget.task.completed
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.task.completed
                        ? AppColors.textSecondary
                        : AppColors.black,
                    decoration: widget.task.completed
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.task.hashtags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: [
                        ...widget.task.hashtags
                            .take(3)
                            .map((tag) => HashtagChipCompact(tag: tag)),
                        if (widget.task.hashtags.length > 3)
                          Text(
                            '+${widget.task.hashtags.length - 3}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.grey400,
                            ),
                          ),
                      ],
                    ),
                  ),
                if (widget.task.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      widget.task.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.task.completed
                            ? AppColors.grey400
                            : AppColors.grey400,
                        fontWeight: FontWeight.w500,
                        decoration: widget.task.completed
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          if (_countdownController.state.text.isNotEmpty &&
              !widget.task.completed)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  Text(
                    _countdownController.state.text,
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
