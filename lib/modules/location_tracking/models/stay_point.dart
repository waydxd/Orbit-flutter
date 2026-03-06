import 'package:hive/hive.dart';

part 'stay_point.g.dart';

@HiveType(typeId: 2)
class StayPoint extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double centroidLat;

  @HiveField(2)
  final double centroidLon;

  @HiveField(3)
  final DateTime arrivalTime;

  @HiveField(4)
  final DateTime departureTime;

  @HiveField(5)
  final int dwellDurationMinutes;

  @HiveField(6)
  final String? label;

  StayPoint({
    required this.id,
    required this.centroidLat,
    required this.centroidLon,
    required this.arrivalTime,
    required this.departureTime,
    required this.dwellDurationMinutes,
    this.label,
  });
}
