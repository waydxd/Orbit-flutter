import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_calendar/data/models/event_model.dart';
import 'package:orbit_calendar/data/utils/event_recurrence.dart';

void main() {
  group('EventRecurrence.encode round-trip', () {
    test('daily without until', () {
      final start = DateTime(2025, 6, 1, 9, 30);
      final enc = EventRecurrence.encode(
        frequency: RecurrenceFrequency.daily,
        startLocal: start,
        endsNever: true,
      );
      expect(enc.isRecurring, isTrue);
      expect(enc.recurrenceRule, 'FREQ=DAILY;INTERVAL=1');
      final p = EventRecurrence.tryParseRule(enc.recurrenceRule)!;
      expect(p.frequency, RecurrenceFrequency.daily);
      expect(p.interval, 1);
      expect(p.untilUtc, isNull);
    });

    test('weekly preserves BYDAY and optional UNTIL', () {
      final start = DateTime(2025, 6, 4, 14, 0); // Wednesday
      final until = DateTime(2025, 6, 30);
      final enc = EventRecurrence.encode(
        frequency: RecurrenceFrequency.weekly,
        startLocal: start,
        endsNever: false,
        untilLocalDate: until,
      );
      expect(enc.recurrenceRule.contains('FREQ=WEEKLY'), isTrue);
      expect(enc.recurrenceRule.contains('INTERVAL=1'), isTrue);
      expect(enc.recurrenceRule.contains('BYDAY=WE'), isTrue);
      expect(enc.recurrenceRule.contains('UNTIL='), isTrue);
      final p = EventRecurrence.tryParseRule(enc.recurrenceRule)!;
      expect(p.frequency, RecurrenceFrequency.weekly);
      expect(p.byWeekdays, contains(DateTime.wednesday));
      expect(p.untilUtc, isNotNull);
    });

    test('legacy weekly without INTERVAL parses as interval 1', () {
      final p = EventRecurrence.tryParseRule('FREQ=WEEKLY;BYDAY=MO')!;
      expect(p.interval, 1);
    });

    test('yearly encodes BYMONTH and BYMONTHDAY', () {
      final start = DateTime(2025, 12, 25, 8, 0);
      final enc = EventRecurrence.encode(
        frequency: RecurrenceFrequency.yearly,
        startLocal: start,
        endsNever: true,
      );
      final p = EventRecurrence.tryParseRule(enc.recurrenceRule)!;
      expect(p.frequency, RecurrenceFrequency.yearly);
      expect(p.byMonth, 12);
      expect(p.byMonthDay, 25);
    });
  });

  group('EventRecurrence.occursOnDay', () {
    test(
        'weekly expands from rule even when isRecurring is false (bad payload)',
        () {
      final start = DateTime(2025, 6, 2, 10, 0);
      final enc = EventRecurrence.encode(
        frequency: RecurrenceFrequency.weekly,
        startLocal: start,
        endsNever: true,
      );
      final event = EventModel(
        id: 'e1',
        userId: 'u',
        title: 'Weekly',
        description: '',
        startTime: start,
        endTime: start.add(const Duration(hours: 1)),
        location: '',
        isRecurring: false,
        recurrenceRule: enc.recurrenceRule,
        createdAt: start,
        updatedAt: start,
      );
      expect(
        EventRecurrence.occursOnDay(event, DateTime(2025, 6, 9)),
        isTrue,
      );
    });

    test('weekly matches when calendar passes UTC-normalized day', () {
      final start = DateTime(2025, 6, 2, 10, 0); // Monday
      final enc = EventRecurrence.encode(
        frequency: RecurrenceFrequency.weekly,
        startLocal: start,
        endsNever: true,
      );
      final event = EventModel(
        id: 'e1',
        userId: 'u',
        title: 'Weekly',
        description: '',
        startTime: start,
        endTime: start.add(const Duration(hours: 1)),
        location: '',
        isRecurring: enc.isRecurring,
        recurrenceRule: enc.recurrenceRule,
        createdAt: start,
        updatedAt: start,
      );
      expect(
        EventRecurrence.occursOnDay(event, DateTime.utc(2025, 6, 9)),
        isTrue,
      );
    });

    test('weekly matches weekday from start', () {
      final start = DateTime(2025, 6, 2, 10, 0); // Monday
      final enc = EventRecurrence.encode(
        frequency: RecurrenceFrequency.weekly,
        startLocal: start,
        endsNever: true,
      );
      final event = EventModel(
        id: 'e1',
        userId: 'u',
        title: 'Weekly',
        description: '',
        startTime: start,
        endTime: start.add(const Duration(hours: 1)),
        location: '',
        isRecurring: enc.isRecurring,
        recurrenceRule: enc.recurrenceRule,
        createdAt: start,
        updatedAt: start,
      );
      expect(
        EventRecurrence.occursOnDay(event, DateTime(2025, 6, 9)),
        isTrue,
      );
      expect(
        EventRecurrence.occursOnDay(event, DateTime(2025, 6, 10)),
        isFalse,
      );
    });

    test('daily counts civil calendar days across US DST spring forward', () {
      final start = DateTime(2024, 3, 10, 9, 0); // local civil Mar 10
      final enc = EventRecurrence.encode(
        frequency: RecurrenceFrequency.daily,
        startLocal: start,
        endsNever: true,
      );
      final event = EventModel(
        id: 'e1',
        userId: 'u',
        title: 'Daily',
        description: '',
        startTime: start,
        endTime: start.add(const Duration(hours: 1)),
        location: '',
        isRecurring: enc.isRecurring,
        recurrenceRule: enc.recurrenceRule,
        createdAt: start,
        updatedAt: start,
      );
      expect(EventRecurrence.occursOnDay(event, DateTime(2024, 3, 10)), isTrue);
      expect(EventRecurrence.occursOnDay(event, DateTime(2024, 3, 11)), isTrue);
      expect(EventRecurrence.occursOnDay(event, DateTime(2024, 3, 12)), isTrue);
    });

    test('UNTIL excludes later days', () {
      final start = DateTime(2025, 6, 2, 10, 0);
      final enc = EventRecurrence.encode(
        frequency: RecurrenceFrequency.daily,
        startLocal: start,
        endsNever: false,
        untilLocalDate: DateTime(2025, 6, 5),
      );
      final event = EventModel(
        id: 'e2',
        userId: 'u',
        title: 'Daily',
        description: '',
        startTime: start,
        endTime: start.add(const Duration(hours: 1)),
        location: '',
        isRecurring: enc.isRecurring,
        recurrenceRule: enc.recurrenceRule,
        createdAt: start,
        updatedAt: start,
      );
      expect(
        EventRecurrence.occursOnDay(event, DateTime(2025, 6, 5)),
        isTrue,
      );
      expect(
        EventRecurrence.occursOnDay(event, DateTime(2025, 6, 6)),
        isFalse,
      );
    });

    test('yearly same month and day each year', () {
      final start = DateTime(2024, 7, 4, 9, 0);
      final enc = EventRecurrence.encode(
        frequency: RecurrenceFrequency.yearly,
        startLocal: start,
        endsNever: true,
      );
      final event = EventModel(
        id: 'e3',
        userId: 'u',
        title: 'Yearly',
        description: '',
        startTime: start,
        endTime: start.add(const Duration(hours: 1)),
        location: '',
        isRecurring: enc.isRecurring,
        recurrenceRule: enc.recurrenceRule,
        createdAt: start,
        updatedAt: start,
      );
      expect(
        EventRecurrence.occursOnDay(event, DateTime(2026, 7, 4)),
        isTrue,
      );
      expect(
        EventRecurrence.occursOnDay(event, DateTime(2026, 7, 5)),
        isFalse,
      );
    });
  });
}
