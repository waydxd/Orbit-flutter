import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../data/models/event_model.dart';
import '../view_model/calendar_view_model.dart';
import '../../core/themes/app_colors.dart';
<<<<<<< Updated upstream
=======
import '../../tasks/view/create_item_page.dart';
>>>>>>> Stashed changes

class EventDetailPage extends StatelessWidget {
  final EventModel event;

  const EventDetailPage({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      children: [
                        // Illustration Area
                        Container(
                          height: 240,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                          ),
                          child: Stack(
                            children: [
                              // Abstract shapes to simulate illustration background
                              Positioned(
                                bottom: 0,
                                left: -50,
                                child: Container(
                                  width: 300,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: -50,
                                right: -20,
                                child: Container(
                                  width: 250,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              // Demo Icon in center
                              const Center(
                                child: Icon(
                                  Icons.event_note_rounded,
                                  size: 100,
                                  color: Colors.white30,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Title Area
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(88, 16, 24, 16),
                          color: AppColors.primaryDark,
                          child: Text(
                            event.title,
                            style: const TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Top Actions
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.more_horiz, color: Colors.white),
                        onPressed: () => _showMoreOptions(context),
                      ),
                    ),
                    // Floating Action Button
                    Positioned(
                      bottom: -28,
<<<<<<< Updated upstream
                      left: 24,
=======
                      right: 24, // Changed from left: 24 to right: 24
>>>>>>> Stashed changes
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.secondary,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            customBorder: const CircleBorder(),
<<<<<<< Updated upstream
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Edit coming soon')),
                              );
=======
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CreateItemPage(
                                    initialIsEvent: true,
                                    editEvent: event,
                                  ),
                                ),
                              );
                              // We could pop this page to return to calendar if edited
                              if (result == true && context.mounted) {
                                Navigator.pop(context);
                              }
>>>>>>> Stashed changes
                            },
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),

                _buildListItem(
                  icon: Icons.access_time_rounded,
                  title: _formatDate(event.startTime),
                  subtitle: _formatTimeRange(event.startTime, event.endTime),
                ),
                
                if (event.location.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  _buildListItem(
                    icon: Icons.location_on_rounded,
                    title: 'Location',
                    subtitle: event.location,
                  ),
                ],

                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  _buildListItem(
                    icon: Icons.flag_rounded,
                    title: 'Description',
                    subtitle: event.description,
                  ),
                ],
                
                const SizedBox(height: 40),
              ],
            ),
          ),
          
          // Bottom Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _handleDelete(context),
                    child: const Text(
                      'DELETE',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'DONE',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey.shade500, size: 28),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, d MMM').format(date);
  }

  String _formatTimeRange(DateTime start, DateTime end) {
    final timeFormatter = DateFormat('HH:mm');
    if (start.year == end.year && start.month == end.month && start.day == end.day) {
      return '${timeFormatter.format(start)} - ${timeFormatter.format(end)}';
    } else {
      final dateFormatter = DateFormat('d MMM');
      return '${timeFormatter.format(start)} - ${dateFormatter.format(end)} ${timeFormatter.format(end)}';
    }
  }

  Future<void> _handleDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        final viewModel = Provider.of<CalendarViewModel>(context, listen: false);
        await viewModel.deleteEvent(event.id);
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event deleted successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete event: $e')),
          );
        }
      }
    }
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context); // Close bottom sheet
                _handleDelete(context); // Trigger delete confirmation
              },
            ),
          ],
        ),
      ),
    );
  }
}
