import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/accessibility/wcag_audit.dart';
import 'package:itun/core/theme/app_colors.dart';

void main() {
  group('WCAG 2.2 AA Theme Contrast Compliance', () {
    test(
      'elevated button foreground passes normal text contrast on primary green',
      () {
        const buttonForeground = Color(0xFF00391C);
        const buttonBackground = AppColors.primary; // #1EE088
        final ratio = WcagAudit.contrastRatio(
          buttonForeground,
          buttonBackground,
        );
        expect(
          ratio,
          greaterThanOrEqualTo(WcagAudit.normalTextContrast),
          reason:
              'Button text on primary ($ratio:1) must meet WCAG AA normal text ≥ 4.5:1',
        );
      },
    );

    test(
      'dark theme primary text passes normal text contrast on dark background',
      () {
        const foreground = AppColors.textPrimaryDark;
        const background = AppColors.darkBackground;
        final ratio = WcagAudit.contrastRatio(foreground, background);
        expect(
          ratio,
          greaterThanOrEqualTo(WcagAudit.normalTextContrast),
          reason: 'Dark theme primary text ($ratio:1) must meet ≥ 4.5:1',
        );
      },
    );

    test(
      'light theme primary text passes normal text contrast on light background',
      () {
        const foreground = AppColors.textPrimaryLight;
        const background = AppColors.lightBackground;
        final ratio = WcagAudit.contrastRatio(foreground, background);
        expect(
          ratio,
          greaterThanOrEqualTo(WcagAudit.normalTextContrast),
          reason: 'Light theme primary text ($ratio:1) must meet ≥ 4.5:1',
        );
      },
    );

    test(
      'Santali terracotta accent passes normal text contrast on light surface',
      () {
        const foreground = AppColors.santaliTerracotta; // #8B3A3A
        const background = AppColors.lightSurface; // #FFFFFF
        final ratio = WcagAudit.contrastRatio(foreground, background);
        expect(
          ratio,
          greaterThanOrEqualTo(WcagAudit.normalTextContrast),
          reason:
              'Santali terracotta text ($ratio:1) on white must meet ≥ 4.5:1',
        );
      },
    );

    test(
      'Santali Sal green accent passes normal text contrast on light surface',
      () {
        const foreground = AppColors.santaliSalGreen; // #1B4D3E
        const background = AppColors.lightSurface; // #FFFFFF
        final ratio = WcagAudit.contrastRatio(foreground, background);
        expect(
          ratio,
          greaterThanOrEqualTo(WcagAudit.normalTextContrast),
          reason:
              'Santali Sal green text ($ratio:1) on white must meet ≥ 4.5:1',
        );
      },
    );

    test(
      'Santali Night Sky accent passes normal text contrast on light surface',
      () {
        const foreground = AppColors.santaliNightSky; // #1E2A44
        const background = AppColors.lightSurface; // #FFFFFF
        final ratio = WcagAudit.contrastRatio(foreground, background);
        expect(
          ratio,
          greaterThanOrEqualTo(WcagAudit.normalTextContrast),
          reason:
              'Santali Night sky text ($ratio:1) on white must meet ≥ 4.5:1',
        );
      },
    );

    test(
      'Santali Ochre accent passes large text / UI component contrast on dark surface',
      () {
        const foreground = AppColors.santaliOchre; // #D99B26
        const background = AppColors.darkBackground; // #000000
        final ratio = WcagAudit.contrastRatio(foreground, background);
        expect(
          ratio,
          greaterThanOrEqualTo(WcagAudit.largeTextContrast),
          reason:
              'Santali ochre on dark background ($ratio:1) must meet large text / component contrast ≥ 3.0:1',
        );
      },
    );

    test('minimum tap target helper enforces 48x48 logical pixels', () {
      expect(WcagAudit.hasMinimumTapTarget(const Size(48, 48)), isTrue);
      expect(WcagAudit.hasMinimumTapTarget(const Size(44, 44)), isFalse);
      expect(WcagAudit.hasMinimumTapTarget(const Size(48, 44)), isFalse);
    });
  });
}
