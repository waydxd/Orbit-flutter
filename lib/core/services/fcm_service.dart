import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../data/services/api_client.dart';
import '../../utils/logger.dart';

/// Top-level handler for background FCM messages (must be a top-level function).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  Logger.infoWithTag('FCM', 'Background message received: ${message.messageId}');
}

/// Manages Firebase Cloud Messaging lifecycle: token registration, foreground
/// display via local notifications, and background handling.
class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  ApiClient? _apiClient;

  /// Initialize FCM. Call once at app startup after Firebase.initializeApp().
  /// [apiClient] is used to register the device token with the backend.
  Future<void> initialize({ApiClient? apiClient}) async {
    if (_initialized) return;
    _apiClient = apiClient;

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _requestPermissions();
    await _initLocalNotifications();
    await _registerToken();
    _listenForTokenRefresh();
    _listenForForegroundMessages();

    _initialized = true;
    Logger.infoWithTag('FCM', 'FCM service initialized');
  }

  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    Logger.infoWithTag(
      'FCM',
      'Notification permission: ${settings.authorizationStatus}',
    );
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'orbit_push',
        'Push Notifications',
        description: 'Orbit event & task reminders from the server',
        importance: Importance.high,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    Logger.debugWithTag('FCM', 'Notification tapped: ${response.payload}');
  }

  Future<void> _registerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        Logger.infoWithTag('FCM', 'Token obtained (length=${token.length})');
        await _sendTokenToBackend(token);
      }
    } catch (e) {
      Logger.errorWithTag('FCM', 'Failed to get FCM token', e);
    }
  }

  void _listenForTokenRefresh() {
    _messaging.onTokenRefresh.listen((newToken) async {
      Logger.infoWithTag('FCM', 'Token refreshed');
      await _sendTokenToBackend(newToken);
    });
  }

  void _listenForForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      Logger.debugWithTag('FCM', 'Foreground message: ${message.messageId}');
      _showLocalNotification(message);
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'orbit_push',
      'Push Notifications',
      channelDescription: 'Orbit event & task reminders from the server',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: message.hashCode,
      title: notification.title ?? 'Orbit',
      body: notification.body ?? '',
      notificationDetails: details,
      payload: message.data.toString(),
    );
  }

  Future<void> _sendTokenToBackend(String token) async {
    if (_apiClient == null) return;
    final platform = Platform.isIOS ? 'ios' : 'android';
    try {
      await _apiClient!.post(
        '/fcm/token',
        data: {'token': token, 'platform': platform},
      );
      Logger.infoWithTag('FCM', 'Token registered with backend');
    } catch (e) {
      Logger.errorWithTag('FCM', 'Failed to register token with backend', e);
    }
  }

  /// Unregister the current device token from the backend (e.g. on logout).
  Future<void> unregisterToken() async {
    if (_apiClient == null) return;
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _apiClient!.delete('/fcm/token', data: {'token': token});
        Logger.infoWithTag('FCM', 'Token unregistered from backend');
      }
    } catch (e) {
      Logger.errorWithTag('FCM', 'Failed to unregister token', e);
    }
  }
}
