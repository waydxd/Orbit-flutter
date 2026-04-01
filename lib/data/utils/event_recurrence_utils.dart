/// Maps Repeat dropdown labels to API fields (iCalendar-style RRULE subset).
class EventRecurrenceUtils {
  EventRecurrenceUtils._();

  /// Weekday codes for RRULE BYDAY (Monday = 1 in Dart [DateTime.weekday]).
  static const _byDay = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

  static String byDayForDate(DateTime start) => _byDay[start.weekday - 1];

  /// Returns API values for POST/PUT body.
  static ({
    bool isRecurring,
    String recurrenceRule,
    String recurrenceException,
  }) fromUiRepeat(String repeatLabel, DateTime startLocal) {
    switch (repeatLabel) {
      case 'Daily':
        return (
          isRecurring: true,
          recurrenceRule: 'FREQ=DAILY',
          recurrenceException: '',
        );
      case 'Weekly':
        return (
          isRecurring: true,
          recurrenceRule: 'FREQ=WEEKLY;BYDAY=${byDayForDate(startLocal)}',
          recurrenceException: '',
        );
      case 'Monthly':
        return (
          isRecurring: true,
          recurrenceRule: 'FREQ=MONTHLY;BYMONTHDAY=${startLocal.day}',
          recurrenceException: '',
        );
      case 'Never':
      default:
        return (
          isRecurring: false,
          recurrenceRule: '',
          recurrenceException: '',
        );
    }
  }

  /// Best-effort label for the dropdown when loading an existing event.
  static String toUiRepeat({
    required bool isRecurring,
    required String recurrenceRule,
  }) {
    if (!isRecurring || recurrenceRule.isEmpty) return 'Never';
    final r = recurrenceRule.toUpperCase();
    if (r.contains('FREQ=DAILY')) return 'Daily';
    if (r.contains('FREQ=WEEKLY')) return 'Weekly';
    if (r.contains('FREQ=MONTHLY')) return 'Monthly';
    return 'Never';
  }
}
