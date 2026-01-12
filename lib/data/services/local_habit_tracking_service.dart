import '../models/habit_suggestion.dart';

/// Local/Mock implementation of habit tracking service
/// This stores data in memory and detects patterns locally
/// Use this for demo/testing when backend is not available
class LocalHabitTrackingService {
  // Singleton instance
  static final LocalHabitTrackingService _instance = LocalHabitTrackingService._internal();
  factory LocalHabitTrackingService() => _instance;
  LocalHabitTrackingService._internal();

  // Store recorded events: key is a unique pattern identifier
  // Pattern: "userId|title|startTime|endTime|dayOfWeek"
  final Map<String, List<_RecordedEvent>> _recordedEvents = {};

  // Store dismissed habit IDs by pattern key
  final Set<String> _dismissedPatternKeys = {};

  // Store accepted habit IDs by pattern key
  final Set<String> _acceptedPatternKeys = {};

  // Minimum occurrences to suggest as habit
  static const int _minOccurrences = 3;

  /// Record an event for habit frequency tracking
  Future<void> recordEvent({
    required String userId,
    required String title,
    String? description,
    required String startTime,
    required String endTime,
    required int dayOfWeek,
    String? location,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));

    final patternKey = _createPatternKey(
      userId: userId,
      title: title,
      startTime: startTime,
      endTime: endTime,
      dayOfWeek: dayOfWeek,
    );

    final event = _RecordedEvent(
      userId: userId,
      title: title,
      description: description,
      startTime: startTime,
      endTime: endTime,
      dayOfWeek: dayOfWeek,
      location: location,
      recordedAt: DateTime.now(),
    );

    if (_recordedEvents[patternKey] == null) {
      _recordedEvents[patternKey] = [];
    }
    _recordedEvents[patternKey]!.add(event);

    print('LocalHabitTracking: Recorded event "$title" for pattern $patternKey');
    print('LocalHabitTracking: Pattern now has ${_recordedEvents[patternKey]!.length} occurrences');
  }

  /// Get habit suggestions for a user (events occurring 3+ times)
  Future<List<HabitSuggestion>> getSuggestions(String userId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));

    final suggestions = <HabitSuggestion>[];
    int habitId = 1;

    for (final entry in _recordedEvents.entries) {
      final patternKey = entry.key;
      final events = entry.value;

      // Filter by userId
      final userEvents = events.where((e) => e.userId == userId).toList();

      if (userEvents.length >= _minOccurrences) {
        // Check if already dismissed or accepted using pattern key
        if (_dismissedPatternKeys.contains(patternKey) || _acceptedPatternKeys.contains(patternKey)) {
          habitId++;
          continue;
        }

        final latestEvent = userEvents.last;
        suggestions.add(HabitSuggestion(
          habitId: habitId,
          title: latestEvent.title,
          description: latestEvent.description,
          startTime: latestEvent.startTime,
          endTime: latestEvent.endTime,
          dayOfWeek: latestEvent.dayOfWeek,
          dayOfWeekName: _getDayOfWeekName(latestEvent.dayOfWeek),
          location: latestEvent.location,
          frequency: userEvents.length,
          lastOccurrence: latestEvent.recordedAt,
        ));
      }
      habitId++;
    }

    print('LocalHabitTracking: Found ${suggestions.length} suggestions for user $userId');
    return suggestions;
  }

  /// Accept a habit suggestion (simulates creating 5-year recurring events)
  Future<AcceptSuggestionResponse> acceptSuggestion({
    required String userId,
    required int habitId,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Find the pattern key by habitId
    final patternKey = _getPatternKeyByHabitId(habitId);
    if (patternKey != null) {
      _acceptedPatternKeys.add(patternKey);
    }

    // Calculate events for 1 years
    const eventsCreated = 52;

    print('LocalHabitTracking: Accepted habit $habitId (pattern: $patternKey), would create $eventsCreated events');

    return AcceptSuggestionResponse(
      message: 'Successfully created recurring events for 5 years',
      eventsCreated: eventsCreated,
    );
  }

  /// Dismiss a habit suggestion
  Future<void> dismissSuggestion(int habitId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));

    // Find the pattern key by habitId
    final patternKey = _getPatternKeyByHabitId(habitId);
    if (patternKey != null) {
      _dismissedPatternKeys.add(patternKey);
    }
    print('LocalHabitTracking: Dismissed habit $habitId (pattern: $patternKey)');
  }

  /// Get pattern key by habit ID
  String? _getPatternKeyByHabitId(int habitId) {
    int currentId = 1;
    for (final entry in _recordedEvents.entries) {
      if (currentId == habitId) {
        return entry.key;
      }
      currentId++;
    }
    return null;
  }

  /// Get suggestion by habit ID (for creating recurring events)
  HabitSuggestion? getSuggestionByHabitId(int habitId) {
    int currentId = 1;
    for (final entry in _recordedEvents.entries) {
      if (currentId == habitId) {
        final events = entry.value;
        if (events.isNotEmpty) {
          final latestEvent = events.last;
          return HabitSuggestion(
            habitId: habitId,
            title: latestEvent.title,
            description: latestEvent.description,
            startTime: latestEvent.startTime,
            endTime: latestEvent.endTime,
            dayOfWeek: latestEvent.dayOfWeek,
            dayOfWeekName: _getDayOfWeekName(latestEvent.dayOfWeek),
            location: latestEvent.location,
            frequency: events.length,
            lastOccurrence: latestEvent.recordedAt,
          );
        }
      }
      currentId++;
    }
    return null;
  }

  /// Clear all data (for testing)
  void clearAll() {
    _recordedEvents.clear();
    _dismissedPatternKeys.clear();
    _acceptedPatternKeys.clear();
    print('LocalHabitTracking: Cleared all data');
  }

  /// Get stats for debugging
  Map<String, dynamic> getStats() {
    return {
      'totalPatterns': _recordedEvents.length,
      'totalEvents': _recordedEvents.values.fold<int>(0, (sum, list) => sum + list.length),
      'dismissedCount': _dismissedPatternKeys.length,
      'acceptedCount': _acceptedPatternKeys.length,
    };
  }

  String _createPatternKey({
    required String userId,
    required String title,
    required String startTime,
    required String endTime,
    required int dayOfWeek,
  }) {
    // Normalize title for matching (lowercase, trimmed)
    final normalizedTitle = title.toLowerCase().trim();
    return '$userId|$normalizedTitle|$startTime|$endTime|$dayOfWeek';
  }

  String _getDayOfWeekName(int dayOfWeek) {
    const days = [
      'Sunday', 'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday'
    ];
    return days[dayOfWeek % 7];
  }
}

/// Internal class to store recorded event data
class _RecordedEvent {
  final String userId;
  final String title;
  final String? description;
  final String startTime;
  final String endTime;
  final int dayOfWeek;
  final String? location;
  final DateTime recordedAt;

  _RecordedEvent({
    required this.userId,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.dayOfWeek,
    this.location,
    required this.recordedAt,
  });
}

