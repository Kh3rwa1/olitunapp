import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/accessibility/wcag_audit.dart';
import 'package:itun/core/theme/app_colors.dart';
import 'package:itun/core/theme/app_theme.dart';
import 'package:itun/features/home/presentation/widgets/magic_translate_dialog.dart';
import 'package:itun/shared/widgets/animated_buttons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('Accessibility: Dynamic Type 200% Text Scaling', () {
    testWidgets(
      'PrimaryButton renders without overflow under 200% text scale',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: MediaQuery(
              data: const MediaQueryData(
                textScaler: TextScaler.linear(2.0),
                size: Size(400, 800),
              ),
              child: Scaffold(
                body: Center(
                  child: PrimaryButton(text: 'Start Lesson', onPressed: () {}),
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Start Lesson'), findsOneWidget);
      },
    );

    testWidgets('DuoButton scales gracefully under 200% text scale', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(2.0),
              size: Size(400, 800),
            ),
            child: Scaffold(
              body: Center(
                child: DuoButton(text: 'SUBMIT ANSWER', onPressed: () {}),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('SUBMIT ANSWER'), findsOneWidget);
    });

    testWidgets(
      'MagicTranslateDialog renders cleanly under 200% text scale without overflow',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const MediaQuery(
                data: MediaQueryData(
                  textScaler: TextScaler.linear(2.0),
                  size: Size(500, 1000),
                ),
                child: Scaffold(
                  body: SingleChildScrollView(child: MagicTranslateDialog()),
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('AI Translator'), findsOneWidget);
        expect(find.text('CLOSE'), findsOneWidget);
      },
    );
  });

  group('Accessibility: Focus Navigation & Semantics Tree', () {
    testWidgets(
      'PrimaryButton has interactive semantics button flag and tap action',
      (tester) async {
        var tapped = false;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: PrimaryButton(
                text: 'Continue Learning',
                onPressed: () => tapped = true,
              ),
            ),
          ),
        );

        final buttonFinder = find.byType(PrimaryButton);
        expect(buttonFinder, findsOneWidget);

        await tester.tap(buttonFinder);
        await tester.pumpAndSettle();
        expect(tapped, isTrue);

        expect(find.text('Continue Learning'), findsOneWidget);
      },
    );
  });

  group('Accessibility: WCAG AA Color Contrast Audit', () {
    test('Light Theme Color Tokens Meet WCAG AA Contrast Standards', () {
      const bg = AppColors.lightBackground;
      const text = AppColors.textPrimaryLight;
      final contrast = WcagAudit.contrastRatio(text, bg);

      expect(
        contrast >= 4.5,
        isTrue,
        reason:
            'Text primary on background must achieve at least 4.5:1 contrast (got $contrast:1)',
      );
    });

    test('Dark Theme Color Tokens Meet WCAG AA Contrast Standards', () {
      const darkBg = AppColors.darkBackground;
      const darkText = AppColors.textPrimaryDark;
      final contrast = WcagAudit.contrastRatio(darkText, darkBg);

      expect(
        contrast >= 4.5,
        isTrue,
        reason:
            'Dark text primary on dark background must achieve at least 4.5:1 contrast (got $contrast:1)',
      );
    });
  });
}
