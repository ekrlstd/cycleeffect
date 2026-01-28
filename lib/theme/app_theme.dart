import 'package:flutter/material.dart';

/// App theme configuration using Material 3 with green color scheme.
///
/// Implements a modern, expressive design with various shades of green
/// for cards and UI elements.
class AppTheme {
  AppTheme._();

  // Primary green color palette
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF81C784);
  static const Color paleGreen = Color(0xFFE8F5E9);
  static const Color darkGreen = Color(0xFF1B5E20);

  // Card colors with various green shades
  static const Color cardBackground = Color(0xFFF1F8E9);
  static const Color cardBackgroundAlt = Color(0xFFE8F5E9);
  static const Color mapCardBackground = Color(0xFFDCEDC8);
  static const Color waveformCardBackground = Color(0xFFC8E6C9);

  // Traffic severity colors
  static const Color trafficLow = Color(0xFF4CAF50);
  static const Color trafficMedium = Color(0xFFFFA726);
  static const Color trafficHigh = Color(0xFFEF5350);

  // Text colors
  static const Color textPrimary = Color(0xFF1B5E20);
  static const Color textSecondary = Color(0xFF558B2F);
  static const Color textMuted = Color(0xFF7CB342);

  /// Creates the light theme for the app.
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryGreen,
      brightness: Brightness.light,
      primary: primaryGreen,
      secondary: lightGreen,
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: darkGreen,
      onSurface: textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: paleGreen,

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
        iconTheme: IconThemeData(color: primaryGreen),
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
        color: primaryGreen,
        size: 24,
      ),
    );
  }

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
