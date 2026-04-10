import 'event_recurrence.dart';

typedef MaterializedOccurrence = ({DateTime start, DateTime end});

/// Generates concrete start/end pairs for a repeat through [untilLocalDate] (inclusive).
///
/// [frequency] must not be [RecurrenceFrequency.never]. Steps match [EventRecurrence.occursOnDay]
/// intent for `INTERVAL=1` (daily +1 day, weekly +7 days on same weekday, monthly same
/// day-of-month skipping short months, yearly same month/day skipping years without that date).
List<MaterializedOccurrence> materializeRecurringOccurrences({
  required RecurrenceFrequency frequency,
  required DateTime firstStart,
  required DateTime firstEnd,
  required DateTime untilLocalDate,
}) {
  if (frequency == RecurrenceFrequency.never) {
    throw ArgumentError.value(
      frequency,
      'frequency',
      'must not be never; use a single non-recurring event',
    );
  }

  final duration = firstEnd.difference(firstStart);
  final out = <MaterializedOccurrence>[];

  DateTime stepFrom(DateTime current) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        final cal = DateTime(current.year, current.month, current.day);
        final nextCal = cal.add(const Duration(days: 1));
        return DateTime(
          nextCal.year,
          nextCal.month,
          nextCal.day,
          current.hour,
          current.minute,
          current.second,
          current.millisecond,
          current.microsecond,
        );
      case RecurrenceFrequency.weekly:
        final cal = DateTime(current.year, current.month, current.day);
        final nextCal = cal.add(const Duration(days: 7));
        return DateTime(
          nextCal.year,
          nextCal.month,
          nextCal.day,
          current.hour,
          current.minute,
          current.second,
          current.millisecond,
          current.microsecond,
        );
      case RecurrenceFrequency.monthly:
        return _nextMonthlyOccurrence(current, firstStart);
      case RecurrenceFrequency.yearly:
        return _nextYearlyOccurrence(current);
      case RecurrenceFrequency.never:
        throw StateError('unreachable');
    }
  }

  var occStart = firstStart;
  const maxOcc = 10000;
  for (var i = 0; i < maxOcc; i++) {
    if (!EventRecurrence.occurrenceStartWithinRepeatEnd(
      occurrenceStartLocal: occStart,
      untilLocalRepeatEndDate: untilLocalDate,
    )) {
      break;
    }
    final occEnd = occStart.add(duration);
    out.add((start: occStart, end: occEnd));
    final next = stepFrom(occStart);
    if (!next.isAfter(occStart)) {
      break;
    }
    occStart = next;
  }

  return out;
}

DateTime _nextMonthlyOccurrence(DateTime current, DateTime seriesStart) {
  final dom = seriesStart.day;
  final h = current.hour;
  final mi = current.minute;
  final s = current.second;
  final ms = current.millisecond;
  final us = current.microsecond;

  var y = current.year;
  var m = current.month + 1;
  if (m > 12) {
    m = 1;
    y++;
  }
  for (var guard = 0; guard < 2400; guard++) {
    final last = DateTime(y, m + 1, 0).day;
    if (dom <= last) {
      return DateTime(y, m, dom, h, mi, s, ms, us);
    }
    m++;
    if (m > 12) {
      m = 1;
      y++;
    }
  }
  throw StateError('monthly recurrence overflow');
}

DateTime _nextYearlyOccurrence(DateTime current) {
  final m = current.month;
  final dom = current.day;
  final h = current.hour;
  final mi = current.minute;
  final s = current.second;
  final ms = current.millisecond;
  final us = current.microsecond;

  var y = current.year + 1;
  for (var guard = 0; guard < 400; guard++) {
    final last = DateTime(y, m + 1, 0).day;
    if (dom <= last) {
      return DateTime(y, m, dom, h, mi, s, ms, us);
    }
    y++;
  }
  throw StateError('yearly recurrence overflow');
}
