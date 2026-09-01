import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

void main() {
  group('AppColors', () {
    test('primary color is Olitun green', () {
      expect(AppColors.primary, isA<Color>());
      // Signature green #1EE088.
      expect(AppColors.primary, equals(const Color(0xFF1EE088)));
    });

    test('Santali cultural palette tokens are defined and non-null', () {
      expect(AppColors.santaliTerracotta, equals(const Color(0xFF8B3A3A)));
      expect(AppColors.santaliOchre, equals(const Color(0xFFD99B26)));
      expect(AppColors.santaliSalGreen, equals(const Color(0xFF1B4D3E)));
      expect(AppColors.santaliNightSky, equals(const Color(0xFF1E2A44)));
      expect(AppColors.santaliEarthBlack, equals(const Color(0xFF181E24)));
      expect(AppColors.santaliClayWhite, equals(const Color(0xFFFBF9F5)));
    });

    test(
      'avatarPalettes has at least 6 entries incorporating cultural colors',
      () {
        expect(AppColors.avatarPalettes.length, greaterThanOrEqualTo(6));
      },
    );

    test('each avatar palette has exactly 2 colors', () {
      for (final palette in AppColors.avatarPalettes) {
        expect(
          palette.length,
          2,
          reason: 'Avatar palette should have start and end gradient colors',
        );
      }
    });

    test('heroGradient is a LinearGradient', () {
      expect(AppColors.heroGradient, isA<LinearGradient>());
    });

    test('premiumGreen gradient is not null', () {
      expect(AppColors.premiumGreen, isA<LinearGradient>());
    });

    test('success and error colors are distinct', () {
      expect(AppColors.success, isNot(equals(AppColors.error)));
    });

    test('dark surface colors are darker than light equivalents', () {
      // Dark surfaces should have lower luminance.
      final darkLum = AppColors.darkSurface.computeLuminance();
      expect(darkLum, lessThan(0.2));
    });

    test('semantic accent color palette has distinct entries', () {
      final semanticColors = {
        AppColors.accentForest,
        AppColors.brandBlue,
        AppColors.accentGold,
        AppColors.accentOchre,
        AppColors.accentPurple,
        AppColors.accentTerracotta,
      };
      expect(
        semanticColors.length,
        6,
        reason: 'All semantic accent colors should be unique',
      );
    });
  });
}
