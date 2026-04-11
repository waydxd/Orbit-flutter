/// Application configuration constants
class AppConfig {
  static const String appName = 'Orbit';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String baseUrl = 'https://wayd.zapto.org';
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

  // Hugging Face API Configuration
  static const String huggingFaceBaseUrl = 'https://router.huggingface.co';
  static const String huggingFaceApiKey = String.fromEnvironment(
      'HUGGING_FACE_API_KEY',
      defaultValue: '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');
  static const String hfClassificationModel = 'facebook/bart-large-mnli';

  // Remote NLP Server Configuration
  // Note: `NlpService` appends `parse/event` and `parse/task` to this base URL.
  // NLP parse endpoints use the same JWT Bearer token issued at login (Orbit-core).
  // Local: `--dart-define=NLP_SERVER_BASE_URL=http://127.0.0.1:5001/api/nlp/` (trailing slash ok)
  static const String nlpServerBaseUrl = String.fromEnvironment(
    'NLP_SERVER_BASE_URL',
    defaultValue: 'https://wayd.zapto.org/api/nlp/',
  );
}
