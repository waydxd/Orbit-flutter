import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Dream-space / nebula-inspired accents for hashtag chips.
/// Colors are chosen to work as filled chips (readable white or dark label).
const List<Color> _dreamSpaceAccents = [
  Color(0xFF7C6FDB), // soft violet
  Color(0xFF5B8DEF), // cosmic blue
  Color(0xFF3D9B94), // aurora teal
  Color(0xFFC75BAE), // dusk magenta
  Color(0xFFD4A84B), // star gold
  Color(0xFF6B5FC7), // deep periwinkle
  Color(0xFF8B7FD8), // lavender nebula
  Color(0xFF4A9FD4), // nebula cyan-blue
  Color(0xFF5CB3A8), // sea aurora
  Color(0xFFE078A8), // rose nebula
  Color(0xFFB56EDC), // cosmic purple
  Color(0xFF6A9FE8), // soft sky
  Color(0xFF9B8AE8), // mist violet
  Color(0xFF58A6C8), // twilight blue
];

String normalizeHashtagTag(String raw) {
  var s = raw.trim().toLowerCase();
  while (s.startsWith('#')) {
    s = s.substring(1);
  }
  return s;
}

/// Display text without leading `#` (preserves user casing).
String stripLeadingHashtagForDisplay(String raw) {
  var s = raw.trim();
  while (s.startsWith('#')) {
    s = s.substring(1);
  }
  return s;
}

/// FNV-1a 32-bit style hash — stable across app launches (unlike [String.hashCode]).
int stableHashtagHash(String normalized) {
  const int prime = 0x01000193;
  int hash = 0x811C9DC5;
  for (var i = 0; i < normalized.length; i++) {
    hash ^= normalized.codeUnitAt(i);
    hash = (hash * prime) & 0x7FFFFFFF;
  }
  return hash;
}

/// Accent for timetable blocks, location event cards, home carousel: first hashtag
/// when present; otherwise legacy title keywords; otherwise app primary.
Color accentForEventDisplay({
  required String title,
  List<String> hashtags = const [],
}) {
  if (hashtags.isNotEmpty) {
    return hashtagDreamColor(hashtags.first);
  }
  final lowerTitle = title.toLowerCase();
  if (lowerTitle.contains('math')) return const Color(0xFF50C8AA);
  if (lowerTitle.contains('english')) return const Color(0xFF8B80F0);
  if (lowerTitle.contains('history')) return const Color(0xFF0096FF);
  return AppColors.primary;
}

/// Deterministic accent for a hashtag string (raw or with `#`).
Color hashtagDreamColor(String rawTag) {
  final key = normalizeHashtagTag(rawTag);
  if (key.isEmpty) {
    return _dreamSpaceAccents[0];
  }
  final idx = stableHashtagHash(key) % _dreamSpaceAccents.length;
  return _dreamSpaceAccents[idx];
}

/// Foreground color on a solid [accent] chip background.
Color onHashtagAccentColor(Color accent) {
  return accent.computeLuminance() > 0.55
      ? const Color(0xFF1F2937)
      : Colors.white;
}

/// Muted foreground for icons on accent (e.g. close button).
Color onHashtagAccentMutedColor(Color accent) {
  return accent.computeLuminance() > 0.55
      ? const Color(0xFF1F2937).withValues(alpha: 0.65)
      : Colors.white.withValues(alpha: 0.72);
}

double hashtagSoftFillAlpha(Brightness brightness) {
  return brightness == Brightness.dark ? 0.2 : 0.14;
}

double hashtagSuggestionBorderAlpha(Brightness brightness) {
  return brightness == Brightness.dark ? 0.35 : 0.28;
}
