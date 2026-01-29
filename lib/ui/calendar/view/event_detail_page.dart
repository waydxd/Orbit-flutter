import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../data/models/event_model.dart';
import '../../../data/models/suggestion_model.dart';
import '../../../data/view_models/suggestions_view_model.dart';
import '../../core/themes/app_colors.dart';
import '../widgets/ai_suggestions_section.dart';

/// Event Detail Page showing event information and AI-generated suggestions
class EventDetailPage extends StatefulWidget {
  final EventModel event;

  const EventDetailPage({super.key, required this.event});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  @override
  void initState() {
    super.initState();
    // Fetch AI suggestions when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchSuggestions();
    });
  }

  void _fetchSuggestions() {
    final suggestionsViewModel = context.read<SuggestionsViewModel>();
    suggestionsViewModel.fetchSuggestions(event: widget.event);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEventHeader(),
                const Divider(height: 1, thickness: 1, color: AppColors.grey200),
                _buildEventDetails(),
                const Divider(height: 1, thickness: 1, color: AppColors.grey200),
                _buildAISuggestionsSection(),
                const SizedBox(height: 100), // Bottom padding for FAB
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildRefreshFab(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: _getEventColor(widget.event.title),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.white),
          onPressed: () {
            // TODO: Navigate to edit event
          },
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: () {
            _showEventOptionsMenu();
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.event.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getEventColor(widget.event.title),
                _getEventColor(widget.event.title).withValues(alpha: 0.8),
              ],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.event,
              size: 60,
              color: Colors.white24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventHeader() {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getEventColor(widget.event.title).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_today,
                  color: _getEventColor(widget.event.title),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFormat.format(widget.event.startTime),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${timeFormat.format(widget.event.startTime)} - ${timeFormat.format(widget.event.endTime)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location
          if (widget.event.location.isNotEmpty) ...[
            _buildDetailRow(
              icon: Icons.location_on_outlined,
              title: 'Location',
              content: widget.event.location,
              iconColor: AppColors.secondary,
            ),
            const SizedBox(height: 16),
          ],

          // Description
          if (widget.event.description.isNotEmpty) ...[
            _buildDetailRow(
              icon: Icons.description_outlined,
              title: 'Description',
              content: widget.event.description,
              iconColor: AppColors.info,
            ),
          ],

          // Empty state for no details
          if (widget.event.location.isEmpty && widget.event.description.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 48,
                      color: AppColors.grey300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No additional details',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
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

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String content,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAISuggestionsSection() {
    return Consumer<SuggestionsViewModel>(
      builder: (context, viewModel, child) {
        return AISuggestionsSection(
          event: widget.event,
          suggestions: viewModel.suggestions,
          isLoading: viewModel.isFetchingSuggestions,
          error: viewModel.suggestionsError,
          onRefresh: _fetchSuggestions,
        );
      },
    );
  }

  Widget _buildRefreshFab() {
    return Consumer<SuggestionsViewModel>(
      builder: (context, viewModel, child) {
        return FloatingActionButton.extended(
          onPressed: viewModel.isFetchingSuggestions
              ? null
              : () => viewModel.fetchSuggestions(
                    event: widget.event,
                    forceRefresh: true,
                  ),
          backgroundColor: viewModel.isFetchingSuggestions
              ? AppColors.grey400
              : AppColors.primary,
          icon: viewModel.isFetchingSuggestions
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.auto_awesome, color: Colors.white),
          label: Text(
            viewModel.isFetchingSuggestions
                ? 'Analyzing...'
                : 'Get AI Suggestions',
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );
  }

  void _showEventOptionsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share Event'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement share
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Duplicate Event'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement duplicate
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Delete Event',
                  style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement delete
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getEventColor(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('math')) return const Color(0xFF50C8AA);
    if (lowerTitle.contains('english')) return const Color(0xFF8B80F0);
    if (lowerTitle.contains('history')) return const Color(0xFF0096FF);
    if (lowerTitle.contains('meeting')) return const Color(0xFFFF6B6B);
    if (lowerTitle.contains('lunch') || lowerTitle.contains('dinner')) {
      return const Color(0xFFFFB347);
    }
    return AppColors.primary;
  }
}

