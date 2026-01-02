import 'dart:developer' as developer;
import '../config/environment.dart';

/// Application logger utility
class Logger {
  const Logger._();
  static const String _name = 'Orbit';

  /// Log debug message
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (EnvironmentConfig.isDebug) {
      developer.log(
        message,
        name: _name,
        level: 500, // Debug level
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Log info message
  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: _name,
      level: 800, // Info level
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log warning message
  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: _name,
      level: 900, // Warning level
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log error message
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: _name,
      level: 1000, // Error level
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log error message with tag
  static void errorWithTag(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    developer.log(
      '[$tag] $message',
      name: _name,
      level: 1000, // Error level
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log warning message with tag
  static void warningWithTag(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    developer.log(
      '[$tag] $message',
      name: _name,
      level: 900, // Warning level
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log info message with tag
  static void infoWithTag(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    developer.log(
      '[$tag] $message',
      name: _name,
      level: 800, // Info level
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log debug message with tag
  static void debugWithTag(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (EnvironmentConfig.isDebug) {
      developer.log(
        '[$tag] $message',
        name: _name,
        level: 500, // Debug level
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Log API request
  static void apiRequest(
    String method,
    String url, [
    Map<String, dynamic>? data,
  ]) {
    if (EnvironmentConfig.isDebug) {
      debug('API Request: $method $url${data != null ? '\nData: $data' : ''}');
    }
  }

  /// Log API response
  static void apiResponse(
    String method,
    String url,
    int statusCode, [
    dynamic data,
  ]) {
    if (EnvironmentConfig.isDebug) {
      debug(
        'API Response: $method $url - $statusCode${data != null ? '\nData: $data' : ''}',
      );
    }
  }

  /// Log navigation
  static void navigation(String from, String to) {
    if (EnvironmentConfig.isDebug) {
      debug('Navigation: $from -> $to');
    }
  }

  /// Log user action
  static void userAction(String action, [Map<String, dynamic>? data]) {
    if (EnvironmentConfig.isDebug) {
      debug('User Action: $action${data != null ? '\nData: $data' : ''}');
    }
  }
}
