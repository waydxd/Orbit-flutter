import 'package:hive_flutter/hive_flutter.dart';
import '../models/gps_fix.dart';
import '../models/stay_point.dart';

class LocationStorage {
  static const String gpsBoxName = 'gps_fixes';
  static const String stayPointBoxName = 'stay_points';

  static Future<void> init() async {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(GpsFixAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(StayPointAdapter());
    }
    await Hive.openBox<GpsFix>(gpsBoxName);
    await Hive.openBox<StayPoint>(stayPointBoxName);
  }

  static Box<GpsFix> get _gpsBox => Hive.box<GpsFix>(gpsBoxName);
  static Box<StayPoint> get _stayPointBox => Hive.box<StayPoint>(stayPointBoxName);

  static Future<void> saveGpsFix(GpsFix fix) async {
    await _gpsBox.add(fix);
  }

  static List<GpsFix> getUnprocessedFixes() {
    // Return fixes sorted by timestamp
    final fixes = _gpsBox.values.toList();
    fixes.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return fixes;
  }

  static Future<void> removeGpsFixes(Iterable<dynamic> keys) async {
    await _gpsBox.deleteAll(keys);
  }

  static Future<void> clearAllGpsFixes() async {
    await _gpsBox.clear();
  }

  static Future<void> saveStayPoint(StayPoint stayPoint) async {
    await _stayPointBox.put(stayPoint.id, stayPoint);
  }

  static List<StayPoint> getAllStayPoints() {
    return _stayPointBox.values.toList();
  }
}
