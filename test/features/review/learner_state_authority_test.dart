// WS6 learner-state authority contract tests: cross-system transitions
// derive from documented authorities (SRS for mastery, append-only quiz
// history, idempotent rewards) and converge across offline/replay/switch.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/api/appwrite_functions_service.dart';
import 'package:itun/core/auth/account_scope.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/auth/presentation/providers/auth_providers.dart';
import 'package:itun/features/quiz/presentation/providers/mistake_provider.dart';
import 'package:itun/features/review/data/review_state_migration.dart';
import 'package:itun/features/review/data/review_store.dart';
import 'package:itun/features/review/domain/review_corpus_identity.dart';
import 'package:itun/features/review/domain/review_item.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockFunctions extends Mock implements AppwriteFunctionsService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final t0 = DateTime.utc(2026, 6, 1, 10);

  Future<(ProviderContainer, SharedPreferences)> setup() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appwriteFunctionsServiceProvider.overrideWithValue(_MockFunctions()),
        isAuthenticatedProvider.overrideWith((ref) => false),
        corpusIdentityMapProvider.overrideWith(
          (ref) async => ReviewCorpusIdentityMap.empty(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(reviewStoreProvider.future);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return (container, prefs);
  }

  QuizQuestion wordQ(String id) =>
      QuizQuestion(promptOlChiki: 'x', sourceWordId: id);

  group('WS6 authority contracts', () {
    test(
      'learn -> quiz wrong records one failure + one mistake event',
      () async {
        final (c, _) = await setup();
        final notifier = c.read(reviewStoreProvider.notifier);
        final result = await notifier.recordRecall(
          itemId: 'w1',
          itemType: ReviewItemType.word,
          correct: false,
          exerciseType: ReviewExerciseType.recognition,
          now: t0,
        );
        expect(result.durable, isTrue);
        expect(result.state.failedRecalls, 1);
        expect(result.becameMastered, isFalse);

        await c
            .read(mistakeProvider.notifier)
            .recordMistake(
              quizId: 'q1',
              questionIndex: 0,
              question: wordQ('w1'),
            );
        expect(c.read(mistakeProvider), hasLength(1));
      },
    );

    test('wrong -> review -> recovered -> mastered is monotonic', () async {
      final (c, _) = await setup();
      final notifier = c.read(reviewStoreProvider.notifier);
      // Wrong first: learning, never review/mastered.
      var r = await notifier.recordRecall(
        itemId: 'w1',
        itemType: ReviewItemType.word,
        correct: false,
        exerciseType: ReviewExerciseType.recognition,
        now: t0,
      );
      expect(r.state.masteryState, MasteryState.learning);
      // Correct recalls climb; mastery never awarded from one answer.
      for (var i = 0; i < 6; i++) {
        r = await notifier.recordRecall(
          itemId: 'w1',
          itemType: ReviewItemType.word,
          correct: true,
          exerciseType: ReviewExerciseType.typing,
          now: t0.add(Duration(days: i + 1)),
        );
      }
      expect(r.durable, isTrue);
      // Typing counts double: 12 successes -> mastered with interval.
      expect(r.state.masteryState, MasteryState.mastered);
    });

    test('single correct answer never awards mastery', () async {
      final (c, _) = await setup();
      final r = await c
          .read(reviewStoreProvider.notifier)
          .recordRecall(
            itemId: 'w1',
            itemType: ReviewItemType.word,
            correct: true,
            exerciseType: ReviewExerciseType.recognition,
            now: t0,
          );
      expect(r.becameMastered, isFalse);
      expect(r.state.masteryState, isNot(MasteryState.mastered));
    });

    test(
      'offline completion then reconnect preserves work (restart)',
      () async {
        final (c, prefs) = await setup();
        final notifier = c.read(reviewStoreProvider.notifier);
        await notifier.recordRecall(
          itemId: 'w_off',
          itemType: ReviewItemType.word,
          correct: true,
          exerciseType: ReviewExerciseType.typing,
          now: t0,
        );
        // Restart offline: reload under the SAME captured account scope.
        final scope = AccountScope.capture(prefs);
        final reloaded = await ReviewStore.load(prefs, scope: scope);
        expect(reloaded.get('w_off')?.successfulRecalls, 2);
      },
    );

    test('duplicate mutation replay does not double-apply locally', () async {
      final (c, _) = await setup();
      final store = await c.read(reviewStoreProvider.notifier).current();
      // ensureIntroduced is duplicate-safe: second call is a no-op.
      final a = store.ensureIntroduced(
        itemId: 'w1',
        itemType: ReviewItemType.word,
        now: t0,
      );
      final b = store.ensureIntroduced(
        itemId: 'w1',
        itemType: ReviewItemType.word,
        now: t0.add(const Duration(hours: 1)),
      );
      expect(identical(a, b), isTrue);
      expect(store.get('w1')?.successfulRecalls, 0);
    });

    test(
      'guest -> account migration preserves evidence exactly once',
      () async {
        final (c, prefs) = await setup();
        final guest = await ReviewStore.load(
          prefs,
          storageKey: 'review_states_guest',
        );
        guest.recordRecall(
          itemId: 'w_g',
          itemType: ReviewItemType.word,
          correct: true,
          exerciseType: ReviewExerciseType.recognition,
          now: t0,
        );
        await guest.persist();
        final account = await c.read(reviewStoreProvider.notifier).current();
        final result = await ReviewStateMigrator.migrateGuestToAccount(
          guestStore: guest,
          accountStore: account,
          prefs: prefs,
          destinationOwnerKey: account.storageKeyUsed,
        );
        expect(result.migratedCount, 1);
        expect(account.get('w_g')?.successfulRecalls, 1);
        expect(guest.all(), isEmpty);
      },
    );

    test('srs mastery is not inferred from mistake queue length', () async {
      final (c, _) = await setup();
      final mistakes = c.read(mistakeProvider.notifier);
      // Queue several mistakes for different items.
      for (var i = 0; i < 3; i++) {
        await mistakes.recordMistake(
          quizId: 'q$i',
          questionIndex: 0,
          question: wordQ('w_q$i'),
        );
      }
      expect(c.read(mistakeProvider), hasLength(3));
      // No SRS state exists: nothing is mastered anywhere.
      final store = await c.read(reviewStoreProvider.notifier).current();
      expect(store.countsByState()[MasteryState.mastered], 0);
      expect(mistakes.masteredCount, 0);
    });
  });
}
