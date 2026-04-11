import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'config/environment.dart';
import 'data/services/local_storage_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/fcm_service.dart';
import 'data/services/api_client.dart';
import 'utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ensure the notification channel used by the background location service exists.
  // If the service is already running, Android can crash the app if the channel is missing.
  const AndroidNotificationChannel locationChannel = AndroidNotificationChannel(
    'orbit_location_channel',
    'Orbit Location Service',
    description: 'Background location tracking for Orbit.',
    importance: Importance.low,
  );
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(locationChannel);

  // Initialize local notifications (scheduled alarms)
  await NotificationService().initialize();

  // Initialize Firebase and FCM push notifications.
  // Wrapped in try/catch so the app still launches if Firebase is not configured yet
  // (e.g. missing google-services.json / GoogleService-Info.plist).
  try {
    await Firebase.initializeApp();
    await FcmService().initialize(apiClient: ApiClient());
  } catch (e) {
    Logger.warningWithTag(
      'Main',
      'Firebase initialization skipped (not configured): $e',
    );
  }

  EnvironmentConfig.setEnvironment(Environment.development);

  // Initialize local storage
  await LocalStorageService.initialize();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      // Match main tab gradient bottom (0xFFCDC9F1) so no white strip under the app.
      systemNavigationBarColor: Color(0xFFCDC9F1),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const OrbitApp());
}
