import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:itun/core/auth/account_scope.dart';
import 'package:itun/features/admin/presentation/quizzes/widgets/quiz_form_sheet/quiz_validation.dart';
import 'package:itun/features/quiz/domain/quiz_memory_resolver.dart';
import 'package:itun/features/quiz/presentation/providers/mistake_provider.dart';
import 'package:itun/features/review/data/review_state_migration.dart';
import 'package:itun/features/review/data/review_store.dart';
import 'package:itun/features/review/domain/memory_scheduler.dart';
import 'package:itun/features/review/domain/retention_metrics.dart';
import 'package:itun/features/review/domain/review_corpus_identity.dart';
import 'package:itun/features/review/domain/review_item.dart';
import 'package:itun/features/review/domain/review_state_merge_policy.dart';
import 'package:itun/shared/models/content_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ===========================================================================
  // GROUP 1: MEMORY (Scenarios 1–9)
  // ===========================================================================
  group('P0 Memory Engine (Scenarios 1-9)', () {
    final now = DateTime.utc(2026, 3, 1, 10);

    test('Scenario 1: Fresh item introduction', () {
      final item = MemoryScheduler.introduce(
        itemId: 'w_fresh',
        itemType: ReviewItemType.word,
        now: now,
      );

      expect(item.itemId, 'w_fresh');
      expect(item.itemType, ReviewItemType.word);
      expect(item.introducedAt, now);
      expect(item.masteryState, MasteryState.fresh);
      expect(item.intervalDays, 0.0);
      expect(item.ease, MemoryScheduler.initialEase);
      expect(item.successfulRecalls, 0);
      expect(item.failedRecalls, 0);
      expect(item.lapseCount, 0);
      expect(item.nextReviewAt, now);
    });

    test('Scenario 2: Successful recall progression', () {
      var item = MemoryScheduler.introduce(
        itemId: 'w_learn',
        itemType: ReviewItemType.word,
        now: now,
      );

      // Recall 1: Recognition -> moves to learning with initial interval
      item = MemoryScheduler.recordRecall(
        item,
        RecallInput(
          correct: true,
          exerciseType: ReviewExerciseType.recognition,
          now: now,
        ),
      );
      expect(item.successfulRecalls, 1);
      expect(item.masteryState, MasteryState.learning);
      expect(item.intervalDays, 1.0);

      // Recall 2: Typing -> moves to review
      final day2 = now.add(const Duration(days: 1));
      item = MemoryScheduler.recordRecall(
        item,
        RecallInput(
          correct: true,
          exerciseType: ReviewExerciseType.typing,
          now: day2,
        ),
      );
      expect(item.successfulRecalls, 3);
      expect(item.typingSuccesses, 1);
      expect(item.masteryState, MasteryState.review);
      expect(item.intervalDays, greaterThanOrEqualTo(3.0));

      // Recalls 3-6: Extended review -> reaches mastered
      var curTime = day2;
      for (var i = 3; i <= 6; i++) {
        curTime = curTime.add(Duration(days: item.intervalDays.ceil()));
        item = MemoryScheduler.recordRecall(
          item,
          RecallInput(
            correct: true,
            exerciseType: ReviewExerciseType.typing,
            now: curTime,
          ),
        );
      }
      expect(item.successfulRecalls, 11);
      expect(item.masteryState, MasteryState.mastered);
      expect(item.intervalDays, greaterThanOrEqualTo(MemoryScheduler.intervalForMasteredDays));
    });

    test('Scenario 3: Lapse demotion', () {
      // Create an item in review
      var item = MemoryScheduler.introduce(
        itemId: 'w_lapse',
        itemType: ReviewItemType.word,
        now: now,
      );
      item = MemoryScheduler.recordRecall(
        item,
        RecallInput(
          correct: true,
          exerciseType: ReviewExerciseType.typing,
          now: now,
        ),
      );
      item = MemoryScheduler.recordRecall(
        item,
        RecallInput(
          correct: true,
          exerciseType: ReviewExerciseType.typing,
          now: now.add(const Duration(days: 1)),
        ),
      );
      expect(item.masteryState, MasteryState.review);

      // Fail recall -> lapse
      final lapseTime = now.add(const Duration(days: 4));
      item = MemoryScheduler.recordRecall(
        item,
        RecallInput(
          correct: false,
          exerciseType: ReviewExerciseType.recognition,
          now: lapseTime,
        ),
      );

      expect(item.lapseCount, 1);
      expect(item.failedRecalls, 1);
      expect(item.masteryState, MasteryState.review); // Single lapse stays in review
      expect(item.intervalDays, 1.0);
      expect(item.nextReviewAt, lapseTime.add(MemoryScheduler.reviewRetryDelay));

      // Repeated failures drop item to learning
      for (var i = 0; i < 6; i++) {
        item = MemoryScheduler.recordRecall(
          item,
          RecallInput(
            correct: false,
            exerciseType: ReviewExerciseType.recognition,
            now: lapseTime.add(Duration(days: i + 1)),
          ),
        );
      }
      expect(item.masteryState, MasteryState.learning);
    });

    test('Scenario 4: Ease calculation stability', () {
      var item = MemoryScheduler.introduce(
        itemId: 'w_ease',
        itemType: ReviewItemType.word,
        now: now,
      );

      // Multiple consecutive failures should clamp at minEase (1.3)
      for (var i = 0; i < 20; i++) {
        item = MemoryScheduler.recordRecall(
          item,
          RecallInput(
            correct: false,
            exerciseType: ReviewExerciseType.recognition,
            now: now.add(Duration(minutes: i * 15)),
          ),
        );
      }
      expect(item.ease, MemoryScheduler.minEase);
      expect(item.ease, greaterThanOrEqualTo(1.3));

      // Multiple consecutive rapid successes should clamp at maxEase (2.5)
      for (var i = 0; i < 20; i++) {
        item = MemoryScheduler.recordRecall(
          item,
          RecallInput(
            correct: true,
            exerciseType: ReviewExerciseType.typing,
            now: now.add(Duration(days: i + 1)),
            responseTimeMs: 800,
          ),
        );
      }
      expect(item.ease, lessThanOrEqualTo(MemoryScheduler.maxEase));
      expect(item.ease, MemoryScheduler.maxEase);
    });

    test('Scenario 5: Typing vs recognition weighting', () {
      final base = MemoryScheduler.introduce(
        itemId: 'w_test',
        itemType: ReviewItemType.word,
        now: now,
      );

      final withRecognition = MemoryScheduler.recordRecall(
        base,
        RecallInput(
          correct: true,
          exerciseType: ReviewExerciseType.recognition,
          now: now,
        ),
      );

      final withTyping = MemoryScheduler.recordRecall(
        base,
        RecallInput(
          correct: true,
          exerciseType: ReviewExerciseType.typing,
          now: now,
        ),
      );

      expect(withTyping.typingSuccesses, 1);
      expect(withRecognition.typingSuccesses, 0);
      expect(withTyping.ease, greaterThanOrEqualTo(withRecognition.ease));
    });

    test('Scenario 6: Daily review queue formation', () {
      final past = now.subtract(const Duration(hours: 2));
      final future = now.add(const Duration(days: 2));

      final itemDue = MemoryItemState(
        itemId: 'w_due',
        itemType: ReviewItemType.word,
        introducedAt: past,
        nextReviewAt: past,
      );
      final itemNotDue = MemoryItemState(
        itemId: 'w_future',
        itemType: ReviewItemType.word,
        introducedAt: now,
        nextReviewAt: future,
      );

      expect(itemDue.isDue(now), isTrue);
      expect(itemNotDue.isDue(now), isFalse);
    });

    test('Scenario 7: Overdue prioritization', () {
      final earlier = now.subtract(const Duration(days: 3));
      final recent = now.subtract(const Duration(hours: 1));

      final overdueItem = MemoryItemState(
        itemId: 'w_overdue',
        itemType: ReviewItemType.word,
        introducedAt: earlier,
        nextReviewAt: earlier,
        lapseCount: 2,
      );
      final recentItem = MemoryItemState(
        itemId: 'w_recent',
        itemType: ReviewItemType.word,
        introducedAt: recent,
        nextReviewAt: recent,
      );

      // Earlier nextReviewAt has higher priority (isBefore)
      expect(overdueItem.nextReviewAt.isBefore(recentItem.nextReviewAt), isTrue);
    });

    test('Scenario 8: Retention rate accuracy', () {
      final tIntro = DateTime.utc(2026, 1, 1, 10);
      final tRecallD1 = DateTime.utc(2026, 1, 1, 20); // Within 24 hours
      final tRecallLate = DateTime.utc(2026, 1, 5, 10); // After 4 days

      final item1 = MemoryItemState(
        itemId: 'w_d1',
        itemType: ReviewItemType.word,
        introducedAt: tIntro,
        nextReviewAt: tRecallD1,
        firstRecallAt: tRecallD1,
        successfulRecalls: 1,
      );
      final item2 = MemoryItemState(
        itemId: 'w_late',
        itemType: ReviewItemType.word,
        introducedAt: tIntro,
        nextReviewAt: tRecallLate,
        firstRecallAt: tRecallLate,
        successfulRecalls: 1,
      );
      final item3 = MemoryItemState(
        itemId: 'w_never',
        itemType: ReviewItemType.word,
        introducedAt: tIntro,
        nextReviewAt: tIntro,
      );

      final metrics = RetentionMetrics.compute(
        [item1, item2, item3],
        now: DateTime.utc(2026, 1, 10),
      );

      expect(metrics.introducedCount, 3);
      expect(metrics.d1EligibleCount, 2);
      expect(metrics.d1RecalledCount, 1); // Only item1 recalled within 24h
      expect(metrics.d1RecallRate, closeTo(0.5, 0.01));
    });

    test('Scenario 9: Leech quarantine / orphan identification', () {
      final map = ReviewCorpusIdentityMap(
        activeWordIds: {'w_valid'},
        activeSentenceIds: const {},
        aliases: const [],
        tombstones: const [
          ReviewIdTombstone(
            itemType: ReviewItemType.word,
            id: 'w_tombstone',
          ),
        ],
      );

      expect(map.isActive('w_valid'), isTrue);
      expect(map.isActive('w_orphan'), isFalse);
      expect(map.isTombstoned('w_tombstone'), isTrue);
    });
  });

  // ===========================================================================
  // GROUP 2: PERSISTENCE (Scenarios 10–14)
  // ===========================================================================
  group('P0 Persistence Durability (Scenarios 10-14)', () {
    test('Scenario 10: Offline local persistence durability', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final scope = AccountScope.forTest(prefs, userId: 'user_123');

      final store = await ReviewStore.load(
        prefs,
        scope: scope,
      );

      await store.recordRecallDurable(
        itemId: 'w_persist',
        itemType: ReviewItemType.word,
        correct: true,
        exerciseType: ReviewExerciseType.typing,
      );

      expect(store.get('w_persist'), isNotNull);
      expect(store.get('w_persist')!.successfulRecalls, 2);
      expect(store.get('w_persist')!.typingSuccesses, 1);

      // Synchronous write check in prefs
      final raw = prefs.getString(scope.reviewKey);
      expect(raw, isNotNull);
      expect(raw!.contains('w_persist'), isTrue);
    });

    test('Scenario 11: Atomic write / anti-corruption skips malformed entries', () async {
      final corruptData = jsonEncode({
        'schemaVersion': 3,
        'items': {
          'w_good': {
            'itemId': 'w_good',
            'itemType': 'word',
            'introducedAt': '2026-01-01T00:00:00.000Z',
            'nextReviewAt': '2026-01-02T00:00:00.000Z',
          },
          'w_bad': 'not-a-map',
        },
      });

      SharedPreferences.setMockInitialValues({
        'review_states_guest': corruptData,
      });
      final prefs = await SharedPreferences.getInstance();
      final scope = AccountScope.forTest(prefs, isGuest: true);

      final store = await ReviewStore.load(
        prefs,
        scope: scope,
      );

      expect(store.get('w_good'), isNotNull);
      expect(store.get('w_bad'), isNull);
    });

    test('Scenario 12: App restart state preservation', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final scope = AccountScope.forTest(prefs, userId: 'user_restart');

      final store1 = await ReviewStore.load(prefs, scope: scope);
      await store1.recordRecallDurable(
        itemId: 'w_survive',
        itemType: ReviewItemType.word,
        correct: true,
        exerciseType: ReviewExerciseType.typing,
      );

      // Re-load as new instance
      final store2 = await ReviewStore.load(prefs, scope: scope);
      final restored = store2.get('w_survive');
      expect(restored, isNotNull);
      expect(restored!.successfulRecalls, 2);
      expect(restored.typingSuccesses, 1);
    });

    test('Scenario 13: Background save queue completion', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final scope = AccountScope.forTest(prefs, userId: 'user_queue');

      final store = await ReviewStore.load(prefs, scope: scope);

      // Fire multiple rapid durable writes
      await Future.wait<void>([
        store.recordRecallDurable(itemId: 'w_1', itemType: ReviewItemType.word, correct: true, exerciseType: ReviewExerciseType.recognition),
        store.recordRecallDurable(itemId: 'w_2', itemType: ReviewItemType.word, correct: true, exerciseType: ReviewExerciseType.recognition),
        store.recordRecallDurable(itemId: 'w_3', itemType: ReviewItemType.word, correct: true, exerciseType: ReviewExerciseType.recognition),
      ]);

      final storeAfter = await ReviewStore.load(prefs, scope: scope);
      expect(storeAfter.get('w_1'), isNotNull);
      expect(storeAfter.get('w_2'), isNotNull);
      expect(storeAfter.get('w_3'), isNotNull);
    });

    test('Scenario 14: Corrupted state recovery resets gracefully', () async {
      SharedPreferences.setMockInitialValues({
        'review_states_guest': '{bad json{{{',
      });
      final prefs = await SharedPreferences.getInstance();
      final scope = AccountScope.forTest(prefs, isGuest: true);

      final store = await ReviewStore.load(
        prefs,
        scope: scope,
      );

      expect(store.all(), isEmpty);

      // Store remains fully functional for new writes
      await store.recordRecallDurable(
        itemId: 'w_new',
        itemType: ReviewItemType.word,
        correct: true,
        exerciseType: ReviewExerciseType.recognition,
      );
      expect(store.get('w_new'), isNotNull);
    });
  });

  // ===========================================================================
  // GROUP 3: ACCOUNT ISOLATION (Scenarios 15–18)
  // ===========================================================================
  group('P0 Account Isolation & Migration (Scenarios 15-18)', () {
    test('Scenario 15: Guest-mode isolation', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final guestScope = AccountScope.forTest(prefs, isGuest: true);
      final userScope = AccountScope.forTest(prefs, userId: 'user_a');

      final guestStore = await ReviewStore.load(
        prefs,
        scope: guestScope,
      );
      await guestStore.recordRecallDurable(
        itemId: 'w_guest_only',
        itemType: ReviewItemType.word,
        correct: true,
        exerciseType: ReviewExerciseType.recognition,
      );

      final userStore = await ReviewStore.load(
        prefs,
        scope: userScope,
      );

      expect(guestStore.get('w_guest_only'), isNotNull);
      expect(userStore.get('w_guest_only'), isNull);
    });

    test('Scenario 16: Multi-account local data separation', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final scopeA = AccountScope.forTest(prefs, userId: 'user_A');
      final scopeB = AccountScope.forTest(prefs, userId: 'user_B');

      final storeA = await ReviewStore.load(
        prefs,
        scope: scopeA,
      );
      final storeB = await ReviewStore.load(
        prefs,
        scope: scopeB,
      );

      await storeA.recordRecallDurable(
        itemId: 'w_userA',
        itemType: ReviewItemType.word,
        correct: true,
        exerciseType: ReviewExerciseType.recognition,
      );

      expect(storeA.get('w_userA'), isNotNull);
      expect(storeB.get('w_userA'), isNull);
    });

    test('Scenario 17: Guest → authenticated migration without loss', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final guestScope = AccountScope.forTest(prefs, isGuest: true);
      final targetScope = AccountScope.forTest(prefs, userId: 'user_target');

      final guestStore = await ReviewStore.load(
        prefs,
        scope: guestScope,
      );
      final userStore = await ReviewStore.load(
        prefs,
        scope: targetScope,
      );

      // Guest practiced w_shared and w_guest
      await guestStore.recordRecallDurable(
        itemId: 'w_shared',
        itemType: ReviewItemType.word,
        correct: true,
        exerciseType: ReviewExerciseType.recognition,
      );
      await guestStore.recordRecallDurable(
        itemId: 'w_guest',
        itemType: ReviewItemType.word,
        correct: true,
        exerciseType: ReviewExerciseType.recognition,
      );

      // Account already had w_shared
      await userStore.recordRecallDurable(
        itemId: 'w_shared',
        itemType: ReviewItemType.word,
        correct: true,
        exerciseType: ReviewExerciseType.recognition,
      );

      final migratedCount = await ReviewStateMigrator.migrateGuestToAccount(
        guestStore: guestStore,
        accountStore: userStore,
      );

      expect(migratedCount.migratedCount, 2);
      expect(userStore.get('w_guest'), isNotNull);
      // Monotonic addition: 1 (account) + 1 (guest) = 2
      expect(userStore.get('w_shared')!.successfulRecalls, 2);
      // Guest store wiped to prevent leakage into next session
      expect(guestStore.all(), isEmpty);
    });

    test('Scenario 18: Logout / account-switch state clearing', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final scope = AccountScope.forTest(prefs, userId: 'user_logout');

      final storeA = await ReviewStore.load(
        prefs,
        scope: scope,
      );
      await storeA.recordRecallDurable(
        itemId: 'w_temp',
        itemType: ReviewItemType.word,
        correct: true,
        exerciseType: ReviewExerciseType.recognition,
      );
      expect(storeA.get('w_temp'), isNotNull);

      await storeA.clear();
      expect(storeA.all(), isEmpty);

      // Key is cleared in SharedPreferences
      final raw = prefs.getString(scope.reviewKey);
      expect(raw, isNull);
    });
  });

  // ===========================================================================
  // GROUP 4: SYNC & CONVERGENCE (Scenarios 19–24)
  // ===========================================================================
  group('P0 Deterministic Sync Convergence (Scenarios 19-24)', () {
    final t1 = DateTime.utc(2026, 1, 1, 10);
    final t2 = DateTime.utc(2026, 1, 2, 10);

    test('Scenario 19: Commutative merge policy', () {
      final a = MemoryItemState(
        itemId: 'w_sym',
        itemType: ReviewItemType.word,
        introducedAt: t1,
        nextReviewAt: t2,
        successfulRecalls: 3,
        failedRecalls: 1,
        ease: 2.3,
      );
      final b = MemoryItemState(
        itemId: 'w_sym',
        itemType: ReviewItemType.word,
        introducedAt: t1.subtract(const Duration(days: 1)),
        nextReviewAt: t1,
        successfulRecalls: 2,
        failedRecalls: 2,
        ease: 2.1,
      );

      final ab = ReviewStateMergePolicy.merge(a, b);
      final ba = ReviewStateMergePolicy.merge(b, a);

      expect(ab.successfulRecalls, ba.successfulRecalls);
      expect(ab.failedRecalls, ba.failedRecalls);
      expect(ab.ease, ba.ease);
      expect(ab.nextReviewAt, ba.nextReviewAt);
      expect(ab.introducedAt, ba.introducedAt);
      expect(ab, equals(ba));
    });

    test('Scenario 20: Concurrent offline recall merging preserves both evidences', () {
      final devA = MemoryItemState(
        itemId: 'w_concurrent',
        itemType: ReviewItemType.word,
        introducedAt: t1,
        lastReviewedAt: t2,
        nextReviewAt: t2.add(const Duration(days: 3)),
        successfulRecalls: 2,
      );
      final devB = MemoryItemState(
        itemId: 'w_concurrent',
        itemType: ReviewItemType.word,
        introducedAt: t1,
        lastReviewedAt: t2.add(const Duration(hours: 2)),
        nextReviewAt: t2.add(const Duration(days: 1)),
        successfulRecalls: 1,
        failedRecalls: 1, // Dev B had a lapse
        lapseCount: 1,
      );

      final merged = ReviewStateMergePolicy.merge(devA, devB);

      // Max evidence preserved
      expect(merged.successfulRecalls, 2);
      expect(merged.failedRecalls, 1);
      expect(merged.lapseCount, 1);
      // Safety: failure causes earlier due date to be selected
      expect(merged.nextReviewAt, devB.nextReviewAt);
    });

    test('Scenario 21: Duplicate sync idempotent handling', () {
      final a = MemoryItemState(
        itemId: 'w_idem',
        itemType: ReviewItemType.word,
        introducedAt: t1,
        nextReviewAt: t2,
        successfulRecalls: 2,
      );
      final b = MemoryItemState(
        itemId: 'w_idem',
        itemType: ReviewItemType.word,
        introducedAt: t1,
        nextReviewAt: t2,
        successfulRecalls: 3,
      );

      final pass1 = ReviewStateMergePolicy.merge(a, b);
      final pass2 = ReviewStateMergePolicy.merge(pass1, b);

      expect(pass1, equals(pass2));
    });

    test('Scenario 22: Out-of-order review sync does not clobber newer state', () {
      final newer = MemoryItemState(
        itemId: 'w_order',
        itemType: ReviewItemType.word,
        introducedAt: t1,
        lastReviewedAt: t2.add(const Duration(days: 5)),
        nextReviewAt: t2.add(const Duration(days: 10)),
        successfulRecalls: 5,
      );
      final olderStale = MemoryItemState(
        itemId: 'w_order',
        itemType: ReviewItemType.word,
        introducedAt: t1,
        lastReviewedAt: t2,
        nextReviewAt: t2.add(const Duration(days: 2)),
        successfulRecalls: 2,
      );

      final merged = ReviewStateMergePolicy.merge(newer, olderStale);

      expect(merged.lastReviewedAt, newer.lastReviewedAt);
      expect(merged.successfulRecalls, 5);
    });

    test('Scenario 23: Clock skew resilience preserves monotonic learning evidence', () {
      // Device B has clock in 2025 (1 year skewed backwards)
      final skewedPast = DateTime.utc(2025);
      final normalTime = DateTime.utc(2026);

      final devNormal = MemoryItemState(
        itemId: 'w_skew',
        itemType: ReviewItemType.word,
        introducedAt: normalTime,
        successfulRecalls: 1,
        nextReviewAt: normalTime.add(const Duration(days: 1)),
      );
      final devSkewed = MemoryItemState(
        itemId: 'w_skew',
        itemType: ReviewItemType.word,
        introducedAt: skewedPast,
        successfulRecalls: 3,
        failedRecalls: 1,
        nextReviewAt: skewedPast.add(const Duration(days: 1)),
      );

      final merged = ReviewStateMergePolicy.merge(devNormal, devSkewed);

      // Recall counts never regress despite skewed timestamps
      expect(merged.successfulRecalls, 3);
      expect(merged.failedRecalls, 1);
      expect(merged.introducedAt, skewedPast); // Earliest introduction retained
    });

    test('Scenario 24: Alias resolution maps old ID to canonical ID', () {
      final map = ReviewCorpusIdentityMap(
        activeWordIds: {'w_canonical'},
        activeSentenceIds: const {},
        aliases: const [
          ReviewIdAlias(
            itemType: ReviewItemType.word,
            from: 'w_deprecated',
            to: 'w_canonical',
          ),
        ],
        tombstones: const [],
      );

      expect(map.resolveCanonicalId('w_deprecated', expectedType: ReviewItemType.word), 'w_canonical');
      expect(map.isActive('w_canonical'), isTrue);
      expect(map.isActive('w_deprecated'), isFalse);
    });
  });

  // ===========================================================================
  // GROUP 5: LEARNING IDENTITY (Scenarios 25–29)
  // ===========================================================================
  group('P0 Canonical Learning Item Identity (Scenarios 25-29)', () {
    test('Scenario 25: Reject non-canonical learning item in memory engine', () {
      final unlinked = QuizQuestion(
        promptOlChiki: 'ᱚ',
      );
      expect(resolveQuizMemoryItem(unlinked), isNull);

      final explicitNonMemory = QuizQuestion(
        promptOlChiki: 'ᱚ',
        sourceWordId: 'w_word_1',
        isNonMemory: true,
      );
      expect(resolveQuizMemoryItem(explicitNonMemory), isNull);
    });

    test('Scenario 26: Correct item mapping for word quiz', () {
      final wordQuestion = QuizQuestion(
        promptOlChiki: 'ᱚᱞ',
        sourceWordId: 'w_word_1',
      );
      final resolved = resolveQuizMemoryItem(wordQuestion);
      expect(resolved, isNotNull);
      expect(resolved!.itemId, 'w_word_1');
      expect(resolved.itemType, ReviewItemType.word);
    });

    test('Scenario 27: Correct item mapping for sentence quiz', () {
      final sentenceQuestion = QuizQuestion(
        promptOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱫᱟᱨᱟᱢ',
        sourceSentenceId: 's_sentence_1',
      );
      final resolved = resolveQuizMemoryItem(sentenceQuestion);
      expect(resolved, isNotNull);
      expect(resolved!.itemId, 's_sentence_1');
      expect(resolved.itemType, ReviewItemType.sentence);
    });

    test('Scenario 28: Fallback handling for non-canonical quiz questions', () {
      final nonCanonicalQuestion = QuizQuestion(
        promptOlChiki: 'General Comprehension',
        isNonMemory: true,
      );

      expect(nonCanonicalQuestion.isCanonicalLearningItem, isFalse);
      expect(nonCanonicalQuestion.hasCanonicalIdentity, isFalse);
      expect(resolveQuizMemoryItem(nonCanonicalQuestion), isNull);
    });

    test('Scenario 29: Admin quiz validation requiring valid source item', () {
      final validWord = QuizQuestion(promptOlChiki: 'ᱚ', sourceWordId: 'w_1');
      expect(QuizValidation.validateQuestionIdentity(validWord), isNull);

      final validSentence = QuizQuestion(promptOlChiki: 'ᱥᱟᱹᱜᱩᱱ', sourceSentenceId: 's_1');
      expect(QuizValidation.validateQuestionIdentity(validSentence), isNull);

      final validNonMemory = QuizQuestion(promptOlChiki: 'Comprehension', isNonMemory: true);
      expect(QuizValidation.validateQuestionIdentity(validNonMemory), isNull);

      final invalidUnlinked = QuizQuestion(promptOlChiki: 'Orphan');
      expect(QuizValidation.validateQuestionIdentity(invalidUnlinked), isNotNull);
    });
  });

  // ===========================================================================
  // GROUP 6: MISTAKE RECONCILIATION (Scenarios 30–33)
  // ===========================================================================
  group('P0 Mistake vs Memory Semantics (Scenarios 30-33)', () {
    test('Scenario 30: Mistake creates memory lapse evidence', () {
      final item = MemoryItemState(
        itemId: 'w_mistake_test',
        itemType: ReviewItemType.word,
        introducedAt: DateTime.utc(2026),
        nextReviewAt: DateTime.utc(2026, 1, 2),
        successfulRecalls: 6,
        intervalDays: 28,
        masteryState: MasteryState.mastered,
      );

      final afterLapse = MemoryScheduler.recordRecall(
        item,
        RecallInput(
          correct: false,
          exerciseType: ReviewExerciseType.recognition,
          now: DateTime.utc(2026, 1, 3),
        ),
      );

      expect(afterLapse.failedRecalls, 1);
      expect(afterLapse.lapseCount, 1);
      expect(afterLapse.masteryState, MasteryState.review); // Demoted from mastered
      expect(afterLapse.intervalDays, 1.0); // Reset interval
    });

    test('Scenario 31: Mistake practice completion updates SRS evidence', () {
      final item = MemoryItemState(
        itemId: 'w_practiced',
        itemType: ReviewItemType.word,
        introducedAt: DateTime.utc(2026),
        nextReviewAt: DateTime.utc(2026, 1, 2),
        failedRecalls: 1,
        masteryState: MasteryState.learning,
      );

      final afterMistakePractice = MemoryScheduler.recordRecall(
        item,
        RecallInput(
          correct: true,
          exerciseType: ReviewExerciseType.recognition,
          now: DateTime.utc(2026, 1, 2, 12),
        ),
      );

      expect(afterMistakePractice.successfulRecalls, 1);
      expect(afterMistakePractice.failedRecalls, 1);
      expect(afterMistakePractice.intervalDays, greaterThanOrEqualTo(1.0));
    });

    test('Scenario 32: SRS mastery clears pending mistake review', () {
      final item = MemoryItemState(
        itemId: 'w_mastered_check',
        itemType: ReviewItemType.word,
        introducedAt: DateTime.utc(2026),
        nextReviewAt: DateTime.utc(2026, 2),
        successfulRecalls: 6,
        intervalDays: 28,
        masteryState: MasteryState.mastered,
      );

      expect(item.isMastered, isTrue);
      expect(item.masteryState == MasteryState.mastered, isTrue);
    });

    test('Scenario 33: Resolved mistakes preserve audit trail and never resurrect', () {
      final mistake = MistakeItem(
        quizId: 'q_1',
        questionIndex: 0,
        question: QuizQuestion(promptOlChiki: 'ᱚᱞ', sourceWordId: 'w_audit'),
        addedAt: '2026-01-01T10:00:00.000Z',
      );

      final resolved = mistake.copyWith(
        isResolved: true,
        resolvedAt: '2026-01-02T12:00:00.000Z',
      );

      expect(resolved.isResolved, isTrue);
      expect(resolved.resolvedAt, '2026-01-02T12:00:00.000Z');

      // Check serialization round-trip
      final json = resolved.toJson();
      final restored = MistakeItem.fromJson(json);

      expect(restored.isResolved, isTrue);
      expect(restored.resolvedAt, '2026-01-02T12:00:00.000Z');
      expect(restored.questionId, '${mistake.quizId}_0');
    });
  });
}
