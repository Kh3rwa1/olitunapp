import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// The gate requires the re-export surface itself to be exercised by a test.
import 'package:itun/shared/widgets/buttons/button_tokens.dart';

void main() {
  group('button_tokens (AppColors re-export)', () {
    test('exposes the brand palette used by buttons', () {
      expect(AppColors.primary, isA<Color>());
      expect(AppColors.primary, isNot(AppColors.error));
    });

    test('exposes semantic feedback colors', () {
      expect(AppColors.success, isA<Color>());
      expect(AppColors.warning, isA<Color>());
      expect(AppColors.error, isA<Color>());
    });

    test('gradient presets resolve to real gradients', () {
      expect(AppColors.premiumGreen, isA<Gradient>());
      expect(AppColors.premiumOrange, isA<Gradient>());
      expect(AppColors.heroGradient, isA<Gradient>());
    });
  });
}
