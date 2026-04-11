import 'package:uuid/uuid.dart';

import '../data/models/event_model.dart';

/// One VEVENT worth of data parsed from an .ics file.
class ParsedIcsEvent {
  final DateTime start;
  final DateTime end;
  final String summary;
  final String description;
  final String location;
  final String? uid;
  final String rrule;

  const ParsedIcsEvent({
    required this.start,
    required this.end,
    this.summary = '',
    this.description = '',
    this.location = '',
    this.uid,
    this.rrule = '',
  });
}

String _unfoldIcsLines(String raw) {
  final lines = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
  final out = StringBuffer();
  for (final line in lines) {
    if (line.isEmpty) continue;
    if (out.isNotEmpty &&
        (line.startsWith(' ') || line.startsWith('\t')) &&
        out.toString().isNotEmpty) {
      out.write(line.substring(1));
    } else {
      if (out.isNotEmpty) out.writeln();
      out.write(line);
    }
  }
  if (out.isNotEmpty) out.writeln();
  return out.toString();
}

/// Parses ICS date/time: `YYYYMMDD`, `YYYYMMDDTHHmmss`, optional trailing `Z`.
DateTime? _parseIcsDateTime(String value) {
  final v = value.trim();
  if (v.length == 8) {
    final y = int.tryParse(v.substring(0, 4));
    final m = int.tryParse(v.substring(4, 6));
    final d = int.tryParse(v.substring(6, 8));
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }
  if (v.contains('T')) {
    final isUtc = v.endsWith('Z');
    final core = isUtc ? v.substring(0, v.length - 1) : v;
    final parts = core.split('T');
    if (parts.length != 2) return null;
    final date = parts[0];
    final time = parts[1];
    if (date.length != 8) return null;
    final y = int.tryParse(date.substring(0, 4));
    final mo = int.tryParse(date.substring(4, 6));
    final da = int.tryParse(date.substring(6, 8));
    if (y == null || mo == null || da == null) return null;
    var h = 0, mi = 0, s = 0;
    if (time.length >= 4) {
      h = int.tryParse(time.substring(0, 2)) ?? 0;
      mi = int.tryParse(time.substring(2, 4)) ?? 0;
      if (time.length >= 6) {
        s = int.tryParse(time.substring(4, 6)) ?? 0;
      }
    }
    if (isUtc) {
      return DateTime.utc(y, mo, da, h, mi, s).toLocal();
    }
    return DateTime(y, mo, da, h, mi, s);
  }
  return null;
}

String? _lineValue(String block, String propPrefix) {
  for (final line in block.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    final colon = trimmed.indexOf(':');
    if (colon <= 0) continue;
    final namePart = trimmed.substring(0, colon).toUpperCase();
    final value = trimmed.substring(colon + 1);
    if (namePart == propPrefix || namePart.startsWith('$propPrefix;')) {
      return value.replaceAll('\\n', '\n').replaceAll('\\,', ',');
    }
  }
  return null;
}

/// Parses [text] as iCalendar and returns VEVENTs (skips all-day multi-day edge cases
/// by using [DTEND] or duration default 1h).
List<ParsedIcsEvent> parseIcsVevents(String text) {
  final unfolded = _unfoldIcsLines(text);
  final events = <ParsedIcsEvent>[];
  final re = RegExp(
    r'BEGIN:VEVENT\s*(.*?)END:VEVENT',
    caseSensitive: false,
    dotAll: true,
  );
  for (final m in re.allMatches(unfolded)) {
    final block = m.group(1) ?? '';
    final dtStartRaw = _lineValue(block, 'DTSTART');
    final dtEndRaw = _lineValue(block, 'DTEND');
    if (dtStartRaw == null) continue;
    final start = _parseIcsDateTime(dtStartRaw);
    if (start == null) continue;
    DateTime end;
    if (dtEndRaw != null) {
      final parsedEnd = _parseIcsDateTime(dtEndRaw);
      end = parsedEnd ?? start.add(const Duration(hours: 1));
      if (parsedEnd != null &&
          dtEndRaw.length == 8 &&
          !dtEndRaw.contains('T')) {
        end = DateTime(parsedEnd.year, parsedEnd.month, parsedEnd.day);
        if (!end.isAfter(start)) {
          end = start.add(const Duration(hours: 1));
        }
      }
    } else {
      end = start.add(const Duration(hours: 1));
    }
    final summary = _lineValue(block, 'SUMMARY') ?? '';
    final description = _lineValue(block, 'DESCRIPTION') ?? '';
    final location = _lineValue(block, 'LOCATION') ?? '';
    final uid = _lineValue(block, 'UID');
    final rrule = (_lineValue(block, 'RRULE') ?? '').trim();
    events.add(
      ParsedIcsEvent(
        start: start,
        end: end,
        summary: summary,
        description: description,
        location: location,
        uid: uid,
        rrule: rrule.trim(),
      ),
    );
  }
  return events;
}

String _formatIcsUtc(DateTime dt) {
  final u = dt.toUtc();
  final y = u.year.toString().padLeft(4, '0');
  final mo = u.month.toString().padLeft(2, '0');
  final d = u.day.toString().padLeft(2, '0');
  final h = u.hour.toString().padLeft(2, '0');
  final mi = u.minute.toString().padLeft(2, '0');
  final s = u.second.toString().padLeft(2, '0');
  return '$y$mo${d}T$h$mi${s}Z';
}

String _escapeIcsText(String s) {
  return s
      .replaceAll('\\', '\\\\')
      .replaceAll('\n', '\\n')
      .replaceAll(',', '\\,')
      .replaceAll(';', '\\;');
}

/// Builds an iCalendar document with one VEVENT per [events] (non-recurring
/// instances only; recurrence is exported as RRULE when present).
String buildIcsDocument(
  List<EventModel> events, {
  String prodId = '-//Orbit//Orbit Calendar//EN',
}) {
  final buf = StringBuffer()
    ..writeln('BEGIN:VCALENDAR')
    ..writeln('VERSION:2.0')
    ..writeln('PRODID:$prodId')
    ..writeln('CALSCALE:GREGORIAN');
  for (final e in events) {
    buf
      ..writeln('BEGIN:VEVENT')
      ..writeln('UID:${e.id}@orbit-calendar')
      ..writeln('DTSTAMP:${_formatIcsUtc(DateTime.now().toUtc())}')
      ..writeln('DTSTART:${_formatIcsUtc(e.startTime)}')
      ..writeln('DTEND:${_formatIcsUtc(e.endTime)}')
      ..writeln('SUMMARY:${_escapeIcsText(e.title)}');
    if (e.description.isNotEmpty) {
      buf.writeln('DESCRIPTION:${_escapeIcsText(e.description)}');
    }
    if (e.location.isNotEmpty) {
      buf.writeln('LOCATION:${_escapeIcsText(e.location)}');
    }
    if (e.isRecurring && e.recurrenceRule.trim().isNotEmpty) {
      buf.writeln('RRULE:${e.recurrenceRule.trim()}');
    }
    buf.writeln('END:VEVENT');
  }
  buf.writeln('END:VCALENDAR');
  return buf.toString();
}

/// Maps a parsed ICS row to an [EventModel] ready for [CalendarRepository.createEvent].
EventModel parsedIcsToEventModel({
  required ParsedIcsEvent parsed,
  required String userId,
}) {
  final now = DateTime.now();
  final isRecurring = parsed.rrule.isNotEmpty;
  return EventModel(
    id: const Uuid().v4(),
    userId: userId,
    title: parsed.summary.isEmpty ? 'Imported event' : parsed.summary,
    description: parsed.description,
    startTime: parsed.start,
    endTime: parsed.end.isAfter(parsed.start)
        ? parsed.end
        : parsed.start.add(const Duration(hours: 1)),
    location: parsed.location,
    isRecurring: isRecurring,
    recurrenceRule: parsed.rrule,
    recurrenceException: '',
    createdAt: now,
    updatedAt: now,
  );
}
