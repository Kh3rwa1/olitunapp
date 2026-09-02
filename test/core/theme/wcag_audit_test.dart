import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/accessibility/wcag_audit.dart';
import 'package:itun/core/theme/app_colors.dart';

/// Verifies the theme's own contrast claims for button foregrounds.
///
/// The light FilledButton/ElevatedButton themes render on AppColors.primary
/// (#1EE088). The legacy white foreground was 1.74:1 — a WCAG AA failure on
/// every brand CTA — so the theme now uses AppColors.elevatedButtonFg.
void main() {
  group('theme button foreground contrast (WcagAudit)', () {
    test('elevatedButtonFg on primary is WCAG AAA (>= 7.0:1)', () {
      final ratio = WcagAudit.contrastRatio(
        AppColors.elevatedButtonFg,
        AppColors.primary,
      );
      expect(ratio, greaterThanOrEqualTo(7.0));
    });

    test('elevatedButtonFg passes normal-text AA on bright tokens', () {
      for (final bg in [
        AppColors.primary,
        AppColors.success,
        AppColors.brandBlue,
        AppColors.accentOchre,
        AppColors.accentGold,
        const Color(0xFF10B981),
      ]) {
        expect(
          WcagAudit.passesNormalText(AppColors.elevatedButtonFg, bg),
          isTrue,
          reason: 'elevatedButtonFg on $bg must pass AA (>= 4.5:1)',
        );
      }
    });

    test('white on primary is a documented AA failure (< 3:1)', () {
      final ratio = WcagAudit.contrastRatio(Colors.white, AppColors.primary);
      expect(ratio, lessThan(3.0));
    });

    test('white on success is a documented AA failure (< 3:1)', () {
      final ratio = WcagAudit.contrastRatio(Colors.white, AppColors.success);
      expect(ratio, lessThan(3.0));
    });

    test('dark-theme button foreground (black) passes on primary', () {
      expect(
        WcagAudit.passesNormalText(Colors.black, AppColors.primary),
        isTrue,
      );
    });
  });
}
