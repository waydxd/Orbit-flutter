import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/daily_heatmap_record.dart';

import '../../core/themes/app_colors.dart';

class HeatmapCalendarWidget extends StatelessWidget {
  final List<DailyHeatmapRecord> records;
  final DateTime focusedDate;
  final ValueChanged<DateTime> onPageChanged;

  const HeatmapCalendarWidget({
    super.key,
    required this.records,
    required this.focusedDate,
    required this.onPageChanged,
  });

  static const Map<String, Color> categoryColors = {
    'Work': Color(0xFF4A90D9), // Blue
    'Study': Color(0xFF7B68EE), // Purple
    'Exercise': Color(0xFF50C878), // Green
    'Personal': Color(0xFFFFB347), // Orange
    'Other': Color(0xFFB0BEC5), // Grey
  };

  @override
  Widget build(BuildContext context) {
    // Calculate max minutes in the current records to normalize intensity
    int maxMinutes = 0;
    for (var record in records) {
      if (record.totalDuration > maxMinutes) {
        maxMinutes = record.totalDuration;
      }
    }

    // Convert list to map for quick lookup
    final Map<DateTime, DailyHeatmapRecord> recordMap = {
      for (var r in records)
        DateTime(r.date.year, r.date.month, r.date.day): r
    };

    return Column(
      children: [
        const SizedBox(height: 8),
        
          // Calendar Container
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
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
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: focusedDate,
              calendarFormat: CalendarFormat.month,
              onPageChanged: onPageChanged,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.textPrimary),
                rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.textPrimary),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                weekendStyle: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  return _buildCell(context, day, recordMap, maxMinutes);
                },
                todayBuilder: (context, day, focusedDay) {
                  return _buildCell(context, day, recordMap, maxMinutes, isToday: true);
                },
                outsideBuilder: (context, day, focusedDay) {
                  return _buildCell(context, day, recordMap, maxMinutes, isOutside: true);
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCell(
    BuildContext context,
    DateTime day,
    Map<DateTime, DailyHeatmapRecord> recordMap,
    int maxMinutes, {
    bool isToday = false,
    bool isOutside = false,
  }) {
    final dateKey = DateTime(day.year, day.month, day.day);
    final record = recordMap[dateKey];
    
    Color cellColor = Colors.white; // Clean white for empty days
    
    double intensity = 0.0;
    
    if (record != null && record.totalDuration > 0 && maxMinutes > 0) {
      final dominantCategory = record.dominantCategory;
      final baseColor = categoryColors[dominantCategory] ?? categoryColors['Other']!;
      
      intensity = record.totalDuration / maxMinutes;
      // Clamp intensity between 0 and 1 just in case
      intensity = intensity.clamp(0.0, 1.0);
      
      cellColor = baseColor.withOpacity(0.2 + 0.8 * intensity);
    }

    if (isOutside) {
      cellColor = cellColor.withOpacity(0.3);
    }

    return GestureDetector(
      onTap: () {
        if (record != null && record.totalDuration > 0) {
          _showBreakdownBottomSheet(context, day, record);
        }
      },
      onLongPress: () {
        if (record != null && record.totalDuration > 0) {
          _showPercentageCard(context, day, record);
        }
      },
      child: Container(
        margin: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          color: cellColor,
          borderRadius: BorderRadius.circular(8.0),
          border: isToday ? Border.all(color: AppColors.primary, width: 2) : null,
          boxShadow: record != null && record.totalDuration > 0 ? [
            BoxShadow(
              color: cellColor.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.day}',
          style: TextStyle(
                color: isOutside ? AppColors.grey400 : (intensity > 0.5 ? Colors.white : AppColors.textPrimary),
            fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _showBreakdownBottomSheet(BuildContext context, DateTime day, DailyHeatmapRecord record) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')} Breakdown',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...record.categoryDurations.entries.map((entry) {
                final color = categoryColors[entry.key] ?? categoryColors['Other']!;
                final hours = entry.value ~/ 60;
                final minutes = entry.value % 60;
                final durationStr = hours > 0 
                    ? '${hours}h ${minutes > 0 ? '${minutes}m' : ''}'
                    : '${minutes}m';
                    
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        entry.key,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      Text(
                        durationStr,
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showPercentageCard(BuildContext context, DateTime day, DailyHeatmapRecord record) {
    final totalDuration = record.totalDuration;
    if (totalDuration == 0) return;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...record.categoryDurations.entries.map((entry) {
                  final color = categoryColors[entry.key] ?? categoryColors['Other']!;
                  final percentage = (entry.value / totalDuration * 100).toStringAsFixed(1);
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          entry.key,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                        ),
                        const Spacer(),
                        Text(
                          '$percentage%',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
