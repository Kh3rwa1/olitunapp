import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:itun/features/profile/presentation/providers/profile_providers.dart';
import 'package:itun/features/practice/presentation/providers/typing_practice_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/core/storage/hive_service.dart';

class _MockUserStatsNotifier extends Mock implements UserStatsNotifier {}

void main() {
  group('TypingPracticeController', () {
    late _MockUserStatsNotifier mockUserStatsNotifier;
    late SharedPreferences prefs;
    const targetWord = '\u1C5A\u1C5B\u1C5C'; // ᱚᱟᱤ
    const args = TypingPracticeArgs(
      itemKey: 'word_test_1',
      target: targetWord,
      latin: 'Vowels',
      meaning: 'Vowels meaning',
    );

    setUp(() async {
      mockUserStatsNotifier = _MockUserStatsNotifier();
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      // Dummy stub to prevent unawaited Future warnings
      when(
        () => mockUserStatsNotifier.recordPracticeCompletion(
          contentId: any(named: 'contentId'),
          contentType: any(named: 'contentType'),
          practiceMode: any(named: 'practiceMode'),
          attempts: any(named: 'attempts'),
          withHint: any(named: 'withHint'),
          starsAwarded: any(named: 'starsAwarded'),
        ),
      ).thenAnswer((_) async {});
    });

    ProviderContainer createContainer() {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          userStatsProvider.overrideWith((ref) => mockUserStatsNotifier),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('1. Initial state is Idle', () {
      final container = createContainer();
      final state = container.read(typingPracticeControllerProvider(args));

      expect(state.phase, equals(TypingPhase.idle));
      expect(state.typedSoFar, isEmpty);
      expect(state.attemptsTotal, equals(0));
      expect(state.wrongAtPosition, equals(0));
      expect(state.withHint, isFalse);
      expect(state.hasAwardedStars, isFalse);
      expect(state.needsDigits, isFalse);
    });

    test(
      '1b. Initial state has needsDigits true when target contains digits',
      () {
        const argsWithDigits = TypingPracticeArgs(
          itemKey: 'word_digits_test',
          target: '\u1C5A\u1C52\u1C5C', // target has ᱒ (U+1C52)
          latin: 'With Digits',
          meaning: 'With Digits meaning',
        );
        final container = createContainer();
        final state = container.read(
          typingPracticeControllerProvider(argsWithDigits),
        );
        expect(state.needsDigits, isTrue);
      },
    );

    test('2. startPractice transitions state to typing', () {
      final container = createContainer();
      container
          .read(typingPracticeControllerProvider(args).notifier)
          .startPractice();

      final state = container.read(typingPracticeControllerProvider(args));
      expect(state.phase, equals(TypingPhase.typing));
    });

    test('3. appendChar appends correct characters correctly', () {
      final container = createContainer();
      container
          .read(typingPracticeControllerProvider(args).notifier)
          .startPractice();

      // Type first correct char 'ᱚ' (U+1C5A)
      container
          .read(typingPracticeControllerProvider(args).notifier)
          .appendChar('\u1C5A');

      var state = container.read(typingPracticeControllerProvider(args));
      expect(state.typedSoFar, equals('\u1C5A'));
      expect(state.wrongAtPosition, equals(0));

      // Type second correct char 'ᱟ' (U+1C5B)
      container
          .read(typingPracticeControllerProvider(args).notifier)
          .appendChar('\u1C5B');
      state = container.read(typingPracticeControllerProvider(args));
      expect(state.typedSoFar, equals('\u1C5A\u1C5B'));
    });

    test(
      '4. appendChar ignores inputs not in valid Ol Chiki / Danda range',
      () {
        final container = createContainer();
        container
            .read(typingPracticeControllerProvider(args).notifier)
            .startPractice();

        // Type non-Ol-Chiki char like 'x'
        container
            .read(typingPracticeControllerProvider(args).notifier)
            .appendChar('x');

        final state = container.read(typingPracticeControllerProvider(args));
        expect(state.typedSoFar, isEmpty);
        expect(
          state.attemptsTotal,
          equals(0),
        ); // Rejection filter ignores it completely
      },
    );

    test(
      '5. appendChar handles incorrect character and triggers hint after 3 consecutive wrong attempts at same position',
      () {
        final container = createContainer();
        container
            .read(typingPracticeControllerProvider(args).notifier)
            .startPractice();

        // Type correct 'ᱚ'
        container
            .read(typingPracticeControllerProvider(args).notifier)
            .appendChar('\u1C5A');

        // Now type wrong 'ᱩ' (U+1C5D) instead of 'ᱟ' (U+1C5B)
        // Mistake 1 at position 1
        container
            .read(typingPracticeControllerProvider(args).notifier)
            .appendChar('\u1C5D');
        var state = container.read(typingPracticeControllerProvider(args));
        expect(state.typedSoFar, equals('\u1C5A'));
        expect(state.attemptsTotal, equals(1));
        expect(state.wrongAtPosition, equals(1));
        expect(state.withHint, isFalse);

        // Mistake 2 at position 1
        container
            .read(typingPracticeControllerProvider(args).notifier)
            .appendChar('\u1C5D');
        state = container.read(typingPracticeControllerProvider(args));
        expect(state.attemptsTotal, equals(2));
        expect(state.wrongAtPosition, equals(2));
        expect(state.withHint, isFalse);

        // Mistake 3 at position 1 -> triggers hint!
        container
            .read(typingPracticeControllerProvider(args).notifier)
            .appendChar('\u1C5D');
        state = container.read(typingPracticeControllerProvider(args));
        expect(state.attemptsTotal, equals(3));
        expect(state.wrongAtPosition, equals(3));
        expect(state.withHint, isTrue);
      },
    );

    test('6. wrongAtPosition resets to 0 upon correct character input', () {
      final container = createContainer();
      container
          .read(typingPracticeControllerProvider(args).notifier)
          .startPractice();

      // Wrong input once
      container
          .read(typingPracticeControllerProvider(args).notifier)
          .appendChar('\u1C5D');
      var state = container.read(typingPracticeControllerProvider(args));
      expect(state.wrongAtPosition, equals(1));

      // Correct input
      container
          .read(typingPracticeControllerProvider(args).notifier)
          .appendChar('\u1C5A');
      state = container.read(typingPracticeControllerProvider(args));
      expect(state.typedSoFar, equals('\u1C5A'));
      expect(state.wrongAtPosition, equals(0));
    });

    test('7. deleteLastChar deletes last char and resets wrongAtPosition', () {
      final container = createContainer();
      container
          .read(typingPracticeControllerProvider(args).notifier)
          .startPractice();

      container
          .read(typingPracticeControllerProvider(args).notifier)
          .appendChar('\u1C5A');
      container
          .read(typingPracticeControllerProvider(args).notifier)
          .appendChar('\u1C5D'); // Wrong char, wrongAtPosition = 1

      container
          .read(typingPracticeControllerProvider(args).notifier)
          .deleteLastChar();

      final state = container.read(typingPracticeControllerProvider(args));
      expect(state.typedSoFar, isEmpty); // deleted the first correct character
      expect(state.wrongAtPosition, equals(0));
    });

    test(
      '8. revealAndContinue sets typedSoFar to target, sets hint to true, and completes typing',
      () {
        final container = createContainer();
        container
            .read(typingPracticeControllerProvider(args).notifier)
            .startPractice();

        container
            .read(typingPracticeControllerProvider(args).notifier)
            .revealAndContinue();

        final state = container.read(typingPracticeControllerProvider(args));
        expect(state.phase, equals(TypingPhase.complete));
        expect(state.typedSoFar, equals(targetWord));
        expect(state.withHint, isTrue);

        verify(
          () => mockUserStatsNotifier.recordPracticeCompletion(
            contentId: 'word_test_1',
            contentType: 'word',
            practiceMode: 'typing',
            attempts: 0,
            withHint: true,
            starsAwarded: 5,
          ),
        ).called(1);
      },
    );

    test(
      '9. tryAgain resets practice state but preserves hasAwardedStars and avoids duplicate recording',
      () {
        final container = createContainer();
        container
            .read(typingPracticeControllerProvider(args).notifier)
            .startPractice();

        // Match target completely to complete session
        container
            .read(typingPracticeControllerProvider(args).notifier)
            .appendChar('\u1C5A');
        container
            .read(typingPracticeControllerProvider(args).notifier)
            .appendChar('\u1C5B');
        container
            .read(typingPracticeControllerProvider(args).notifier)
            .appendChar('\u1C5C');

        var state = container.read(typingPracticeControllerProvider(args));
        expect(state.phase, equals(TypingPhase.complete));
        expect(state.hasAwardedStars, isTrue);

        // Verify recordPracticeCompletion called exactly once
        verify(
          () => mockUserStatsNotifier.recordPracticeCompletion(
            contentId: 'word_test_1',
            contentType: 'word',
            practiceMode: 'typing',
            attempts: 0,
            withHint: false,
            starsAwarded: 5,
          ),
        ).called(1);

        // Tap "Try again"
        container
            .read(typingPracticeControllerProvider(args).notifier)
            .tryAgain();
        state = container.read(typingPracticeControllerProvider(args));

        expect(state.phase, equals(TypingPhase.idle));
        expect(state.typedSoFar, isEmpty);
        expect(state.hasAwardedStars, isTrue); // Preserved!

        // Start practice and complete a second time
        container
            .read(typingPracticeControllerProvider(args).notifier)
            .startPractice();
        container
            .read(typingPracticeControllerProvider(args).notifier)
            .appendChar('\u1C5A');
        container
            .read(typingPracticeControllerProvider(args).notifier)
            .appendChar('\u1C5B');
        container
            .read(typingPracticeControllerProvider(args).notifier)
            .appendChar('\u1C5C');

        state = container.read(typingPracticeControllerProvider(args));
        expect(state.phase, equals(TypingPhase.complete));

        // Verify recordPracticeCompletion was NOT called a second time (still exactly 1 total call)
        verifyNever(
          () => mockUserStatsNotifier.recordPracticeCompletion(
            contentId: any(named: 'contentId'),
            contentType: any(named: 'contentType'),
            practiceMode: any(named: 'practiceMode'),
            attempts: any(named: 'attempts'),
            withHint: any(named: 'withHint'),
            starsAwarded: any(named: 'starsAwarded'),
          ),
        );
      },
    );

    test('10. markCelebrationDone transitions phase from complete to done', () {
      final container = createContainer();
      container
          .read(typingPracticeControllerProvider(args).notifier)
          .startPractice();
      container
          .read(typingPracticeControllerProvider(args).notifier)
          .revealAndContinue();

      var state = container.read(typingPracticeControllerProvider(args));
      expect(state.phase, equals(TypingPhase.complete));

      container
          .read(typingPracticeControllerProvider(args).notifier)
          .markCelebrationDone();
      state = container.read(typingPracticeControllerProvider(args));
      expect(state.phase, equals(TypingPhase.done));
    });
  });
}
