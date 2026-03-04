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
  static const String huggingFaceApiKey = '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'; // Set via environment or secure storage
  static const String hfClassificationModel = 'facebook/bart-large-mnli';
  static const String hfNerModel = 'dslim/bert-base-NER';

  // NLP Server Configuration (local T5 parsing)
  static const String nlpServerBaseUrl = 'http://localhost:5001';
  // For Android emulator: 'http://10.0.2.2:5001'
  // For iOS simulator: 'http://localhost:5001'
  // For physical device: use computer's IP address
}
