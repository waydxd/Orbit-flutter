import 'package:flutter/material.dart';

/// Application constants
class Constants {
  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Border radius
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;
  static const double radiusXXL = 24.0;

  // Icon sizes
  static const double iconS = 16.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 48.0;

  // Breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1200.0;

  // Calendar
  static const int daysInWeek = 7;
  static const int maxWeeksInMonth = 6;
  static const int hoursInDay = 24;
  static const int minutesInHour = 60;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // File sizes
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
  static const int maxDocumentSizeBytes = 10 * 1024 * 1024; // 10MB

  // UI Dimensions
  static const double loginFormWidth = 324.0;
  static const double loginFormHeight = 457.0;
  static const double splashIconSize = 80.0;
  static const double homeIconSize = 64.0;
  static const double buttonHeight = 14.0;
  static const double textFieldHeight = 14.0;

  // Font sizes
  static const double fontSizeXS = 11.0;
  static const double fontSizeS = 14.0;
  static const double fontSizeM = 16.0;
  static const double fontSizeL = 24.0;
  static const double fontSizeXL = 32.0;

  // Font weights
  static const FontWeight fontWeightNormal = FontWeight.w500;
  static const FontWeight fontWeightBold = FontWeight.bold;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;

  // Opacity values
  static const double opacityLight = 0.44;
  static const double opacityMedium = 0.22;
  static const double opacityHigh = 0.7;

  // Shadow values
  static const double shadowBlurRadius = 100.0;
  static const double shadowOffset = 40.0;
  static const double shadowOpacity = 0.2;

  // Authentication
  static const String testEmail = 'test@example.com';
  static const String testPassword = 'Password123';
  static const String mockAccessToken = 'mock_access_token';
  static const String mockRefreshToken = 'mock_refresh_token';
}
