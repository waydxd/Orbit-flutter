// OpenAPI / backend contract (events):
// - `is_recurring` (bool): whether the row represents a recurring series.
// - `recurrence_rule` (string): iCalendar RRULE subset. This client always emits
//   `INTERVAL=1` when encoding. Supported: FREQ=DAILY|WEEKLY|MONTHLY|YEARLY;
//   WEEKLY uses `BYDAY` from the series start weekday; MONTHLY uses `BYMONTHDAY`;
//   YEARLY uses `BYMONTH` and `BYMONTHDAY`. Optional `UNTIL` is the UTC instant
//   corresponding to the end of the chosen local calendar day, formatted as
//   `yyyyMMdd'T'HHmmss'Z'` (no punctuation in date part besides T and Z).
// - `recurrence_exception` (string): optional EXDATE-style data; not expanded here.
//
// New creates can materialize repeats as many non-recurring rows (see
// `event_recurrence_materialize.dart`). [occursOnDay] still expands server-stored
// RRULE for calendar UI within the fetched time range.

import '../models/event_model.dart';

enum RecurrenceFrequency { never, daily, weekly, monthly, yearly }

/// Encoded fields for API create/update bodies.
typedef EncodedRecurrence = ({
  bool isRecurring,
  String recurrenceRule,
  String recurrenceException,
});

/// UI state restored from an event or parsed rule.
typedef RecurrencePrefill = ({
  String frequencyLabel,
  bool endsNever,
  DateTime? untilLocalDate,
});

/// Parsed RRULE subset used internally and by [tryParseRule].
typedef RRuleParts = ({
  RecurrenceFrequency frequency,
  int interval,
  List<int> byWeekdays,
  int? byMonthDay,
  int? byMonth,
  DateTime? untilUtc,
});

abstract final class EventRecurrence {
  const EventRecurrence._();

  static const _byDayTokens = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

  static DateTime _dateOnlyLocal(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  /// Civil calendar distance between two local calendar dates (y/m/d), ignoring DST.
  static int _calendarDaysBetweenLocalDates(DateTime a, DateTime b) {
    final ua = DateTime.utc(a.year, a.month, a.day);
    final ub = DateTime.utc(b.year, b.month, b.day);
    return ub.difference(ua).inDays;
  }

  static bool _sameCalendarDayLocal(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _byDayFromWeekday(int dartWeekday) =>
      _byDayTokens[dartWeekday - 1];

  /// Formats [localEndOfDay] (any time on that local calendar day) as UNTIL in UTC.
  static String _formatUntilUtcFromLocalEndOfDay(DateTime localEndOfDay) {
    final end = DateTime(
      localEndOfDay.year,
      localEndOfDay.month,
      localEndOfDay.day,
      23,
      59,
      59,
    );
    final u = end.toUtc();
    final y = u.year.toString().padLeft(4, '0');
    final mo = u.month.toString().padLeft(2, '0');
    final d = u.day.toString().padLeft(2, '0');
    final h = u.hour.toString().padLeft(2, '0');
    final mi = u.minute.toString().padLeft(2, '0');
    final s = u.second.toString().padLeft(2, '0');
    return '$y$mo${d}T$h$mi${s}Z';
  }

  static DateTime? _parseUntilUtc(String upperRule) {
    final m = RegExp(r'UNTIL=([0-9]{8}T[0-9]{6}Z)', caseSensitive: false)
        .firstMatch(upperRule);
    if (m == null) return null;
    final raw = m.group(1)!;
    final y = int.parse(raw.substring(0, 4));
    final mo = int.parse(raw.substring(4, 6));
    final d = int.parse(raw.substring(6, 8));
    final h = int.parse(raw.substring(9, 11));
    final mi = int.parse(raw.substring(11, 13));
    final s = int.parse(raw.substring(13, 15));
    return DateTime.utc(y, mo, d, h, mi, s);
  }

  static Map<String, String> _parsePairs(String rule) {
    final out = <String, String>{};
    for (final part in rule.split(';')) {
      final p = part.trim();
      if (p.isEmpty) continue;
      final eq = p.indexOf('=');
      if (eq <= 0) continue;
      final k = p.substring(0, eq).trim().toUpperCase();
      final v = p.substring(eq + 1).trim();
      out[k] = v;
    }
    return out;
  }

  /// Best-effort parse of a stored RRULE string. Missing `INTERVAL` ⇒ 1.
  static RRuleParts? tryParseRule(String rule) {
    if (rule.trim().isEmpty) return null;
    final upper = rule.toUpperCase();
    final m = _parsePairs(upper);
    final freqStr = m['FREQ'];
    if (freqStr == null) return null;

    RecurrenceFrequency freq;
    switch (freqStr) {
      case 'DAILY':
        freq = RecurrenceFrequency.daily;
        break;
      case 'WEEKLY':
        freq = RecurrenceFrequency.weekly;
        break;
      case 'MONTHLY':
        freq = RecurrenceFrequency.monthly;
        break;
      case 'YEARLY':
        freq = RecurrenceFrequency.yearly;
        break;
      default:
        return null;
    }

    final interval = int.tryParse(m['INTERVAL'] ?? '1') ?? 1;
    final untilUtc = _parseUntilUtc(upper);

    final byWeekdays = <int>[];
    final byday = m['BYDAY'];
    if (byday != null && byday.isNotEmpty) {
      for (final token in byday.split(',')) {
        final t = token.trim().toUpperCase();
        final idx = _byDayTokens.indexOf(t);
        if (idx >= 0) byWeekdays.add(idx + 1);
      }
    }

    int? byMonthDay;
    final bmd = m['BYMONTHDAY'];
    if (bmd != null) {
      byMonthDay = int.tryParse(bmd.split(',').first.trim());
    }

    int? byMonth;
    final bm = m['BYMONTH'];
    if (bm != null) {
      byMonth = int.tryParse(bm.split(',').first.trim());
    }

    return (
      frequency: freq,
      interval: interval <= 0 ? 1 : interval,
      byWeekdays: byWeekdays,
      byMonthDay: byMonthDay,
      byMonth: byMonth,
      untilUtc: untilUtc,
    );
  }

  static RecurrenceFrequency frequencyFromLabel(String label) {
    switch (label.trim()) {
      case 'Daily':
        return RecurrenceFrequency.daily;
      case 'Weekly':
        return RecurrenceFrequency.weekly;
      case 'Monthly':
        return RecurrenceFrequency.monthly;
      case 'Yearly':
        return RecurrenceFrequency.yearly;
      case 'Never':
      default:
        return RecurrenceFrequency.never;
    }
  }

  static String labelFromFrequency(RecurrenceFrequency f) {
    switch (f) {
      case RecurrenceFrequency.never:
        return 'Never';
      case RecurrenceFrequency.daily:
        return 'Daily';
      case RecurrenceFrequency.weekly:
        return 'Weekly';
      case RecurrenceFrequency.monthly:
        return 'Monthly';
      case RecurrenceFrequency.yearly:
        return 'Yearly';
    }
  }

  /// Builds `recurrence_rule` / `is_recurring` for the API.
  static EncodedRecurrence encode({
    required RecurrenceFrequency frequency,
    required DateTime startLocal,
    required bool endsNever,
    DateTime? untilLocalDate,
  }) {
    if (frequency == RecurrenceFrequency.never) {
      return (
        isRecurring: false,
        recurrenceRule: '',
        recurrenceException: '',
      );
    }

    final buf = StringBuffer();
    switch (frequency) {
      case RecurrenceFrequency.never:
        throw StateError('encode: never must be handled before switch');
      case RecurrenceFrequency.daily:
        buf.write('FREQ=DAILY;INTERVAL=1');
        break;
      case RecurrenceFrequency.weekly:
        buf.write(
          'FREQ=WEEKLY;INTERVAL=1;BYDAY=${_byDayFromWeekday(startLocal.weekday)}',
        );
        break;
      case RecurrenceFrequency.monthly:
        buf.write(
          'FREQ=MONTHLY;INTERVAL=1;BYMONTHDAY=${startLocal.day}',
        );
        break;
      case RecurrenceFrequency.yearly:
        buf.write(
          'FREQ=YEARLY;INTERVAL=1;BYMONTH=${startLocal.month};BYMONTHDAY=${startLocal.day}',
        );
        break;
    }

    if (!endsNever && untilLocalDate != null) {
      buf.write(';UNTIL=${_formatUntilUtcFromLocalEndOfDay(untilLocalDate)}');
    }

    return (
      isRecurring: true,
      recurrenceRule: buf.toString(),
      recurrenceException: '',
    );
  }

  static RecurrencePrefill prefillFromEvent(EventModel event) {
    if (event.recurrenceRule.trim().isEmpty) {
      return (
        frequencyLabel: 'Never',
        endsNever: true,
        untilLocalDate: null,
      );
    }
    final parsed = tryParseRule(event.recurrenceRule);
    if (parsed == null) {
      return (
        frequencyLabel: 'Never',
        endsNever: true,
        untilLocalDate: null,
      );
    }

    final label = labelFromFrequency(parsed.frequency);
    final untilUtc = parsed.untilUtc;
    if (untilUtc == null) {
      return (
        frequencyLabel: label,
        endsNever: true,
        untilLocalDate: null,
      );
    }
    final untilLocal = untilUtc.toLocal();
    return (
      frequencyLabel: label,
      endsNever: false,
      untilLocalDate: _dateOnlyLocal(untilLocal),
    );
  }

  static bool _occurrenceStartOnDayRespectsUntil({
    required DateTime dayLocal,
    required DateTime seriesStartLocal,
    required DateTime? untilUtc,
  }) {
    if (untilUtc == null) return true;
    final occStart = DateTime(
      dayLocal.year,
      dayLocal.month,
      dayLocal.day,
      seriesStartLocal.hour,
      seriesStartLocal.minute,
      seriesStartLocal.second,
    );
    return !occStart.toUtc().isAfter(untilUtc);
  }

  /// Whether [event] should appear on the calendar cell for [day] (local date).
  ///
  /// Uses [EventModel.recurrenceRule] as the source of truth when non-empty so
  /// repeats still expand if `is_recurring` is wrong or missing in the payload.
  static bool occursOnDay(EventModel event, DateTime day) {
    final dayD = _dateOnlyLocal(day);
    final startD = _dateOnlyLocal(event.startTime);

    if (event.recurrenceRule.trim().isEmpty) {
      return _sameCalendarDayLocal(event.startTime, day);
    }

    if (dayD.isBefore(startD)) return false;

    final parsed = tryParseRule(event.recurrenceRule);
    if (parsed == null) {
      return _sameCalendarDayLocal(event.startTime, day);
    }

    if (!_occurrenceStartOnDayRespectsUntil(
      dayLocal: dayD,
      seriesStartLocal: event.startTime,
      untilUtc: parsed.untilUtc,
    )) {
      return false;
    }

    final interval = parsed.interval;

    switch (parsed.frequency) {
      case RecurrenceFrequency.never:
        return _sameCalendarDayLocal(event.startTime, day);
      case RecurrenceFrequency.daily:
        final days = _calendarDaysBetweenLocalDates(startD, dayD);
        return days >= 0 && days % interval == 0;
      case RecurrenceFrequency.weekly:
        final weekdays = parsed.byWeekdays.isEmpty
            ? <int>[event.startTime.weekday]
            : parsed.byWeekdays;
        final startCal =
            DateTime.utc(startD.year, startD.month, startD.day);
        final dayCal = DateTime.utc(dayD.year, dayD.month, dayD.day);
        if (!weekdays.contains(dayCal.weekday)) return false;
        final startWeekMonday =
            startCal.subtract(Duration(days: startCal.weekday - 1));
        final dayWeekMonday =
            dayCal.subtract(Duration(days: dayCal.weekday - 1));
        final weeks =
            dayWeekMonday.difference(startWeekMonday).inDays ~/ 7;
        final weeklyOk = weeks >= 0 && weeks % interval == 0;
        return weeklyOk;
      case RecurrenceFrequency.monthly:
        final dom = parsed.byMonthDay ?? event.startTime.day;
        if (dayD.day != dom) return false;
        final months =
            (dayD.year - startD.year) * 12 + (dayD.month - startD.month);
        return months >= 0 && months % interval == 0;
      case RecurrenceFrequency.yearly:
        final m = parsed.byMonth ?? event.startTime.month;
        final dom = parsed.byMonthDay ?? event.startTime.day;
        if (dayD.month != m || dayD.day != dom) return false;
        final years = dayD.year - startD.year;
        return years >= 0 && years % interval == 0;
    }
  }

  /// UTC end-of-day for [localCalendarDay], matching optional RRULE `UNTIL` in [encode].
  static DateTime untilUtcFromLocalRepeatEndDate(DateTime localCalendarDay) {
    final end = DateTime(
      localCalendarDay.year,
      localCalendarDay.month,
      localCalendarDay.day,
      23,
      59,
      59,
    );
    return end.toUtc();
  }

  /// True if [occurrenceStartLocal] is not after the RRULE `UNTIL` instant for
  /// [untilLocalRepeatEndDate].
  static bool occurrenceStartWithinRepeatEnd({
    required DateTime occurrenceStartLocal,
    required DateTime untilLocalRepeatEndDate,
  }) {
    final untilUtc = untilUtcFromLocalRepeatEndDate(untilLocalRepeatEndDate);
    return !occurrenceStartLocal.toUtc().isAfter(untilUtc);
  }
}
