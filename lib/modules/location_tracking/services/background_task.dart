import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/gps_fix.dart';
import '../storage/location_storage.dart';
import '../algorithm/stay_point_detector.dart';
import 'location_api_service.dart';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // Initialize Hive in background
  await Hive.initFlutter();
  await LocationStorage.init();

  final detector = StayPointDetector();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Start polling GPS every 45 seconds (between 30-60 as requested)
  Timer.periodic(const Duration(seconds: 45), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: "Orbit Location Service",
          content: "Tracking location for smart calendar...",
        );
      }
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }

      // Get location
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      // Discard noise > 50m
      if (position.accuracy > 50.0) return;

      final fix = GpsFix(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
      );

      await LocationStorage.saveGpsFix(fix);

      // Process stay points
      _processStayPoints(detector);
    } catch (e) {
      print("Error in background location task: $e");
    }
  });
}

Future<void> _processStayPoints(StayPointDetector detector) async {
  // We need both the keys and values to delete them later
  final box = Hive.box<GpsFix>(LocationStorage.gpsBoxName);
  
  if (box.isEmpty) return;

  // Sorting keys by timestamp to maintain chronological order
  var entries = box.toMap().entries.toList();
  entries.sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));

  List<GpsFix> fixes = entries.map((e) => e.value).toList();
  List<dynamic> keys = entries.map((e) => e.key).toList();

  final (stayPoints, processedKeys) = detector.detect(fixes, keys);

  for (var sp in stayPoints) {
    await LocationStorage.saveStayPoint(sp);
    print("Detected Stay Point: \${sp.centroidLat}, \${sp.centroidLon} for \${sp.dwellDurationMinutes} mins");
    
    // Sync to backend
    await LocationApiService.syncStayPoint(sp);
  }

  if (processedKeys.isNotEmpty) {
    await LocationStorage.removeGpsFixes(processedKeys);
  }
}
