import 'package:flutter/material.dart';

/// Centralized dark theme matching the target UI: dark surface, blue accent.
class AppTheme {
  static const Color background = Color(0xFF0F1115);
  static const Color surface = Color(0xFF181B21);
  static const Color surfaceAlt = Color(0xFF22262E);
  static const Color accent = Color(0xFF5B8CFF);
  static const Color textPrimary = Color(0xFFE8EAED);
  static const Color textSecondary = Color(0xFF9AA0A6);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        surface: surface,
        background: background,
        onSurface: textPrimary,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: textPrimary),
        bodySmall: TextStyle(color: textSecondary),
        titleMedium: TextStyle(color: textPrimary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
      ),
    );
  }
}
