import '../config/environment.dart';
import '../data/services/auth_token_service.dart';

/// API returns images in append order (oldest → newest). Detail/cover uses newest first.
List<String> newestFirstEventImageUrls(List<String> urls) {
  if (urls.length <= 1) return List<String>.from(urls);
  return urls.reversed.toList();
}

Future<Map<String, String>?> eventImageRequestHeaders(
    String absoluteUrl) async {
  if (!eventImageUrlRequiresAuth(absoluteUrl)) return {};
  final token = await AuthTokenService.getAccessToken();
  if (token == null || token.isEmpty) return {};
  return {'Authorization': 'Bearer $token'};
}

String resolveEventImageUrl(String stored) {
  final t = stored.trim();
  if (t.isEmpty) return t;
  if (t.startsWith('http://') || t.startsWith('https://')) return t;
  final base = EnvironmentConfig.baseUrl;
  return Uri.parse(base).resolve(t).toString();
}

/// Core serves event binaries at `/api/v1/assets/events/{id}` behind Bearer auth.
bool eventImageUrlRequiresAuth(String absoluteUrl) {
  final uri = Uri.tryParse(absoluteUrl);
  if (uri == null) return false;
  return uri.path.contains('/api/v1/assets/events/');
}
