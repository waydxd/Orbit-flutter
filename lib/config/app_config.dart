/// Application configuration constants
class AppConfig {
  static const String appName = 'Orbit';
  static const String appVersion = '1.0.0';
  
  // API Configuration
  static const String baseUrl = 'https://api.orbit-calendar.com';
  static const String apiVersion = 'v1';
  
  // Local Storage Keys
  static const String userBoxKey = 'user_box';
  static const String eventBoxKey = 'event_box';
  static const String taskBoxKey = 'task_box';
  static const String settingsBoxKey = 'settings_box';
  
  // Secure Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  
  // Feature Flags
  static const bool enableAIFeatures = true;
  static const bool enableLocationFeatures = true;
  static const bool enableNotifications = true;
  
  // Timeouts
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration syncInterval = Duration(minutes: 15);
}