/// Google Maps Platform API key shared by Places, Distance Matrix, and the
/// native Maps SDK (AndroidManifest / iOS AppDelegate).
abstract final class MapsPlatformConfig {
  static const String apiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyDY_Fu5bhGPf2ZHXZF3pCxOHxnbv9ymnVA',
  );
}
