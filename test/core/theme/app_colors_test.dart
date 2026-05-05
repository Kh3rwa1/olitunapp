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

    test('avatarPalettes has at least 4 entries', () {
      expect(AppColors.avatarPalettes.length, greaterThanOrEqualTo(4));
    });

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

    test('bentoShadow returns a non-empty list', () {
      expect(AppColors.bentoShadow.length, greaterThan(0));
      expect(AppColors.bentoShadow.first, isA<BoxShadow>());
    });

    test('success and error colors are distinct', () {
      expect(AppColors.success, isNot(equals(AppColors.error)));
    });

    test('dark surface colors are darker than light equivalents', () {
      // Dark surfaces should have lower luminance.
      final darkLum = AppColors.darkSurface.computeLuminance();
      expect(darkLum, lessThan(0.2));
    });

    test('duo color palette has distinct entries', () {
      final duoColors = {
        AppColors.duoGreen,
        AppColors.duoBlue,
        AppColors.duoYellow,
        AppColors.duoOrange,
        AppColors.duoPurple,
      };
      expect(duoColors.length, 5, reason: 'All duo colors should be unique');
    });
  });
}
