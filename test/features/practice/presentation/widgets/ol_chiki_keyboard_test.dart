import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/features/practice/presentation/widgets/ol_chiki_keyboard.dart';
import 'package:itun/features/practice/presentation/providers/typing_practice_controller.dart';
import '../../test_helpers/typing_practice_pump.dart';

void main() {
  group('OlChikiKeyboard Widget Tests', () {
    late MockUserStatsNotifier mockUserStats;
    const argsNoDigits = TypingPracticeArgs(
      itemKey: 'word_1',
      target: '\u1C5A\u1C5B',
      latin: 'Word',
      meaning: 'Word Meaning',
    );
    const argsWithDigits = TypingPracticeArgs(
      itemKey: 'word_2',
      target: '\u1C5A\u1C52', // has ᱒ U+1C52
      latin: 'Word With Digits',
      meaning: 'Word Meaning',
    );

    setUp(() {
      mockUserStats = MockUserStatsNotifier();
      registerFallbackValue(argsNoDigits);
      registerFallbackValue(const TypingPracticeState(
        phase: TypingPhase.idle,
        typedSoFar: '',
        attemptsTotal: 0,
        wrongAtPosition: 0,
        withHint: false,
      ));
    });

    testWidgets('1. Renders key rows and actions in light theme without digits row when needsDigits is false', (tester) async {
      await pumpPracticeWidget(
        tester,
        const OlChikiKeyboard(args: argsNoDigits),
        args: argsNoDigits,
        state: const TypingPracticeState(
          phase: TypingPhase.typing,
          typedSoFar: '',
          attemptsTotal: 0,
          wrongAtPosition: 0,
          withHint: false,
          needsDigits: false,
        ),
        mockUserStats: mockUserStats,
      );

      // Verify letters are present
      expect(find.text('ᱚ'), findsOneWidget); // vowel row
      expect(find.text('ᱛ'), findsOneWidget); // consonant row
      expect(find.text(' SPACE '), findsNothing); // SPACE text is capitalized and has style spacing
      expect(find.text('SPACE'), findsOneWidget);
      expect(find.text('DONE'), findsOneWidget);

      // Digits are NOT present
      expect(find.text('᱐'), findsNothing);
    });

    testWidgets('2. Renders dynamic digits row when needsDigits is true', (tester) async {
      await pumpPracticeWidget(
        tester,
        const OlChikiKeyboard(args: argsWithDigits),
        args: argsWithDigits,
        state: const TypingPracticeState(
          phase: TypingPhase.typing,
          typedSoFar: '',
          attemptsTotal: 0,
          wrongAtPosition: 0,
          withHint: false,
          needsDigits: true,
        ),
        mockUserStats: mockUserStats,
      );

      // Digits ARE present!
      expect(find.text('᱐'), findsOneWidget);
      expect(find.text('᱑'), findsOneWidget);
    });

    testWidgets('3. Keystroke interactions dispatch to controller', (tester) async {
      final controller = MockTypingPracticeController(const TypingPracticeState(
        phase: TypingPhase.typing,
        typedSoFar: '',
        attemptsTotal: 0,
        wrongAtPosition: 0,
        withHint: false,
      ));

      await pumpPracticeWidget(
        tester,
        const OlChikiKeyboard(args: argsNoDigits),
        args: argsNoDigits,
        state: const TypingPracticeState(
          phase: TypingPhase.typing,
          typedSoFar: '',
          attemptsTotal: 0,
          wrongAtPosition: 0,
          withHint: false,
        ),
        mockUserStats: mockUserStats,
        controllerOverride: controller,
      );

      // Tap key 'ᱚ'
      await tester.tap(find.text('ᱚ'));
      await tester.pump();
      expect(controller.appendedChars, contains('ᱚ'));

      // Tap Backspace
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();
      expect(controller.deleteLastCharCalled, isTrue);

      // Tap Space
      await tester.tap(find.text('SPACE'));
      await tester.pump();
      expect(controller.appendedChars, contains(' '));

      // Tap ।
      await tester.tap(find.text('।'));
      await tester.pump();
      expect(controller.appendedChars, contains('।'));
    });

    testWidgets('4. Done key triggers completed state transition', (tester) async {
      final controller = MockTypingPracticeController(const TypingPracticeState(
        phase: TypingPhase.complete,
        typedSoFar: '\u1C5A\u1C5B',
        attemptsTotal: 0,
        wrongAtPosition: 0,
        withHint: false,
      ));

      await pumpPracticeWidget(
        tester,
        const OlChikiKeyboard(args: argsNoDigits),
        args: argsNoDigits,
        state: const TypingPracticeState(
          phase: TypingPhase.complete,
          typedSoFar: '\u1C5A\u1C5B',
          attemptsTotal: 0,
          wrongAtPosition: 0,
          withHint: false,
        ),
        mockUserStats: mockUserStats,
        controllerOverride: controller,
      );

      await tester.tap(find.text('DONE'));
      await tester.pump();
      expect(controller.markCelebrationDoneCalled, isTrue);
    });

    testWidgets('5. Golden Test: OlChikiKeyboard light theme with digits', (tester) async {
      tester.view.physicalSize = const Size(390, 420);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await pumpPracticeWidget(
        tester,
        const OlChikiKeyboard(args: argsWithDigits),
        args: argsWithDigits,
        state: const TypingPracticeState(
          phase: TypingPhase.typing,
          typedSoFar: '',
          attemptsTotal: 0,
          wrongAtPosition: 0,
          withHint: false,
          needsDigits: true,
        ),
        mockUserStats: mockUserStats,
        themeMode: ThemeMode.light,
      );

      await tester.pumpAndSettle();
      await expectLater(
        find.byType(OlChikiKeyboard),
        matchesGoldenFile('../../../goldens/ol_chiki_keyboard_light.png'),
      );
    });

    testWidgets('6. Golden Test: OlChikiKeyboard dark theme without digits', (tester) async {
      tester.view.physicalSize = const Size(390, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await pumpPracticeWidget(
        tester,
        const OlChikiKeyboard(args: argsNoDigits),
        args: argsNoDigits,
        state: const TypingPracticeState(
          phase: TypingPhase.typing,
          typedSoFar: '',
          attemptsTotal: 0,
          wrongAtPosition: 0,
          withHint: false,
          needsDigits: false,
        ),
        mockUserStats: mockUserStats,
        themeMode: ThemeMode.dark,
      );

      await tester.pumpAndSettle();
      await expectLater(
        find.byType(OlChikiKeyboard),
        matchesGoldenFile('../../../goldens/ol_chiki_keyboard_dark.png'),
      );
    });
  });
}
