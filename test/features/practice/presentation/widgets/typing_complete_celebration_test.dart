import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/features/practice/presentation/widgets/typing_complete_celebration.dart';
import 'package:itun/shared/providers/local_settings_provider.dart';
import 'package:itun/features/practice/presentation/providers/typing_practice_controller.dart';
import '../../test_helpers/typing_practice_pump.dart';

void main() {
  group('TypingCompleteCelebration Widget Tests', () {
    late MockUserStatsNotifier mockUserStats;
    const testTarget = 'ᱚᱛ';

    setUp(() {
      mockUserStats = MockUserStatsNotifier();
    });

    testWidgets('1. Renders bounce checkmark and target text', (tester) async {
      await pumpPracticeWidget(
        tester,
        const TypingCompleteCelebration(targetText: testTarget),
        args: const TypingPracticeArgs(
          itemKey: 'word_1',
          target: testTarget,
          latin: 'Ot',
          meaning: 'Earth',
        ),
        state: const TypingPracticeState(
          phase: TypingPhase.complete,
          typedSoFar: testTarget,
          attemptsTotal: 0,
          wrongAtPosition: 0,
          withHint: false,
        ),
        mockUserStats: mockUserStats,
      );

      // Verify the check icon exists
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      // Verify target text is rendered
      expect(find.text(testTarget), findsOneWidget);
    });

    testWidgets('2. Renders ConfettiPainter when reduceMotion is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [reduceVisualEffectsProvider.overrideWithValue(false)],
          child: const MaterialApp(
            home: Scaffold(
              body: TypingCompleteCelebration(targetText: testTarget),
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is CustomPaint &&
              w.painter != null &&
              w.painter.runtimeType.toString() == '_ConfettiPainter',
        ),
        findsOneWidget,
      );
    });

    testWidgets('3. Skips ConfettiPainter when reduceMotion is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [reduceVisualEffectsProvider.overrideWithValue(true)],
          child: const MaterialApp(
            home: Scaffold(
              body: TypingCompleteCelebration(targetText: testTarget),
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is CustomPaint &&
              w.painter != null &&
              w.painter.runtimeType.toString() == '_ConfettiPainter',
        ),
        findsNothing,
      );
    });

    testWidgets(
      '4. Golden Test: TypingCompleteCelebration peak frame (light theme)',
      (tester) async {
        tester.view.physicalSize = const Size(350, 200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await pumpPracticeWidget(
          tester,
          const TypingCompleteCelebration(targetText: testTarget),
          args: const TypingPracticeArgs(
            itemKey: 'word_1',
            target: testTarget,
            latin: 'Ot',
            meaning: 'Earth',
          ),
          state: const TypingPracticeState(
            phase: TypingPhase.complete,
            typedSoFar: testTarget,
            attemptsTotal: 0,
            wrongAtPosition: 0,
            withHint: false,
          ),
          mockUserStats: mockUserStats,
        );

        // Advance animation to t=500ms (peak celebration)
        await tester.pump(const Duration(milliseconds: 500));

        await expectLater(
          find.byType(TypingCompleteCelebration),
          matchesGoldenFile(
            '../../../goldens/typing_complete_celebration_light.png',
          ),
        );
      },
    );

    testWidgets(
      '5. Golden Test: TypingCompleteCelebration peak frame (dark theme)',
      (tester) async {
        tester.view.physicalSize = const Size(350, 200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await pumpPracticeWidget(
          tester,
          const TypingCompleteCelebration(targetText: testTarget),
          args: const TypingPracticeArgs(
            itemKey: 'word_1',
            target: testTarget,
            latin: 'Ot',
            meaning: 'Earth',
          ),
          state: const TypingPracticeState(
            phase: TypingPhase.complete,
            typedSoFar: testTarget,
            attemptsTotal: 0,
            wrongAtPosition: 0,
            withHint: false,
          ),
          mockUserStats: mockUserStats,
          themeMode: ThemeMode.dark,
        );

        // Advance animation to t=500ms (peak celebration)
        await tester.pump(const Duration(milliseconds: 500));

        await expectLater(
          find.byType(TypingCompleteCelebration),
          matchesGoldenFile(
            '../../../goldens/typing_complete_celebration_dark.png',
          ),
        );
      },
    );
  });
}
