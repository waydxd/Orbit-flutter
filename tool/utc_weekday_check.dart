import 'dart:developer' as developer;

void main() {
  final u = DateTime.utc(2025, 6, 9);
  final l = DateTime(2025, 6, 9);
  developer.log('utc $u weekday=${u.weekday}');
  developer.log('local $l weekday=${l.weekday}');
}
