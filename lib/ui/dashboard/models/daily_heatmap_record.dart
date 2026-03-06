class DailyHeatmapRecord {
  final DateTime date;
  final Map<String, int> categoryDurations; // Category name -> duration in minutes

  const DailyHeatmapRecord({
    required this.date,
    required this.categoryDurations,
  });

  /// The category with the highest duration.
  String? get dominantCategory {
    if (categoryDurations.isEmpty) return null;
    return categoryDurations.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Total duration of all events on this day.
  int get totalDuration {
    if (categoryDurations.isEmpty) return 0;
    return categoryDurations.values.reduce((a, b) => a + b);
  }
}
