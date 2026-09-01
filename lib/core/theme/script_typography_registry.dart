import 'package:flutter/material.dart';

import '../languages/language_registry.dart';
import 'app_typography.dart';

class ScriptTypographyRegistry {
  const ScriptTypographyRegistry._();

  /// Resolves the recommended font family for a given language code.
  static String getFontFamily(String languageCode) {
    final manifest = LanguageRegistry.findByCode(languageCode);
    return manifest.primaryFontFamily;
  }

  /// Resolves font fallback list for a given language code.
  static List<String> getFontFallbacks(String languageCode) {
    final manifest = LanguageRegistry.findByCode(languageCode);
    return manifest.fallbackFontFamilies;
  }

  /// Builds a [TextStyle] tailored for the target script/language.
  static TextStyle getStyle({
    required String languageCode,
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    final manifest = LanguageRegistry.findByCode(languageCode);
    if (manifest.scriptCode == 'olck' ||
        manifest.primaryFontFamily == 'OlChiki') {
      return AppTypography.olChiki(
        fontSize: fontSize ?? 16,
        fontWeight: fontWeight ?? FontWeight.w700,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    }

    return AppTypography.inter(
      fontSize: fontSize ?? 14,
      fontWeight: fontWeight ?? FontWeight.w500,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
}
