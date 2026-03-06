import 'package:hive/hive.dart';

part 'gps_fix.g.dart';

@HiveType(typeId: 1)
class GpsFix extends HiveObject {
  @HiveField(0)
  final double latitude;

  @HiveField(1)
  final double longitude;

  @HiveField(2)
  final double accuracy;

  @HiveField(3)
  final DateTime timestamp;

  GpsFix({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
  });
}
