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
        return 'https://dev-api.orbit-calendar.com';
      case Environment.staging:
        return 'https://staging-api.orbit-calendar.com';
      case Environment.production:
        return 'https://api.orbit-calendar.com';
    }
  }

  static bool get isDebug => _environment != Environment.production;

  static String get environmentName => _environment.toString().split('.').last;
}
