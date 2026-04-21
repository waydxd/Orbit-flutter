import 'dart:io' show Platform;

/// Environment configuration for different build flavors
enum Environment { local, development, staging, production }

class EnvironmentConfig {
  const EnvironmentConfig._();
  static Environment _environment = Environment.development;

  /// Direct Orbit-txt2img origin (bypasses core BFF). Example: `--dart-define=TXT2IMG_BASE_URL=https://host`
  static const String _txt2imgFromDefine = String.fromEnvironment(
    'TXT2IMG_BASE_URL',
    defaultValue: '',
  );

  /// When [TXT2IMG_BASE_URL] is empty, POST to [txt2ImgRequestPath] on [baseUrl] (default imagen BFF).
  /// Set `--dart-define=TXT2IMG_USE_CORE_PROXY=false` to disable client-side image calls without a direct URL.
  /// Override path: `--dart-define=TXT2IMG_CORE_PATH=/api/imagen/v1/text-to-image`
  static const String _txt2imgCorePath = String.fromEnvironment(
    'TXT2IMG_CORE_PATH',
    defaultValue: '/api/imagen/v1/text-to-image',
  );
  static const bool _useCoreTxt2ImgProxy = bool.fromEnvironment(
    'TXT2IMG_USE_CORE_PROXY',
    defaultValue: true,
  );

  /// Override API host for local Orbit-core (host only, no `/api/v1`). Example:
  /// `--dart-define=API_BASE_URL=http://127.0.0.1:8080` (iOS simulator / desktop)
  /// `--dart-define=API_BASE_URL=http://10.0.2.2:8080` (Android emulator → host)
  static const String _apiBaseFromDefine = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static Environment get environment => _environment;

  static void setEnvironment(Environment env) {
    _environment = env;
  }

  /// Whether the app should call image generation (direct txt2img or core BFF).
  static bool get shouldClientAttemptTxt2Img {
    if (_txt2imgFromDefine.trim().isNotEmpty) return true;
    return _useCoreTxt2ImgProxy;
  }

  /// HTTP base for Dio [BaseOptions.baseUrl].
  ///
  /// **BFF:** Use **host only** (no path suffix). The request path is [txt2ImgRequestPath] (default `/api/imagen/v1/text-to-image`).
  /// If base were `https://host/api/v1` and path were `/image/...`, Dio/`Uri.resolve` would treat the
  /// path as path-absolute and **drop** `/api/v1`, producing `https://host/image/...` (404).
  static String get txt2ImgHttpBaseUrl {
    final direct = _txt2imgFromDefine.trim();
    if (direct.isNotEmpty) {
      return direct.replaceAll(RegExp(r'/+$'), '');
    }
    return baseUrl.replaceAll(RegExp(r'/+$'), '');
  }

  /// Path for POST: `/v1/text-to-image` (direct txt2img) or BFF path from [TXT2IMG_CORE_PATH] (default `/api/imagen/v1/text-to-image`).
  static String get txt2ImgRequestPath {
    if (_txt2imgFromDefine.trim().isNotEmpty) {
      return '/v1/text-to-image';
    }
    final p = _txt2imgCorePath.trim();
    return p.isEmpty ? '/api/imagen/v1/text-to-image' : p;
  }

  /// Non-empty when [shouldClientAttemptTxt2Img] is true (legacy checks).
  static String get txt2imgBaseUrl =>
      shouldClientAttemptTxt2Img ? txt2ImgHttpBaseUrl : '';

  /// Android emulator uses 10.0.2.2 to reach host machine; iOS/desktop use localhost.
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

  static String get baseUrl {
    final override = _apiBaseFromDefine.trim();
    if (override.isNotEmpty) {
      return override.replaceAll(RegExp(r'/+$'), '');
    }
    switch (_environment) {
      case Environment.local:
        return 'http://$_localHost:8080';
      case Environment.development:
        // Shared remote backend by default; use --dart-define=API_BASE_URL=... for local Docker core.
        return 'http://vml1wk238.cse.ust.hk';
      case Environment.staging:
        return 'http://vml1wk238.cse.ust.hk';
      case Environment.production:
        return 'http://vml1wk238.cse.ust.hk';
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

  /// gRPC host for suggestion service
  static String get grpcHost {
    switch (_environment) {
      case Environment.local:
        return _localHost;
      case Environment.development:
      case Environment.staging:
      case Environment.production:
        return 'vml1wk238.cse.ust.hk';
    }
  }

  /// gRPC port for suggestion service
  static int get grpcPort {
    switch (_environment) {
      case Environment.local:
        return 50056;
      case Environment.development:
      case Environment.staging:
      case Environment.production:
        return 443;
    }
  }

  /// Whether to use TLS for the gRPC channel
  static bool get grpcSecure {
    switch (_environment) {
      case Environment.local:
        return false;
      case Environment.development:
      case Environment.staging:
      case Environment.production:
        return true;
    }
  }

  static bool get isDebug =>
      _environment == Environment.local ||
      _environment == Environment.development;

  static bool get isLocal => _environment == Environment.local;

  static String get environmentName => _environment.toString().split('.').last;
}
