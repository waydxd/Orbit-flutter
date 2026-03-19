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
  static const String huggingFaceApiKey = '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';
  static const String hfClassificationModel = 'facebook/bart-large-mnli';


  // Remote NLP Server Configuration
  // Note: `NlpService` appends `parse/event` and `parse/task` to this base URL.
  static const String nlpServerBaseUrl = 'https://wayd.zapto.org/api/nlp/';

  // Dev-only bearer token for the protected NLP parse endpoints.
  static const String nlpParseBearerTokenDev = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6Inp3dWNiQGNvbm5lY3QudXN0LmhrIiwiZXhwIjoxNzc0MDI5MzA1LCJpYXQiOjE3NzM5NDI5MDUsImlkIjoiNzg5YjNmMzQtMGQ5Yi00YTQ4LWE4MzAtNTg3NjQ3MzgyNTlhIn0.PG8IRF-NICOOZo76MdwCMY_aNJWX3p4M3aT0RYiMwoY';
}
