import '../config/environment.dart';

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
