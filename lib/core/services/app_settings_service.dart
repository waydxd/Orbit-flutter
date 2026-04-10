import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService {
  static final AppSettingsService _instance = AppSettingsService._internal();
  factory AppSettingsService() => _instance;
  AppSettingsService._internal();

  static const _keyTimezoneId = 'settings.timeDate.timezoneId';
  static const _keyEventNotificationsEnabled =
      'settings.notifications.eventsEnabled';
  static const _keyTaskNotificationsEnabled =
      'settings.notifications.tasksEnabled';
  static const _keyGpsTrackingEnabled = 'settings.gps.trackingEnabled';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<String?> getTimezoneId() async {
    final prefs = await _prefs;
    final value = prefs.getString(_keyTimezoneId);
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }

  Future<void> setTimezoneId(String? timezoneId) async {
    final prefs = await _prefs;
    final value = timezoneId?.trim() ?? '';
    if (value.isEmpty) {
      await prefs.remove(_keyTimezoneId);
      return;
    }
    await prefs.setString(_keyTimezoneId, value);
  }

  /// Helpful for onboarding/registration: set only if user hasn't picked one yet.
  Future<void> setTimezoneIdIfUnset(String? timezoneId) async {
    final prefs = await _prefs;
    if (prefs.containsKey(_keyTimezoneId)) return;
    final value = timezoneId?.trim() ?? '';
    if (value.isEmpty) return;
    await prefs.setString(_keyTimezoneId, value);
  }

  Future<bool> getEventNotificationsEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyEventNotificationsEnabled) ?? true;
  }

  Future<void> setEventNotificationsEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyEventNotificationsEnabled, enabled);
  }

  Future<bool> getTaskNotificationsEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyTaskNotificationsEnabled) ?? true;
  }

  Future<void> setTaskNotificationsEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyTaskNotificationsEnabled, enabled);
  }

  Future<bool> getGpsTrackingEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyGpsTrackingEnabled) ?? false;
  }

  Future<void> setGpsTrackingEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyGpsTrackingEnabled, enabled);
  }
}

