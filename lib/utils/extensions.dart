import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// String extensions
extension StringExtensions on String {
  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Check if string is email
  bool get isEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  /// Check if string is phone number
  bool get isPhoneNumber {
    return RegExp(r'^\+?[\d\s\-\(\)]{10,}$').hasMatch(this);
  }

  /// Remove all whitespace
  String get removeWhitespace {
    return replaceAll(RegExp(r'\s+'), '');
  }
}

/// DateTime extensions
extension DateTimeExtensions on DateTime {
  /// Format as date string (e.g., "Jan 15, 2025")
  String get formatDate {
    return DateFormat('MMM d, y').format(this);
  }

  /// Format as time string (e.g., "2:30 PM")
  String get formatTime {
    return DateFormat('h:mm a').format(this);
  }

  /// Format as date and time string (e.g., "Jan 15, 2025 at 2:30 PM")
  String get formatDateTime {
    return DateFormat('MMM d, y \'at\' h:mm a').format(this);
  }

  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if date is tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  /// Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Get start of day
  DateTime get startOfDay {
    return DateTime(year, month, day);
  }

  /// Get end of day
  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59, 999);
  }

  /// Get start of week (Monday)
  DateTime get startOfWeek {
    final daysFromMonday = weekday - 1;
    return subtract(Duration(days: daysFromMonday)).startOfDay;
  }

  /// Get end of week (Sunday)
  DateTime get endOfWeek {
    final daysToSunday = 7 - weekday;
    return add(Duration(days: daysToSunday)).endOfDay;
  }

  /// Get start of month
  DateTime get startOfMonth {
    return DateTime(year, month, 1);
  }

  /// Get end of month
  DateTime get endOfMonth {
    return DateTime(year, month + 1, 0, 23, 59, 59, 999);
  }
}

/// BuildContext extensions
extension BuildContextExtensions on BuildContext {
  /// Get screen size
  Size get screenSize => MediaQuery.of(this).size;

  /// Get screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Check if device is mobile
  bool get isMobile => screenWidth < 600;

  /// Check if device is tablet
  bool get isTablet => screenWidth >= 600 && screenWidth < 900;

  /// Check if device is desktop
  bool get isDesktop => screenWidth >= 900;

  /// Get theme
  ThemeData get theme => Theme.of(this);

  /// Get color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Get text theme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Show snackbar
  void showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  /// Show error snackbar
  void showErrorSnackBar(String message) {
    showSnackBar(message, backgroundColor: colorScheme.error);
  }

  /// Show success snackbar
  void showSuccessSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.green);
  }
}

/// List extensions
extension ListExtensions<T> on List<T> {
  /// Get element at index or null if out of bounds
  T? elementAtOrNull(int index) {
    if (index >= 0 && index < length) {
      return this[index];
    }
    return null;
  }

  /// Check if list is null or empty
  bool get isNullOrEmpty => isEmpty;

  /// Check if list is not null and not empty
  bool get isNotNullOrEmpty => isNotEmpty;
}
