import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'config/environment.dart';
import 'data/services/local_storage_service.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  await NotificationService().initialize();

  // Set environment
  // EnvironmentConfig.setEnvironment(Environment.local);
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
