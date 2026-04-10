import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_calendar/data/utils/event_recurrence.dart';
import 'package:orbit_calendar/data/utils/event_recurrence_materialize.dart';

void main() {
  group('materializeRecurringOccurrences', () {
    test('weekly same weekday, inclusive until', () {
      final start = DateTime(2025, 1, 6, 10, 0);
      final end = DateTime(2025, 1, 6, 11, 0);
      final until = DateTime(2025, 1, 27);
      final list = materializeRecurringOccurrences(
        frequency: RecurrenceFrequency.weekly,
        firstStart: start,
        firstEnd: end,
        untilLocalDate: until,
      );
      expect(list.length, 4);
      expect(list[0].start, start);
      expect(list[1].start, DateTime(2025, 1, 13, 10, 0));
      expect(list[2].start, DateTime(2025, 1, 20, 10, 0));
      expect(list[3].start, DateTime(2025, 1, 27, 10, 0));
      for (final o in list) {
        expect(o.end.difference(o.start), const Duration(hours: 1));
      }
    });

    test('daily three days', () {
      final start = DateTime(2025, 3, 1, 9, 0);
      final end = DateTime(2025, 3, 1, 9, 30);
      final list = materializeRecurringOccurrences(
        frequency: RecurrenceFrequency.daily,
        firstStart: start,
        firstEnd: end,
        untilLocalDate: DateTime(2025, 3, 3),
      );
      expect(list.length, 3);
      expect(list[0].start.day, 1);
      expect(list[1].start.day, 2);
      expect(list[2].start.day, 3);
    });

    test('monthly skips short months for day 31', () {
      final start = DateTime(2025, 1, 31, 14, 0);
      final end = DateTime(2025, 1, 31, 15, 0);
      final list = materializeRecurringOccurrences(
        frequency: RecurrenceFrequency.monthly,
        firstStart: start,
        firstEnd: end,
        untilLocalDate: DateTime(2025, 5, 31),
      );
      expect(list.length, 3);
      expect(list[0].start, start);
      expect(list[1].start, DateTime(2025, 3, 31, 14, 0));
      expect(list[2].start, DateTime(2025, 5, 31, 14, 0));
    });

    test('yearly lands on next leap Feb 29', () {
      final start = DateTime(2024, 2, 29, 12, 0);
      final end = DateTime(2024, 2, 29, 13, 0);
      final list = materializeRecurringOccurrences(
        frequency: RecurrenceFrequency.yearly,
        firstStart: start,
        firstEnd: end,
        untilLocalDate: DateTime(2032, 2, 29),
      );
      expect(list.length, 3);
      expect(list[0].start.year, 2024);
      expect(list[1].start, DateTime(2028, 2, 29, 12, 0));
      expect(list[2].start, DateTime(2032, 2, 29, 12, 0));
    });

    test('empty when until is before start day', () {
      final start = DateTime(2025, 6, 10, 8, 0);
      final end = DateTime(2025, 6, 10, 9, 0);
      final list = materializeRecurringOccurrences(
        frequency: RecurrenceFrequency.daily,
        firstStart: start,
        firstEnd: end,
        untilLocalDate: DateTime(2025, 6, 9),
      );
      expect(list, isEmpty);
    });

    test('single occurrence when until equals start date', () {
      final start = DateTime(2025, 4, 5, 10, 0);
      final end = DateTime(2025, 4, 5, 11, 0);
      final list = materializeRecurringOccurrences(
        frequency: RecurrenceFrequency.weekly,
        firstStart: start,
        firstEnd: end,
        untilLocalDate: DateTime(2025, 4, 5),
      );
      expect(list.length, 1);
      expect(list.single.start, start);
    });

    test('rejects never frequency', () {
      expect(
        () => materializeRecurringOccurrences(
          frequency: RecurrenceFrequency.never,
          firstStart: DateTime(2025),
          firstEnd: DateTime(2025, 1, 1, 1),
          untilLocalDate: DateTime(2025, 12, 31),
        ),
        throwsArgumentError,
      );
    });
  });

  group('EventRecurrence.until / occurrenceStartWithinRepeatEnd', () {
    test('occurrence on until calendar day is included', () {
      final untilDay = DateTime(2025, 4, 5);
      final start = DateTime(2025, 4, 5, 10, 0);
      expect(
        EventRecurrence.occurrenceStartWithinRepeatEnd(
          occurrenceStartLocal: start,
          untilLocalRepeatEndDate: untilDay,
        ),
        isTrue,
      );
    });
  });
}
