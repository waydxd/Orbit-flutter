import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../data/models/event_model.dart';
import '../view_model/calendar_view_model.dart';
import '../../core/themes/app_colors.dart';
import '../../tasks/view/create_item_page.dart';

class EventDetailPage extends StatelessWidget {
  final EventModel event;

  const EventDetailPage({
    required this.event,
    super.key,
  });

  String _inferCategory(EventModel e) {
    final combined = '${e.title} ${e.description}'.toLowerCase();
    if (combined.contains('work') ||
        combined.contains('meeting') ||
        combined.contains('sync') ||
        combined.contains('office')) {
      return 'Work';
    }
    if (combined.contains('study') ||
        combined.contains('class') ||
        combined.contains('lecture') ||
        combined.contains('exam')) {
      return 'Study';
    }
    if (combined.contains('gym') ||
        combined.contains('exercise') ||
        combined.contains('workout') ||
        combined.contains('run')) {
      return 'Exercise';
    }
    if (combined.contains('personal') ||
        combined.contains('dinner') ||
        combined.contains('lunch') ||
        combined.contains('friend') ||
        combined.contains('family')) {
      return 'Personal';
    }
    return 'Event';
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
        child: SafeArea(
          child: Column(
            children: [
              // Header
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
                        event.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Template image placeholder (1:1 ratio - replace with actual image later)
                          // No top/left/right padding - image fits edge-to-edge in card
                          AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              color: AppColors.grey100,
                              child: const Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 48,
                                  color: AppColors.grey400,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Category tag (pill)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _inferCategory(event).toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Location section (if present)
                                if (event.location.isNotEmpty) ...[
                                  _buildSectionLabel('LOCATION'),
                                  const SizedBox(height: 12),
                                  _buildLocationRow(event.location),
                                  const SizedBox(height: 24),
                                ],

                                // Date & Time section
                                _buildSectionLabel('DATE & TIME'),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  icon: Icons.calendar_today_rounded,
                                  text: _formatDate(event.startTime),
                                ),
                                const SizedBox(height: 8),
                                _buildInfoRow(
                                  icon: Icons.access_time_rounded,
                                  text:
                                      '${_formatTimeRange(event.startTime, event.endTime)} ${_formatDuration(event.startTime, event.endTime)}',
                                ),
                                const SizedBox(height: 24),
                                _buildSectionLabel('DESCRIPTION'),
                                const SizedBox(height: 12),
                                Text(
                                  event.description.isNotEmpty
                                      ? event.description
                                      : 'No description',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: event.description.isNotEmpty
                                        ? AppColors.textSecondary
                                        : AppColors.grey400,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildLocationRow(String location) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    String? subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, d MMMM yyyy').format(date);
  }

  String _formatTimeRange(DateTime start, DateTime end) {
    final timeFormatter = DateFormat('h:mm a');
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return '${timeFormatter.format(start)} - ${timeFormatter.format(end)}';
    } else {
      final dateFormatter = DateFormat('d MMM');
      return '${timeFormatter.format(start)} - ${dateFormatter.format(end)} ${timeFormatter.format(end)}';
    }
  }

  String _formatDuration(DateTime start, DateTime end) {
    final minutes = end.difference(start).inMinutes;
    if (minutes < 60) {
      return '($minutes min)';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return mins > 0 ? '($hours hr $mins min)' : '($hours hr)';
  }

  Future<void> _handleDelete(BuildContext context) async {
    // Capture mounted state before async gap
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
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
      final viewModel =
          Provider.of<CalendarViewModel>(context, listen: false);
      await viewModel.deleteEvent(event.id);
      if (context.mounted) {
        Navigator.pop(context);
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Event deleted successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Failed to delete event: $e')),
        );
      }
    }
  }

  void _showMoreOptions(BuildContext context) {
    // Important: use the page's context for navigation/dialog/provider lookups.
    // The bottom sheet's BuildContext is disposed after closing the sheet.
    final pageContext = context;
    showModalBottomSheet(
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
              title: const Text('Edit',
                  style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  pageContext,
                  MaterialPageRoute(
                    builder: (context) => CreateItemPage(
                      initialIsEvent: true,
                      editEvent: event,
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
              title: const Text('Delete',
                  style: TextStyle(color: AppColors.error)),
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
}
