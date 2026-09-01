import 'package:flutter/material.dart';

/// Centralized typography definitions for Olitun.
/// Uses only two bundled font families:
/// - [fontFamilyUI] ('Inter') for all UI labels, headings, and body text.
/// - [fontFamilyScript] ('OlChiki') for Ol Chiki native script rendering.
class AppTypography {
  AppTypography._();

  static const String fontFamilyUI = 'Inter';
  static const String fontFamilyScript = 'OlChiki';
  static const List<String> fallbackFonts = [fontFamilyScript];

  /// Standard UI text styles
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamilyUI,
    fontFamilyFallback: fallbackFonts,
    fontSize: 57,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamilyUI,
    fontFamilyFallback: fallbackFonts,
    fontSize: 45,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamilyUI,
    fontFamilyFallback: fallbackFonts,
    fontSize: 36,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamilyUI,
    fontFamilyFallback: fallbackFonts,
    fontSize: 32,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamilyUI,
    fontFamilyFallback: fallbackFonts,
    fontSize: 28,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamilyUI,
    fontFamilyFallback: fallbackFonts,
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamilyUI,
    fontFamilyFallback: fallbackFonts,
    fontSize: 22,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamilyUI,
    fontFamilyFallback: fallbackFonts,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamilyUI,
    fontFamilyFallback: fallbackFonts,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamilyUI,
    fontFamilyFallback: fallbackFonts,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamilyUI,
    fontFamilyFallback: fallbackFonts,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamilyUI,
    fontFamilyFallback: fallbackFonts,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamilyUI,
    fontFamilyFallback: fallbackFonts,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamilyUI,
    fontFamilyFallback: fallbackFonts,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamilyUI,
    fontFamilyFallback: fallbackFonts,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  /// Ol Chiki native script specific typography helpers
  static const TextStyle olChikiDisplay = TextStyle(
    fontFamily: fontFamilyScript,
    fontSize: 48,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle olChikiHeading = TextStyle(
    fontFamily: fontFamilyScript,
    fontSize: 28,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle olChikiBody = TextStyle(
    fontFamily: fontFamilyScript,
    fontSize: 18,
    fontWeight: FontWeight.w400,
  );

  /// Helper to create an Inter-styled text style with custom parameters
  static TextStyle inter({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
    FontStyle? fontStyle,
  }) {
    return TextStyle(
      fontFamily: fontFamilyUI,
      fontFamilyFallback: fallbackFonts,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
      fontStyle: fontStyle,
    );
  }

  /// Helper to create an OlChiki-styled text style with custom parameters
  static TextStyle olChiki({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: fontFamilyScript,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
}
