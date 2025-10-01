import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local storage service for managing Hive boxes and secure storage
class LocalStorageService {
  const LocalStorageService._();
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static SharedPreferences? _prefs;

  /// Initialize local storage
  static Future<void> initialize() async {
    await Hive.initFlutter();
    _prefs = await SharedPreferences.getInstance();

    // Register Hive adapters here when models are created
    // Hive.registerAdapter(UserAdapter());
    // Hive.registerAdapter(EventAdapter());
    // Hive.registerAdapter(TaskAdapter());
  }

  /// Open a Hive box
  static Future<Box<T>> openBox<T>(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<T>(boxName);
    }
    return await Hive.openBox<T>(boxName);
  }

  /// Close a Hive box
  static Future<void> closeBox(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      await Hive.box(boxName).close();
    }
  }

  /// Clear all local data
  static Future<void> clearAll() async {
    await Hive.deleteFromDisk();
    await _secureStorage.deleteAll();
    await _prefs?.clear();
  }

  // Secure Storage Methods

  /// Store secure value
  static Future<void> storeSecure(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  /// Get secure value
  static Future<String?> getSecure(String key) async {
    return await _secureStorage.read(key: key);
  }

  /// Delete secure value
  static Future<void> deleteSecure(String key) async {
    await _secureStorage.delete(key: key);
  }

  // Shared Preferences Methods

  /// Store preference value
  static Future<bool> setPreference<T>(String key, T value) async {
    if (value is String) {
      return await _prefs!.setString(key, value);
    } else if (value is int) {
      return await _prefs!.setInt(key, value);
    } else if (value is double) {
      return await _prefs!.setDouble(key, value);
    } else if (value is bool) {
      return await _prefs!.setBool(key, value);
    } else if (value is List<String>) {
      return await _prefs!.setStringList(key, value);
    }
    return false;
  }

  /// Get preference value
  static T? getPreference<T>(String key) {
    return _prefs?.get(key) as T?;
  }

  /// Remove preference
  static Future<bool> removePreference(String key) async {
    return await _prefs!.remove(key);
  }
}
