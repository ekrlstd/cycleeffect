import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App theme configuration with dark minimalist design.
class AppTheme {
  AppTheme._();

  // Core colors
  static const Color background = Color(0xFF060606);
  static const Color cardBackground = Color(0xFF0E0E0E);
  static const Color textPrimary = Color(0xFFFFFFFF);

  // Border gradient colors
  static const Color borderTop = Color(0xFF3A3A3A);
  static const Color borderSides = Color(0xFF1A1A1A);

  // Text with opacity variations
  static Color get textSecondary => textPrimary.withOpacity(0.7);
  static Color get textMuted => textPrimary.withOpacity(0.5);
  static Color get textSubtle => textPrimary.withOpacity(0.2);

  // Accent colors
  static const Color accentAmber = Color(0xFFFFB800);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color accentRed = Color(0xFFEF5350);

  // Legacy aliases for compatibility
  static const Color backgroundDark = background;
  static const Color cardDark = cardBackground;
  static const Color textBright = textPrimary;
  static const Color accentPurple = Color(0xFF7070a3);
  static const Color cardBackgroundAlt = cardBackground;

  // Traffic severity colors
  static const Color trafficLow = Color(0xFF4CAF50);
  static const Color trafficMedium = Color(0xFFFFA726);
  static const Color trafficHigh = Color(0xFFEF5350);

  /// Creates the dark theme for the app with Inter font.
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.dark(
        surface: cardBackground,
        primary: textPrimary,
        secondary: textPrimary.withOpacity(0.7),
      ),
      textTheme: GoogleFonts.interTextTheme(
        TextTheme(
          headlineLarge: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 32,
          ),
          headlineMedium: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
          titleLarge: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
          titleMedium: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
          bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
          bodyMedium: TextStyle(color: textPrimary, fontSize: 14),
          bodySmall: TextStyle(color: textPrimary, fontSize: 12),
          labelSmall: TextStyle(
            color: textPrimary.withOpacity(0.5),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  static ThemeData get lightTheme => darkTheme;

  // Text Styles (Direct Access)
  static TextStyle get headlineLarge => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static TextStyle get headlineMedium => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );
  
  static TextStyle get titleLarge => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static TextStyle get titleMedium => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16, 
    color: textPrimary,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14, 
    color: textPrimary,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12, 
    color: textPrimary,
  );

  static TextStyle get labelSmall => GoogleFonts.inter(
    fontSize: 11, 
    fontWeight: FontWeight.w600,
    color: textPrimary.withOpacity(0.5),
    letterSpacing: 0.5,
  );
}

/// A card container with gradient border effect.
class GradientBorderCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const GradientBorderCard({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: AppTheme.cardBackground.withOpacity(0.65),
        border: Border.all(
          color: AppTheme.borderTop.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}
