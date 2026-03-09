import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'background_task.dart';

class LocationTrackingService {
  static final LocationTrackingService _instance =
      LocationTrackingService._internal();

  factory LocationTrackingService() => _instance;

  LocationTrackingService._internal();

  Future<void> initialize(BuildContext context) async {
    bool hasPermissions = await _requestPermissions(context);
    if (hasPermissions) {
      await _initBackgroundService();
    }
  }

  Future<bool> _requestPermissions(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showErrorDialog(context,
          'Location services are disabled. Please enable them in settings.');
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showErrorDialog(context,
            'Location permissions are denied. The app needs location access to track your habits.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showErrorDialog(context,
          'Location permissions are permanently denied, we cannot request permissions. Please open app settings to enable them.',
          isPermanent: true);
      return false;
    }

    // Request "Always" permission for background tracking
    if (permission == LocationPermission.whileInUse) {
      // In iOS and Android 11+, we need to request "Always" separately after "While in use"
      var alwaysPermission = await Permission.locationAlways.request();
      if (alwaysPermission.isDenied || alwaysPermission.isPermanentlyDenied) {
        _showErrorDialog(context,
            'Background location access is required for stay-point detection. Please select "Allow all the time" in settings.',
            isPermanent: true);
        return false;
      }
    }

    return true;
  }

  void _showErrorDialog(BuildContext context, String message,
      {bool isPermanent = false}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            if (isPermanent)
              TextButton(
                child: const Text('Open Settings'),
                onPressed: () {
                  openAppSettings();
                  Navigator.of(context).pop();
                },
              ),
          ],
        );
      },
    );
  }

  Future<void> _initBackgroundService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'orbit_location_channel',
        initialNotificationTitle: 'Orbit Location Service',
        initialNotificationContent: 'Initializing',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    service.startService();
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  // iOS specific background execution if needed
  return true;
}
