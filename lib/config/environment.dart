import 'dart:io' show Platform;

/// Environment configuration for different build flavors
enum Environment { local, development, staging, production }

class EnvironmentConfig {
  const EnvironmentConfig._();
  static Environment _environment = Environment.local;
  // static Environment _environment = Environment.development;

  static Environment get environment => _environment;

  static void setEnvironment(Environment env) {
    _environment = env;
  }

  /// Get the local host address based on platform
  /// Android emulator uses 10.0.2.2 to reach host machine
  /// iOS simulator and desktop use localhost
  static String get _localHost {
    try {
      if (Platform.isAndroid) {
        return '10.0.2.2';
      }
    } catch (_) {
      // Platform not available (web), use localhost
    }
    return 'localhost';
  }

  /// Base URL for REST API
  static String get baseUrl {
    switch (_environment) {
      case Environment.local:
        return 'http://localhost:8080';
      case Environment.development:
        // Use the shared remote backend in development to match main branch behavior
        // If you want to target a local Orbit-core instance instead, update this
        // to the appropriate host (e.g. 10.0.2.2 for Android emulator).
        return 'https://wayd.zapto.org';
      case Environment.staging:
        return 'https://wayd.zapto.org';
      case Environment.production:
        return 'https://wayd.zapto.org';
    }
  }

  /// WebSocket URL for chat streaming
  static String get wsUrl {
    switch (_environment) {
      case Environment.local:
        return 'ws://$_localHost:8080';
      case Environment.development:
        return 'wss://dev-api.orbit-calendar.com';
      case Environment.staging:
        return 'wss://staging-api.orbit-calendar.com';
      case Environment.production:
        return 'wss://api.orbit-calendar.com';
    }
  }

  static bool get isDebug =>
      _environment == Environment.local ||
      _environment == Environment.development;

  static bool get isLocal => _environment == Environment.local;
  // static bool get isDebug => _environment != Environment.production;

  static String get environmentName => _environment.toString().split('.').last;
}
