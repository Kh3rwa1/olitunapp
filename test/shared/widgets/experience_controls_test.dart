import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/accessibility/wcag_audit.dart';
import 'package:itun/core/theme/app_colors.dart';
import 'package:itun/shared/widgets/animated_buttons.dart';

Widget _wrap(Widget child, {double scale = 1, bool reduce = false}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        textScaler: TextScaler.linear(scale),
        disableAnimations: reduce,
      ),
      child: Scaffold(
        body: Center(child: SizedBox(width: 280, child: child)),
      ),
    ),
  );
}

void main() {
  testWidgets('primary action supports Enter and Space', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(PrimaryButton(text: 'Continue', onPressed: () => taps++)),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(taps, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(taps, 2);
  });

  testWidgets('primary action exposes a labelled accessible tap target', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        _wrap(PrimaryButton(text: 'Start learning', onPressed: () {})),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      final data = tester
          .getSemantics(find.byType(ElevatedButton))
          .getSemanticsData();
      expect(data.label, 'Start learning');
      expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('large primary labels wrap and increase button height', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        PrimaryButton(
          text: 'Continue to the next learning activity',
          icon: Icons.arrow_forward,
          onPressed: () {},
        ),
        scale: 2,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(ElevatedButton)).height, greaterThan(58));
  });

  testWidgets('Duo labels also wrap at 200 percent text size', (tester) async {
    await tester.pumpWidget(
      _wrap(
        DuoButton(
          text: 'Continue to the next learning activity',
          onPressed: () {},
        ),
        scale: 2,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(ElevatedButton)).height, greaterThan(56));
  });

  testWidgets('loading preserves its label and blocks duplicate activation', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          PrimaryButton(
            text: 'Save progress',
            isLoading: true,
            onPressed: () => taps++,
          ),
          reduce: true,
        ),
      );
      expect(find.text('Save progress'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      final data = tester
          .getSemantics(find.byType(ElevatedButton))
          .getSemanticsData();
      expect(data.label, contains('Save progress'));
      expect(data.label, contains('Loading'));
      expect(data.hasAction(ui.SemanticsAction.tap), isFalse);
      await tester.tap(find.text('Save progress'));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(taps, 0);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('Duo chooses readable text for bright and dark surfaces', (
    tester,
  ) async {
    for (final color in [
      AppColors.primary,
      AppColors.accentPurple,
      AppColors.accentGold,
      AppColors.santaliNightSky,
      Colors.white,
    ]) {
      await tester.pumpWidget(
        _wrap(DuoButton(text: 'Continue', color: color, onPressed: () {})),
      );
      final label = tester.widget<Text>(find.text('Continue'));
      expect(
        WcagAudit.contrastRatio(label.style!.color!, color),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  test('primary label passes contrast throughout the brand gradient', () {
    final colors = AppColors.heroGradient.colors;
    for (var step = 0; step <= 20; step++) {
      final background = Color.lerp(colors.first, colors.last, step / 20)!;
      expect(
        WcagAudit.contrastRatio(AppColors.elevatedButtonFg, background),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  test('black category labels pass across every supported gradient', () {
    for (final gradient in [
      AppColors.heroGradient,
      AppColors.skyBlueGradient,
      AppColors.peachGradient,
      AppColors.mintGradient,
      AppColors.sunsetGradient,
      AppColors.purpleGradient,
      AppColors.premiumCoral,
    ]) {
      for (var step = 0; step <= 20; step++) {
        final background = Color.lerp(
          gradient.colors.first,
          gradient.colors.last,
          step / 20,
        )!;
        expect(
          WcagAudit.contrastRatio(Colors.black, background),
          greaterThanOrEqualTo(4.5),
        );
      }
    }
  });
}
