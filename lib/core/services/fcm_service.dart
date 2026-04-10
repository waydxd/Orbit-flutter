import 'dart:async';
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

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  ApiClient? _apiClient;

  static const Duration _getTokenTimeout = Duration(seconds: 10);

  static bool get _hasDefaultFirebaseApp => Firebase.apps.isNotEmpty;

  /// Only use after confirming [_hasDefaultFirebaseApp].
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  /// Initialize FCM. Call once at app startup after Firebase.initializeApp().
  /// [apiClient] is used to register the device token with the backend.
  Future<void> initialize({ApiClient? apiClient}) async {
    if (_initialized) return;
    if (!_hasDefaultFirebaseApp) {
      Logger.warningWithTag(
        'FCM',
        'Skipping FCM init: no default Firebase app',
      );
      return;
    }

    _apiClient = apiClient;

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _requestPermissions();
    await _initLocalNotifications();
    await _registerToken();
    _listenForTokenRefresh();
    _listenForForegroundMessages();
    _listenForNotificationOpen();

    _initialized = true;
    Logger.infoWithTag('FCM', 'FCM service initialized');
  }

  Future<void> _requestPermissions() async {
    if (!_hasDefaultFirebaseApp) return;
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

  void _logOpenedFromMessage(RemoteMessage message, String source) {
    Logger.infoWithTag(
      'FCM',
      'Opened from push ($source): id=${message.messageId} data=${message.data}',
    );
  }

  void _listenForNotificationOpen() {
    if (!_hasDefaultFirebaseApp) return;
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _logOpenedFromMessage(message, 'background');
    });
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _logOpenedFromMessage(message, 'terminated');
      }
    });
  }

  /// Re-fetch the FCM token and POST it to the backend. Call after login or
  /// when restoring a session so registration succeeds once a JWT is available.
  /// Safe to call when Firebase is not initialized (no-op).
  Future<void> registerTokenWithBackend() async {
    if (!_hasDefaultFirebaseApp) {
      Logger.debugWithTag(
        'FCM',
        'registerTokenWithBackend: no Firebase app, skipping',
      );
      return;
    }
    await _registerToken();
  }

  Future<void> _registerToken() async {
    if (!_hasDefaultFirebaseApp) return;
    try {
      final token = await _messaging.getToken().timeout(
        _getTokenTimeout,
        onTimeout: () {
          Logger.warningWithTag('FCM', 'getToken timed out');
          return null;
        },
      );
      if (token != null) {
        Logger.infoWithTag('FCM', 'Token obtained (length=${token.length})');
        await _sendTokenToBackend(token);
      }
    } catch (e) {
      Logger.errorWithTag('FCM', 'Failed to get FCM token', e);
    }
  }

  void _listenForTokenRefresh() {
    if (!_hasDefaultFirebaseApp) return;
    _messaging.onTokenRefresh.listen((newToken) async {
      Logger.infoWithTag('FCM', 'Token refreshed');
      await _sendTokenToBackend(newToken);
    });
  }

  void _listenForForegroundMessages() {
    if (!_hasDefaultFirebaseApp) return;
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

    final id = message.messageId != null
        ? message.messageId!.hashCode
        : Object.hash(
            message.sentTime?.millisecondsSinceEpoch,
            message.notification?.title,
            message.notification?.body,
          );

    await _localNotifications.show(
      id: id,
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
    if (!_hasDefaultFirebaseApp) return;
    try {
      final token = await _messaging.getToken().timeout(
        _getTokenTimeout,
        onTimeout: () => null,
      );
      if (token != null) {
        await _apiClient!.delete('/fcm/token', data: {'token': token});
        Logger.infoWithTag('FCM', 'Token unregistered from backend');
      }
    } catch (e) {
      Logger.errorWithTag('FCM', 'Failed to unregister token', e);
    }
  }
}
