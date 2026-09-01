import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/theme/app_theme.dart';
import 'package:itun/core/theme/app_typography.dart';

void main() {
  group('AppTypography Invariants', () {
    test('uses Inter as primary UI font family and OlChiki as fallback', () {
      expect(AppTypography.fontFamilyUI, equals('Inter'));
      expect(AppTypography.fontFamilyScript, equals('OlChiki'));
      expect(AppTypography.fallbackFonts, contains('OlChiki'));
    });

    test('inter helper generates styles with Inter and OlChiki fallback', () {
      final style = AppTypography.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.blue,
      );

      expect(style.fontFamily, equals('Inter'));
      expect(style.fontFamilyFallback, contains('OlChiki'));
      expect(style.fontSize, equals(18));
      expect(style.fontWeight, equals(FontWeight.w700));
      expect(style.color, equals(Colors.blue));
    });

    test('olChiki helper generates styles with OlChiki font family', () {
      final style = AppTypography.olChiki(
        fontSize: 24,
        fontWeight: FontWeight.w600,
      );

      expect(style.fontFamily, equals('OlChiki'));
      expect(style.fontSize, equals(24));
      expect(style.fontWeight, equals(FontWeight.w600));
    });

    test('all semantic styles have Inter font family', () {
      final styles = [
        AppTypography.displayLarge,
        AppTypography.displayMedium,
        AppTypography.displaySmall,
        AppTypography.headlineLarge,
        AppTypography.headlineMedium,
        AppTypography.headlineSmall,
        AppTypography.titleLarge,
        AppTypography.titleMedium,
        AppTypography.titleSmall,
        AppTypography.bodyLarge,
        AppTypography.bodyMedium,
        AppTypography.bodySmall,
        AppTypography.labelLarge,
        AppTypography.labelMedium,
        AppTypography.labelSmall,
      ];

      for (final style in styles) {
        expect(style.fontFamily, equals('Inter'));
        expect(style.fontFamilyFallback, contains('OlChiki'));
      }
    });

    test('AppTheme light and dark text themes use Inter font family', () {
      final lightText = AppTheme.lightTheme.textTheme;
      final darkText = AppTheme.darkTheme.textTheme;

      expect(lightText.bodyLarge?.fontFamily, equals('Inter'));
      expect(lightText.bodyMedium?.fontFamily, equals('Inter'));
      expect(lightText.titleLarge?.fontFamily, equals('Inter'));
      expect(lightText.headlineSmall?.fontFamily, equals('Inter'));

      expect(darkText.bodyLarge?.fontFamily, equals('Inter'));
      expect(darkText.bodyMedium?.fontFamily, equals('Inter'));
      expect(darkText.titleLarge?.fontFamily, equals('Inter'));
      expect(darkText.headlineSmall?.fontFamily, equals('Inter'));
    });
  });
}
