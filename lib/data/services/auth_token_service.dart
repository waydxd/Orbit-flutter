import '../../config/app_config.dart';
import 'local_storage_service.dart';

/// Reads the Orbit-core JWT persisted after login/register.
class AuthTokenService {
  const AuthTokenService._();

  /// Current access token, or null if missing or blank (after trim).
  static Future<String?> getAccessToken() async {
    final raw = await LocalStorageService.getSecure(AppConfig.accessTokenKey);
    final t = raw?.trim();
    if (t == null || t.isEmpty) return null;
    return t;
  }

  /// Token only (no `Bearer ` prefix) for assembling `Authorization: Bearer …`.
  static Future<String?> getBearerHeaderValue() => getAccessToken();
}
