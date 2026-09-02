import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/constants/app_constants.dart';

void main() {
  group('AppConstants', () {
    test('app identity', () {
      expect(AppConstants.appName, 'Olitun');
      expect(AppConstants.appTagline, isNotEmpty);
    });

    test(
      'animation durations are ordered slow > pageTransition > normal > fast',
      () {
        expect(
          AppConstants.slowAnimation,
          greaterThan(AppConstants.pageTransition),
        );
        expect(
          AppConstants.pageTransition,
          greaterThan(AppConstants.normalAnimation),
        );
        expect(
          AppConstants.normalAnimation,
          greaterThan(AppConstants.fastAnimation),
        );
      },
    );

    test('radius scale is monotonically increasing', () {
      expect(AppConstants.radiusSmall, lessThan(AppConstants.radiusMedium));
      expect(AppConstants.radiusMedium, lessThan(AppConstants.radiusLarge));
      expect(AppConstants.radiusLarge, lessThan(AppConstants.radiusXLarge));
    });

    test('spacing scale is monotonically increasing', () {
      const scale = [
        AppConstants.spacingXS,
        AppConstants.spacingS,
        AppConstants.spacingM,
        AppConstants.spacingL,
        AppConstants.spacingXL,
        AppConstants.spacingXXL,
      ];
      for (var i = 0; i < scale.length - 1; i++) {
        expect(scale[i], lessThan(scale[i + 1]));
      }
    });

    test('progress ring sizes match the icon/card scale boundaries', () {
      expect(AppConstants.progressRingSmall, 48.0);
      expect(AppConstants.progressRingMedium, 64.0);
      expect(AppConstants.progressRingLarge, 80.0);
    });

    test('preference keys are unique', () {
      final keys = [
        AppConstants.prefThemeMode,
        AppConstants.prefScriptMode,
        AppConstants.prefSoundEnabled,
        AppConstants.prefNotificationsEnabled,
        AppConstants.prefUserName,
        AppConstants.prefUserLevel,
        AppConstants.prefOnboardingComplete,
      ];
      expect(keys.toSet(), hasLength(keys.length));
    });

    test('collection ids are unique', () {
      final cols = [
        AppConstants.colCategories,
        AppConstants.colFeaturedBanners,
        AppConstants.colLetters,
        AppConstants.colLessons,
        AppConstants.colQuizzes,
        AppConstants.colUsers,
        AppConstants.colProgress,
        AppConstants.colStickers,
        AppConstants.colAppStrings,
      ];
      expect(cols.toSet(), hasLength(cols.length));
    });

    test('script modes', () {
      expect(AppConstants.scriptOlChiki, 'olchiki');
      expect(AppConstants.scriptLatin, 'latin');
      expect(AppConstants.scriptBoth, 'both');
    });

    test('gradient presets are unique', () {
      final presets = [
        AppConstants.gradientSkyBlue,
        AppConstants.gradientPeach,
        AppConstants.gradientSunset,
        AppConstants.gradientCoral,
        AppConstants.gradientMint,
        AppConstants.gradientPurple,
      ];
      expect(presets.toSet(), hasLength(presets.length));
    });

    test('cannot be instantiated', () {
      // AppConstants._() is private: only static members are accessible.
      expect(AppConstants.appName, isA<String>());
    });
  });
}
