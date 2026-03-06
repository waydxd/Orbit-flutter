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

  static bool get isDebug => _environment != Environment.production;

  static String get environmentName => _environment.toString().split('.').last;
}
