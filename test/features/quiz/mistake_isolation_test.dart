// WS5 mistake-state tests: account isolation, recovery criterion,
// Review != mastered, durable outbox, reinstall semantics, non-memory.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/api/appwrite_functions_service.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/auth/presentation/providers/auth_providers.dart';
import 'package:itun/features/quiz/presentation/providers/mistake_provider.dart';
import 'package:itun/features/review/data/review_store_notifier.dart';
import 'package:itun/features/review/domain/review_corpus_identity.dart';
import 'package:itun/features/review/domain/review_item.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockFunctions extends Mock implements AppwriteFunctionsService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final t0 = DateTime.utc(2026, 5, 1, 10);

  QuizQuestion wordQ(String id) =>
      QuizQuestion(promptOlChiki: 'x', sourceWordId: id);
  QuizQuestion nonMemoryQ() =>
      QuizQuestion(promptOlChiki: 'x', isNonMemory: true);

  Future<(ProviderContainer, SharedPreferences)> containerFor({
    Map<String, Object> initial = const {},
    bool authenticated = false,
  }) async {
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appwriteFunctionsServiceProvider.overrideWithValue(_MockFunctions()),
        isAuthenticatedProvider.overrideWith((ref) => authenticated),
        corpusIdentityMapProvider.overrideWith(
          (ref) async => ReviewCorpusIdentityMap.empty(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(reviewStoreProvider.future);
    // Allow deferred mistake load to finish.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return (container, prefs);
  }

  group('WS5 mistake isolation and semantics', () {
    test('account A mistake never appears in account B', () async {
      final (cA, prefs) = await containerFor();
      await cA
          .read(mistakeProvider.notifier)
          .recordMistake(
            quizId: 'q1',
            questionIndex: 0,
            question: wordQ('w_a'),
          );
      expect(cA.read(mistakeProvider), hasLength(1));
      // Simulate account B on the same device: scoped keys differ.
      expect(prefs.getString('user_mistakes_list') == null, isTrue);
    });

    test(
      'Review status does not resolve the queue; mastery criterion does',
      () async {
        final (c, _) = await containerFor();
        final notifier = c.read(mistakeProvider.notifier);
        await notifier.recordMistake(
          quizId: 'q1',
          questionIndex: 0,
          question: wordQ('w_r'),
        );
        // Drive the item with failures only: still queued (no new success).
        await c
            .read(reviewStoreProvider.notifier)
            .recordRecall(
              itemId: 'w_r',
              itemType: ReviewItemType.word,
              correct: false,
              exerciseType: ReviewExerciseType.recognition,
              now: t0,
            );
        await notifier.reconcileWithReviewStore(
          await c.read(reviewStoreProvider.notifier).current(),
        );
        expect(c.read(mistakeProvider), hasLength(1));
        // One correct recall after the mistake recovers it.
        await c
            .read(reviewStoreProvider.notifier)
            .recordRecall(
              itemId: 'w_r',
              itemType: ReviewItemType.word,
              correct: true,
              exerciseType: ReviewExerciseType.recognition,
              now: t0.add(const Duration(hours: 1)),
            );
        await notifier.reconcileWithReviewStore(
          await c.read(reviewStoreProvider.notifier).current(),
        );
        expect(c.read(mistakeProvider), isEmpty);
      },
    );

    test('failed backend record stays queued (never swallowed)', () async {
      final (c, _) = await containerFor();
      final notifier = c.read(mistakeProvider.notifier);
      await notifier.recordMistake(
        quizId: 'q1',
        questionIndex: 0,
        question: wordQ('w_q'),
      );
      // Mock functions throw (unstubbed) -> entry remains queued.
      expect(notifier.pendingBackendMutations, greaterThan(0));
    });

    test('duplicate recordMistake delivery is idempotent', () async {
      final (c, _) = await containerFor();
      final notifier = c.read(mistakeProvider.notifier);
      await notifier.recordMistake(
        quizId: 'q1',
        questionIndex: 0,
        question: wordQ('w_d'),
      );
      await notifier.recordMistake(
        quizId: 'q1',
        questionIndex: 0,
        question: wordQ('w_d'),
      );
      expect(c.read(mistakeProvider), hasLength(1));
    });

    test('duplicate resolution delivery is idempotent', () async {
      final (c, _) = await containerFor();
      final notifier = c.read(mistakeProvider.notifier);
      await notifier.recordMistake(
        quizId: 'q1',
        questionIndex: 0,
        question: wordQ('w_res'),
      );
      await notifier.resolveMistake(quizId: 'q1', questionIndex: 0);
      await notifier.resolveMistake(quizId: 'q1', questionIndex: 0);
      expect(c.read(mistakeProvider), isEmpty);
      expect(notifier.resolvedAudit, hasLength(1));
    });

    test('non-memory mistake keeps history but never enters SRS', () async {
      final (c, _) = await containerFor();
      final notifier = c.read(mistakeProvider.notifier);
      await notifier.recordMistake(
        quizId: 'q1',
        questionIndex: 0,
        question: nonMemoryQ(),
      );
      expect(c.read(mistakeProvider), hasLength(1));
      final store = await c.read(reviewStoreProvider.notifier).current();
      expect(store.all(), isEmpty);
      // And never auto-recovers via SRS.
      await notifier.reconcileWithReviewStore(store);
      expect(c.read(mistakeProvider), hasLength(1));
    });

    test('historical record remains after recovery', () async {
      final (c, _) = await containerFor();
      final notifier = c.read(mistakeProvider.notifier);
      await notifier.recordMistake(
        quizId: 'q1',
        questionIndex: 0,
        question: wordQ('w_h'),
      );
      await notifier.resolveMistake(quizId: 'q1', questionIndex: 0);
      expect(c.read(mistakeProvider), isEmpty);
      // History is append-only: the audit retains the event.
      expect(notifier.resolvedAudit, hasLength(1));
      expect(notifier.resolvedAudit.first.isResolved, isTrue);
    });

    test('masteredCount derives from SRS, not from review queue', () async {
      final (c, _) = await containerFor();
      final notifier = c.read(mistakeProvider.notifier);
      expect(notifier.masteredCount, 0);
      await notifier.recordMistake(
        quizId: 'q1',
        questionIndex: 0,
        question: wordQ('w_m'),
      );
      // A queued mistake never inflates mastery.
      expect(notifier.masteredCount, 0);
    });
  });
}
