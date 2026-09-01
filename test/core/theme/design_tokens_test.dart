import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/theme/app_colors.dart';
import 'package:itun/core/theme/app_radius.dart';
import 'package:itun/core/theme/app_spacing.dart';

void main() {
  group('AppSpacing Design Tokens', () {
    test('spacing scale values are ascending and non-negative', () {
      expect(AppSpacing.xxs, 2.0);
      expect(AppSpacing.xs, 4.0);
      expect(AppSpacing.sm, 8.0);
      expect(AppSpacing.md, 12.0);
      expect(AppSpacing.lg, 16.0);
      expect(AppSpacing.xl, 20.0);
      expect(AppSpacing.xxl, 24.0);
      expect(AppSpacing.xxxl, 32.0);
      expect(AppSpacing.huge, 48.0);

      expect(AppSpacing.xxs, lessThan(AppSpacing.xs));
      expect(AppSpacing.xs, lessThan(AppSpacing.sm));
      expect(AppSpacing.sm, lessThan(AppSpacing.md));
      expect(AppSpacing.md, lessThan(AppSpacing.lg));
      expect(AppSpacing.lg, lessThan(AppSpacing.xl));
      expect(AppSpacing.xl, lessThan(AppSpacing.xxl));
      expect(AppSpacing.xxl, lessThan(AppSpacing.xxxl));
      expect(AppSpacing.xxxl, lessThan(AppSpacing.huge));
    });

    test('EdgeInsets helpers match defined constants', () {
      expect(AppSpacing.edgeInsetsXs, const EdgeInsets.all(4.0));
      expect(AppSpacing.edgeInsetsSm, const EdgeInsets.all(8.0));
      expect(AppSpacing.edgeInsetsMd, const EdgeInsets.all(12.0));
      expect(AppSpacing.edgeInsetsLg, const EdgeInsets.all(16.0));
      expect(AppSpacing.edgeInsetsXl, const EdgeInsets.all(20.0));
      expect(AppSpacing.edgeInsetsXxl, const EdgeInsets.all(24.0));

      expect(
        AppSpacing.screenPadding,
        const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      );
      expect(
        AppSpacing.screenPaddingWide,
        const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      );
      expect(AppSpacing.cardPadding, const EdgeInsets.all(16.0));
    });

    test('Gap SizedBox widgets have correct dimensions', () {
      expect((AppSpacing.gapW4 as SizedBox).width, 4.0);
      expect((AppSpacing.gapW8 as SizedBox).width, 8.0);
      expect((AppSpacing.gapW12 as SizedBox).width, 12.0);
      expect((AppSpacing.gapW16 as SizedBox).width, 16.0);
      expect((AppSpacing.gapW20 as SizedBox).width, 20.0);
      expect((AppSpacing.gapW24 as SizedBox).width, 24.0);

      expect((AppSpacing.gapH4 as SizedBox).height, 4.0);
      expect((AppSpacing.gapH8 as SizedBox).height, 8.0);
      expect((AppSpacing.gapH12 as SizedBox).height, 12.0);
      expect((AppSpacing.gapH16 as SizedBox).height, 16.0);
      expect((AppSpacing.gapH20 as SizedBox).height, 20.0);
      expect((AppSpacing.gapH24 as SizedBox).height, 24.0);
      expect((AppSpacing.gapH32 as SizedBox).height, 32.0);
    });
  });

  group('AppRadius Design Tokens', () {
    test('radius scale values are ascending and positive', () {
      expect(AppRadius.xs, 4.0);
      expect(AppRadius.sm, 8.0);
      expect(AppRadius.md, 12.0);
      expect(AppRadius.lg, 16.0);
      expect(AppRadius.xl, 20.0);
      expect(AppRadius.xxl, 24.0);
      expect(AppRadius.xxxl, 28.0);
      expect(AppRadius.full, 999.0);

      expect(AppRadius.xs, lessThan(AppRadius.sm));
      expect(AppRadius.sm, lessThan(AppRadius.md));
      expect(AppRadius.md, lessThan(AppRadius.lg));
      expect(AppRadius.lg, lessThan(AppRadius.xl));
      expect(AppRadius.xl, lessThan(AppRadius.xxl));
      expect(AppRadius.xxl, lessThan(AppRadius.xxxl));
      expect(AppRadius.xxxl, lessThan(AppRadius.full));
    });

    test('BorderRadius presets have correct radii', () {
      expect(AppRadius.borderXs, BorderRadius.circular(4.0));
      expect(AppRadius.borderSm, BorderRadius.circular(8.0));
      expect(AppRadius.borderMd, BorderRadius.circular(12.0));
      expect(AppRadius.borderLg, BorderRadius.circular(16.0));
      expect(AppRadius.borderXl, BorderRadius.circular(20.0));
      expect(AppRadius.borderXxl, BorderRadius.circular(24.0));
      expect(AppRadius.borderXxxl, BorderRadius.circular(28.0));
      expect(AppRadius.borderFull, BorderRadius.circular(999.0));

      expect(
        AppRadius.topXl,
        const BorderRadius.vertical(top: Radius.circular(20.0)),
      );
      expect(
        AppRadius.topXxl,
        const BorderRadius.vertical(top: Radius.circular(24.0)),
      );
      expect(
        AppRadius.topXxxl,
        const BorderRadius.vertical(top: Radius.circular(28.0)),
      );
    });
  });

  group('AppColors Semantic Token Extensions', () {
    test('Quiz feedback surface tokens are valid and distinct', () {
      expect(AppColors.quizFeedbackSuccessDarkBg, isA<Color>());
      expect(AppColors.quizFeedbackErrorDarkBg, isA<Color>());
      expect(AppColors.quizLightSuccessSurface, isA<Color>());

      expect(
        AppColors.quizFeedbackSuccessDarkBg,
        isNot(equals(AppColors.quizFeedbackErrorDarkBg)),
      );
    });

    test('Mistake review card tokens are valid and have dark/light pairs', () {
      expect(AppColors.mistakeCardDarkTop, isA<Color>());
      expect(AppColors.mistakeCardDarkBottom, isA<Color>());
      expect(AppColors.mistakeCardLightTop, isA<Color>());
      expect(AppColors.mistakeCardLightBottom, isA<Color>());
      expect(AppColors.mistakeCardDarkBorder, isA<Color>());
      expect(AppColors.mistakeCardLightBorder, isA<Color>());

      expect(
        AppColors.mistakeCardDarkTop.computeLuminance(),
        lessThan(AppColors.mistakeCardLightTop.computeLuminance()),
      );
    });

    test('Ambient background orb tokens are valid', () {
      expect(AppColors.ambientIndigoDark, isA<Color>());
      expect(AppColors.ambientBlueOrb, isA<Color>());
      expect(AppColors.ambientIndigoOrb, isA<Color>());
      expect(AppColors.ambientPurpleOrb, isA<Color>());
    });

    test('AI translator surface tokens are valid', () {
      expect(AppColors.translatorDarkBg, isA<Color>());
      expect(AppColors.translatorDarkMid, isA<Color>());
      expect(AppColors.translatorDarkLight, isA<Color>());
      expect(AppColors.translatorLightBg, isA<Color>());
      expect(AppColors.translatorLightCardA, isA<Color>());
      expect(AppColors.translatorLightCardB, isA<Color>());
      expect(AppColors.translatorLightCardC, isA<Color>());
    });

    test(
      'Santali cultural palette and semantic accents are valid and distinct',
      () {
        expect(AppColors.santaliTerracotta, isA<Color>());
        expect(AppColors.santaliOchre, isA<Color>());
        expect(AppColors.santaliSalGreen, isA<Color>());
        expect(AppColors.santaliNightSky, isA<Color>());
        expect(AppColors.santaliEarthBlack, isA<Color>());
        expect(AppColors.santaliClayWhite, isA<Color>());

        expect(AppColors.brandBlue, isA<Color>());
        expect(AppColors.accentForest, isA<Color>());
        expect(AppColors.accentOchre, isA<Color>());
        expect(AppColors.accentTerracotta, isA<Color>());
        expect(AppColors.accentGold, isA<Color>());
        expect(AppColors.accentPurple, isA<Color>());
      },
    );
  });
}
