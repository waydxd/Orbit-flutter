import 'package:flutter/material.dart';
import '../../../data/models/suggestion_model.dart';
import '../../core/themes/app_colors.dart';

/// Card widget displaying a single AI suggestion
class SuggestionCard extends StatefulWidget {
  final SuggestionModel suggestion;

  const SuggestionCard({
    super.key,
    required this.suggestion,
  });

  @override
  State<SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends State<SuggestionCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final type = SuggestionType.fromString(widget.suggestion.type);
    final color = _getColorForType(type);

    return GestureDetector(
      onTap: _toggleExpand,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isExpanded ? color.withValues(alpha: 0.3) : AppColors.grey200,
            width: _isExpanded ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isExpanded
                  ? color.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: _isExpanded ? 12 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIconForType(type),
                      color: color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Title and preview
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.suggestion.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _isExpanded ? color : AppColors.textPrimary,
                          ),
                        ),
                        if (!_isExpanded) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.suggestion.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Expand indicator
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: _isExpanded ? color : AppColors.grey400,
                    ),
                  ),
                ],
              ),
            ),
            // Expanded content
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 1, color: AppColors.grey200),
                    const SizedBox(height: 16),
                    // Main content
                    Text(
                      widget.suggestion.content,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.6,
                      ),
                    ),
                    // Metadata if available
                    if (widget.suggestion.metadata != null &&
                        widget.suggestion.metadata!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildMetadata(),
                    ],
                    // Action buttons
                    const SizedBox(height: 16),
                    _buildActionButtons(color),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadata() {
    final metadata = widget.suggestion.metadata!;
    final type = SuggestionType.fromString(widget.suggestion.type);

    // Render different metadata based on type
    switch (type) {
      case SuggestionType.weather:
        return _buildWeatherMetadata(metadata);
      case SuggestionType.nearbyPlaces:
      case SuggestionType.nearbyRestaurants:
        return _buildPlacesMetadata(metadata);
      case SuggestionType.transport:
        return _buildTransportMetadata(metadata);
      default:
        return _buildGenericMetadata(metadata);
    }
  }

  Widget _buildWeatherMetadata(Map<String, dynamic> metadata) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (metadata['temperature'] != null)
            _buildMetadataItem(
              Icons.thermostat,
              '${metadata['temperature']}°',
              'Temp',
            ),
          if (metadata['humidity'] != null)
            _buildMetadataItem(
              Icons.water_drop_outlined,
              '${metadata['humidity']}%',
              'Humidity',
            ),
          if (metadata['condition'] != null)
            _buildMetadataItem(
              _getWeatherIcon(metadata['condition']),
              metadata['condition'],
              'Condition',
            ),
        ],
      ),
    );
  }

  Widget _buildPlacesMetadata(Map<String, dynamic> metadata) {
    final places = metadata['places'] as List<dynamic>?;
    if (places == null || places.isEmpty) return const SizedBox.shrink();

    return Column(
      children: places.take(3).map<Widget>((place) {
        final placeMap = place as Map<String, dynamic>;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.grey50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.place_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      placeMap['name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (placeMap['distance'] != null)
                      Text(
                        '${placeMap['distance']} away',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (placeMap['rating'] != null)
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${placeMap['rating']}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTransportMetadata(Map<String, dynamic> metadata) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (metadata['duration'] != null)
            _buildMetadataItem(
              Icons.schedule,
              metadata['duration'],
              'Duration',
            ),
          if (metadata['distance'] != null)
            _buildMetadataItem(
              Icons.straighten,
              metadata['distance'],
              'Distance',
            ),
          if (metadata['mode'] != null)
            _buildMetadataItem(
              _getTransportIcon(metadata['mode']),
              metadata['mode'],
              'Mode',
            ),
        ],
      ),
    );
  }

  Widget _buildGenericMetadata(Map<String, dynamic> metadata) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: metadata.entries.take(3).map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  entry.value.toString(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMetadataItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Color color) {
    return Row(
      children: [
        _buildActionButton(
          icon: Icons.share_outlined,
          label: 'Share',
          onTap: () {
            // TODO: Implement share
          },
        ),
        const SizedBox(width: 12),
        _buildActionButton(
          icon: Icons.bookmark_outline,
          label: 'Save',
          onTap: () {
            // TODO: Implement save
          },
        ),
        const Spacer(),
        _buildActionButton(
          icon: Icons.open_in_new,
          label: 'More',
          color: color,
          onTap: () {
            // TODO: Open more details
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    final buttonColor = color ?? AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: buttonColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: buttonColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(SuggestionType type) {
    switch (type) {
      case SuggestionType.weather:
        return Icons.cloud_outlined;
      case SuggestionType.transport:
        return Icons.directions_car_outlined;
      case SuggestionType.dressCode:
        return Icons.checkroom_outlined;
      case SuggestionType.nearbyPlaces:
        return Icons.place_outlined;
      case SuggestionType.nearbyRestaurants:
        return Icons.restaurant_outlined;
      case SuggestionType.schedule:
        return Icons.schedule_outlined;
      case SuggestionType.general:
        return Icons.lightbulb_outline;
    }
  }

  Color _getColorForType(SuggestionType type) {
    switch (type) {
      case SuggestionType.weather:
        return const Color(0xFF3B82F6);
      case SuggestionType.transport:
        return const Color(0xFF10B981);
      case SuggestionType.dressCode:
        return const Color(0xFFF59E0B);
      case SuggestionType.nearbyPlaces:
        return const Color(0xFFEF4444);
      case SuggestionType.nearbyRestaurants:
        return const Color(0xFFFF6B6B);
      case SuggestionType.schedule:
        return const Color(0xFF8B5CF6);
      case SuggestionType.general:
        return AppColors.primary;
    }
  }

  IconData _getWeatherIcon(String condition) {
    final lower = condition.toLowerCase();
    if (lower.contains('rain')) return Icons.water_drop;
    if (lower.contains('cloud')) return Icons.cloud;
    if (lower.contains('sun') || lower.contains('clear')) return Icons.wb_sunny;
    if (lower.contains('snow')) return Icons.ac_unit;
    if (lower.contains('thunder') || lower.contains('storm')) return Icons.flash_on;
    return Icons.cloud_outlined;
  }

  IconData _getTransportIcon(String mode) {
    final lower = mode.toLowerCase();
    if (lower.contains('walk')) return Icons.directions_walk;
    if (lower.contains('bike') || lower.contains('cycle')) return Icons.directions_bike;
    if (lower.contains('bus') || lower.contains('transit')) return Icons.directions_bus;
    if (lower.contains('train') || lower.contains('subway')) return Icons.train;
    if (lower.contains('car') || lower.contains('drive')) return Icons.directions_car;
    return Icons.directions;
  }
}

