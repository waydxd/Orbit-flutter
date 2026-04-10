import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_calendar/utils/ics_calendar_io.dart';

void main() {
  test('parseIcsVevents reads one VEVENT', () {
    const ics = '''
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:test@example.com
DTSTART:20240115T100000Z
DTEND:20240115T110000Z
SUMMARY:Hello
DESCRIPTION:Line1\\nLine2
LOCATION:HK
END:VEVENT
END:VCALENDAR
''';
    final list = parseIcsVevents(ics);
    expect(list.length, 1);
    expect(list.first.summary, 'Hello');
    expect(list.first.location, 'HK');
    expect(list.first.description.contains('Line1'), isTrue);
  });
}
