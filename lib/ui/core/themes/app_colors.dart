import 'package:flutter/material.dart';

/// Application color palette
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);
  
  // Secondary Colors
  static const Color secondary = Color(0xFF10B981);
  static const Color secondaryLight = Color(0xFF34D399);
  static const Color secondaryDark = Color(0xFF059669);
  
  // Accent Colors
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentLight = Color(0xFFFBBF24);
  static const Color accentDark = Color(0xFFD97706);
  
  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey50 = Color(0xFFF9FAFB);
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey800 = Color(0xFF1F2937);
  static const Color grey900 = Color(0xFF111827);
  
  // Semantic Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFFD1D5DB);
  static const Color textTertiaryDark = Color(0xFF9CA3AF);
  
  // Surface Colors (replacing deprecated background)
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF111827);
  static const Color surfaceLight = Color(0xFFF9FAFB);
  static const Color surfaceDark = Color(0xFF1F2937);
  
  // Neumorphic Colors
  static const Color neumorphicLight = Color(0xFFE0E5EC);
  static const Color neumorphicDark = Color(0xFF2E3440);
  static const Color neumorphicShadowLight = Color(0xFFA3B1C6);
  static const Color neumorphicShadowDark = Color(0xFF1A1F2B);
  static const Color neumorphicHighlightLight = Color(0xFFFFFFFF);
  static const Color neumorphicHighlightDark = Color(0xFF3E4A59);
  
  // Color Schemes
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: white,
    secondary: secondary,
    onSecondary: white,
    tertiary: accent,
    onTertiary: white,
    error: error,
    onError: white,
    surface: surfaceLight,
    onSurface: textPrimary,
    outline: grey300,
    outlineVariant: grey200,
    shadow: grey400,
    scrim: black,
    inverseSurface: grey800,
    onInverseSurface: white,
    inversePrimary: primaryLight,
    surfaceTint: primary,
  );
  
  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: primaryLight,
    onPrimary: black,
    secondary: secondaryLight,
    onSecondary: black,
    tertiary: accentLight,
    onTertiary: black,
    error: error,
    onError: white,
    surface: surfaceDark,
    onSurface: textPrimaryDark,
    outline: grey600,
    outlineVariant: grey700,
    shadow: black,
    scrim: black,
    inverseSurface: grey200,
    onInverseSurface: black,
    inversePrimary: primaryDark,
    surfaceTint: primaryLight,
  );
}