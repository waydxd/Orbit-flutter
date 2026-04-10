void main() {
  final u = DateTime.utc(2025, 6, 9);
  final l = DateTime(2025, 6, 9);
  print('utc $u weekday=${u.weekday}');
  print('local $l weekday=${l.weekday}');
}
