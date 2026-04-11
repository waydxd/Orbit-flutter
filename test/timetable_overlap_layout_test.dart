import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_calendar/ui/calendar/timetable_overlap_layout.dart';

void main() {
  DateTime t(int h, [int m = 0]) => DateTime(2026, 4, 10, h, m);

  ({DateTime start, DateTime end}) iv(int h1, int m1, int h2, int m2) =>
      (start: t(h1, m1), end: t(h2, m2));

  test('empty segments yields empty layout', () {
    expect(layoutTimetableSegmentsForDay([]), isEmpty);
  });

  test('no overlap: single column', () {
    final segments = [
      iv(9, 0, 10, 0),
      iv(11, 0, 12, 0),
    ];
    final lay = layoutTimetableSegmentsForDay(segments);
    expect(lay, hasLength(2));
    expect(lay[0].column, 0);
    expect(lay[0].columnCount, 1);
    expect(lay[1].column, 0);
    expect(lay[1].columnCount, 1);
  });

  test('two simultaneous events: two columns', () {
    final segments = [
      iv(9, 0, 10, 0),
      iv(9, 0, 10, 0),
    ];
    final lay = layoutTimetableSegmentsForDay(segments);
    expect(lay, hasLength(2));
    expect(lay[0].columnCount, 2);
    expect(lay[1].columnCount, 2);
    expect({lay[0].column, lay[1].column}, {0, 1});
  });

  test('three-way overlap: three columns', () {
    final segments = [
      iv(9, 0, 11, 0),
      iv(9, 30, 10, 30),
      iv(10, 0, 11, 0),
    ];
    final lay = layoutTimetableSegmentsForDay(segments);
    expect(lay, hasLength(3));
    expect(lay[0].columnCount, 3);
    expect(lay[1].columnCount, 3);
    expect(lay[2].columnCount, 3);
    final cols = lay.map((e) => e.column).toSet();
    expect(cols.length, 3);
  });

  test('two separate overlap pairs: each cluster columnCount 2', () {
    final segments = [
      iv(9, 0, 10, 0),
      iv(9, 0, 10, 0),
      iv(14, 0, 15, 0),
      iv(14, 0, 15, 0),
    ];
    final lay = layoutTimetableSegmentsForDay(segments);
    expect(lay, hasLength(4));
    for (final l in lay) {
      expect(l.columnCount, 2);
    }
    expect({lay[0].column, lay[1].column}, {0, 1});
    expect({lay[2].column, lay[3].column}, {0, 1});
  });
}
