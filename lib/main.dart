import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Set environment
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
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const OrbitApp());
}
