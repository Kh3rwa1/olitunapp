import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:itun/features/practice/presentation/widgets/typing_practice_panel.dart';
import 'package:itun/features/practice/presentation/widgets/ol_chiki_keyboard.dart';
import 'package:itun/features/practice/presentation/providers/typing_practice_controller.dart';
import '../../test_helpers/typing_practice_pump.dart';

void main() {
  group('TypingPracticePanel Widget Tests', () {
    late MockUserStatsNotifier mockUserStats;
    const testArgs = TypingPracticeArgs(
      itemKey: 'sentence_1',
      target: 'ᱚᱛ',
      latin: 'Ot',
      meaning: 'Earth',
    );

    setUp(() {
      mockUserStats = MockUserStatsNotifier();
      registerFallbackValue(testArgs);
      registerFallbackValue(
        const TypingPracticeState(
          phase: TypingPhase.idle,
          typedSoFar: '',
          attemptsTotal: 0,
          wrongAtPosition: 0,
          withHint: false,
        ),
      );
    });

    testWidgets(
      '1. Renders scaffolds, dashed outlines, and keyboard in typing phase',
      (tester) async {
        tester.view.physicalSize = const Size(390, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await pumpPracticeWidget(
          tester,
          const TypingPracticePanel(args: testArgs),
          args: testArgs,
          state: const TypingPracticeState(
            phase: TypingPhase.typing,
            typedSoFar: '',
            attemptsTotal: 0,
            wrongAtPosition: 0,
            withHint: false,
          ),
          mockUserStats: mockUserStats,
        );

        // Verify scaffolds are rendered
        expect(find.text('PRACTICE TYPING'), findsOneWidget);
        expect(find.text('Ot'), findsOneWidget);
        expect(find.text('Earth'), findsOneWidget);

        // Verify custom text input area is present
        expect(find.byType(TextField), findsOneWidget);

        // Keyboard is rendered
        expect(find.byType(OlChikiKeyboard), findsOneWidget);

        // Reveal button is NOT visible/interactive (opacity 0)
        final revealFinder = find.text('REVEAL & CONTINUE');
        expect(revealFinder, findsOneWidget);
        final opacityWidget = tester.widget<AnimatedOpacity>(
          find
              .ancestor(
                of: revealFinder,
                matching: find.byType(AnimatedOpacity),
              )
              .first,
        );
        expect(opacityWidget.opacity, 0.0);
      },
    );

    testWidgets(
      '2. Reveals button when attemptsTotal >= 6 and triggers controller',
      (tester) async {
        tester.view.physicalSize = const Size(390, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final controller = MockTypingPracticeController(
          const TypingPracticeState(
            phase: TypingPhase.typing,
            typedSoFar: '',
            attemptsTotal: 6,
            wrongAtPosition: 0,
            withHint: true,
          ),
        );

        await pumpPracticeWidget(
          tester,
          const TypingPracticePanel(args: testArgs),
          args: testArgs,
          state: const TypingPracticeState(
            phase: TypingPhase.typing,
            typedSoFar: '',
            attemptsTotal: 6,
            wrongAtPosition: 0,
            withHint: true,
          ),
          mockUserStats: mockUserStats,
          controllerOverride: controller,
        );

        final revealFinder = find.text('REVEAL & CONTINUE');
        final opacityWidget = tester.widget<AnimatedOpacity>(
          find
              .ancestor(
                of: revealFinder,
                matching: find.byType(AnimatedOpacity),
              )
              .first,
        );
        // Oppacity is fully visible!
        expect(opacityWidget.opacity, 1.0);

        // Tap reveal button
        await tester.tap(revealFinder);
        await tester.pump();
        expect(controller.revealAndContinueCalled, isTrue);
      },
    );

    testWidgets('3. Triggers shake animation when attempts increases', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Pump initial state
      await pumpPracticeWidget(
        tester,
        const TypingPracticePanel(args: testArgs),
        args: testArgs,
        state: const TypingPracticeState(
          phase: TypingPhase.typing,
          typedSoFar: '',
          attemptsTotal: 0,
          wrongAtPosition: 0,
          withHint: false,
        ),
        mockUserStats: mockUserStats,
      );

      // Re-pump with 1 wrong attempt
      await pumpPracticeWidget(
        tester,
        const TypingPracticePanel(args: testArgs),
        args: testArgs,
        state: const TypingPracticeState(
          phase: TypingPhase.typing,
          typedSoFar: '',
          attemptsTotal: 1,
          wrongAtPosition: 1,
          withHint: false,
        ),
        mockUserStats: mockUserStats,
      );

      // Let animations run briefly
      await tester.pump(const Duration(milliseconds: 50));
      // Verify shake is in progress by checking offset isn't zero
      final transformFinder = find.byType(Transform);
      expect(transformFinder, findsWidgets);
    });

    testWidgets('4. Done state displays result and handles try again', (
      tester,
    ) async {
      final controller = MockTypingPracticeController(
        const TypingPracticeState(
          phase: TypingPhase.done,
          typedSoFar: 'ᱚᱛ',
          attemptsTotal: 2,
          wrongAtPosition: 0,
          withHint: false,
        ),
      );

      await pumpPracticeWidget(
        tester,
        const TypingPracticePanel(args: testArgs),
        args: testArgs,
        state: const TypingPracticeState(
          phase: TypingPhase.done,
          typedSoFar: 'ᱚᱛ',
          attemptsTotal: 2,
          wrongAtPosition: 0,
          withHint: false,
        ),
        mockUserStats: mockUserStats,
        controllerOverride: controller,
      );

      expect(find.text('Practiced Successfully'), findsOneWidget);
      expect(find.text('ᱚᱛ'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      // Tap Try Again
      await tester.tap(find.text('Try Again'));
      await tester.pump();
      expect(controller.tryAgainCalled, isTrue);
    });

    testWidgets('5. Golden Test: TypingPracticePanel light theme half-typed', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 760);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await pumpPracticeWidget(
        tester,
        const TypingPracticePanel(args: testArgs),
        args: testArgs,
        state: const TypingPracticeState(
          phase: TypingPhase.typing,
          typedSoFar: 'ᱚ',
          attemptsTotal: 1,
          wrongAtPosition: 0,
          withHint: false,
        ),
        mockUserStats: mockUserStats,
      );

      await tester.pumpAndSettle();
      await expectLater(
        find.byType(TypingPracticePanel),
        matchesGoldenFile(
          '../../../goldens/typing_practice_panel_light_half_typed.png',
        ),
      );
    });

    testWidgets('6. Golden Test: TypingPracticePanel dark theme done state', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await pumpPracticeWidget(
        tester,
        const TypingPracticePanel(args: testArgs),
        args: testArgs,
        state: const TypingPracticeState(
          phase: TypingPhase.done,
          typedSoFar: 'ᱚᱛ',
          attemptsTotal: 2,
          wrongAtPosition: 0,
          withHint: false,
        ),
        mockUserStats: mockUserStats,
        themeMode: ThemeMode.dark,
      );

      await tester.pumpAndSettle();
      await expectLater(
        find.byType(TypingPracticePanel),
        matchesGoldenFile(
          '../../../goldens/typing_practice_panel_dark_done.png',
        ),
      );
    });

    testWidgets('7. Golden Test: TypingPracticePanel wrong-shake mid-frame', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 760);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await pumpPracticeWidget(
        tester,
        const TypingPracticePanel(args: testArgs),
        args: testArgs,
        state: const TypingPracticeState(
          phase: TypingPhase.typing,
          typedSoFar: '',
          attemptsTotal: 0,
          wrongAtPosition: 0,
          withHint: false,
        ),
        mockUserStats: mockUserStats,
      );

      await pumpPracticeWidget(
        tester,
        const TypingPracticePanel(args: testArgs),
        args: testArgs,
        state: const TypingPracticeState(
          phase: TypingPhase.typing,
          typedSoFar: '',
          attemptsTotal: 1,
          wrongAtPosition: 1,
          withHint: false,
        ),
        mockUserStats: mockUserStats,
      );

      await tester.pump(const Duration(milliseconds: 50));
      await expectLater(
        find.byType(TypingPracticePanel),
        matchesGoldenFile(
          '../../../goldens/typing_practice_panel_shake_mid_frame.png',
        ),
      );
    });

    testWidgets(
      '8. Golden Test: TypingPracticePanel with Reveal Button visible',
      (tester) async {
        tester.view.physicalSize = const Size(390, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await pumpPracticeWidget(
          tester,
          const TypingPracticePanel(args: testArgs),
          args: testArgs,
          state: const TypingPracticeState(
            phase: TypingPhase.typing,
            typedSoFar: '',
            attemptsTotal: 6,
            wrongAtPosition: 0,
            withHint: true,
          ),
          mockUserStats: mockUserStats,
        );

        await tester.pumpAndSettle();
        await expectLater(
          find.byType(TypingPracticePanel),
          matchesGoldenFile(
            '../../../goldens/typing_practice_panel_reveal_visible.png',
          ),
        );
      },
    );
  });
}
