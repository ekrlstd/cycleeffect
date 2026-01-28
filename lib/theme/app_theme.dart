import 'package:flutter/material.dart';

/// App theme configuration using Material 3 with dark purple color scheme.
///
/// Implements a modern, sleek dark mode design with purple accents.
class AppTheme {
  AppTheme._();

  // Dark purple color palette
  static const Color backgroundDark = Color(0xFF1a1a40);
  static const Color cardDark = Color(0xFF3f3f70);
  static const Color accentPurple = Color(0xFF7070a3);
  static const Color textLight = Color(0xFFd3d3e6);
  static const Color textBright = Color(0xFFf5f5ff);

  // Card colors
  static const Color cardBackground = Color(0xFF3f3f70);
  static const Color cardBackgroundAlt = Color(0xFF2a2a50);
  static const Color mapCardBackground = Color(0xFF3f3f70);
  static const Color waveformCardBackground = Color(0xFF2a2a50);

  // Traffic severity colors
  static const Color trafficLow = Color(0xFF4CAF50);
  static const Color trafficMedium = Color(0xFFFFA726);
  static const Color trafficHigh = Color(0xFFEF5350);

  // Text colors
  static const Color textPrimary = Color(0xFFf5f5ff);
  static const Color textSecondary = Color(0xFFd3d3e6);
  static const Color textMuted = Color(0xFF7070a3);

  // Legacy aliases for compatibility
  static const Color primaryGreen = accentPurple;
  static const Color lightGreen = textLight;
  static const Color paleGreen = backgroundDark;
  static const Color darkGreen = backgroundDark;

  /// Creates the dark theme for the app.
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: accentPurple,
      brightness: Brightness.dark,
      primary: accentPurple,
      secondary: textLight,
      surface: cardDark,
      onPrimary: textBright,
      onSecondary: backgroundDark,
      onSurface: textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundDark,

      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: accentPurple),
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.zero,
      ),

      // List tile theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Text theme
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textSecondary),
        bodySmall: TextStyle(color: textMuted),
      ),

      // Icon theme
      iconTheme: IconThemeData(
        color: accentPurple,
        size: 24,
      ),

      // Floating action button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentPurple,
        foregroundColor: textBright,
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardDark,
        contentTextStyle: TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: accentPurple.withAlpha(50),
        thickness: 1,
      ),
    );
  }

  // Alias for backward compatibility
  static ThemeData get lightTheme => darkTheme;

  /// Returns the appropriate color for a traffic severity level.
  static Color colorForSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return trafficHigh;
      case 'medium':
      case 'moderate':
        return trafficMedium;
      case 'low':
      default:
        return trafficLow;
    }
  }
}
