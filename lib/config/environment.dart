/// Environment configuration for different build flavors
enum Environment { development, staging, production }

class EnvironmentConfig {
  const EnvironmentConfig._();
  static Environment _environment = Environment.development;

  static Environment get environment => _environment;

  static void setEnvironment(Environment env) {
    _environment = env;
  }

  static String get baseUrl {
    switch (_environment) {
      case Environment.development:
        // Use localhost for iOS simulator and web, 10.0.2.2 for Android emulator
        return 'http://localhost:8080';
      case Environment.staging:
        return 'https://wayd.zapto.org';
      case Environment.production:
        return 'https://wayd.zapto.org';
    }
  }

  static bool get isDebug => _environment != Environment.production;

  static String get environmentName => _environment.toString().split('.').last;
}
