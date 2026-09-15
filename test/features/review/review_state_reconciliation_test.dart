import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/review/domain/review_corpus_identity.dart';
import 'package:itun/features/review/domain/review_item.dart';

void main() {
  final t0 = DateTime.utc(2026, 1, 1, 9);
  final t1 = DateTime.utc(2026, 1, 2, 9);
  final t2 = DateTime.utc(2026, 1, 3, 9);

  MemoryItemState makeItem({
    required String id,
    ReviewItemType type = ReviewItemType.word,
    DateTime? introducedAt,
    DateTime? lastReviewedAt,
    int successfulRecalls = 3,
    int failedRecalls = 1,
    int lapseCount = 0,
    double ease = 2.5,
    double intervalDays = 3.0,
    MasteryState masteryState = MasteryState.review,
    int? responseTimeMs = 1200,
    ReviewExerciseType exerciseType = ReviewExerciseType.typing,
    int typingSuccesses = 2,
    DateTime? firstRecallAt,
  }) {
    final intro = introducedAt ?? t0;
    return MemoryItemState(
      itemId: id,
      itemType: type,
      introducedAt: intro,
      nextReviewAt: lastReviewedAt?.add(const Duration(days: 3)) ?? intro,
      lastPresentedAt: lastReviewedAt ?? intro,
      lastReviewedAt: lastReviewedAt,
      successfulRecalls: successfulRecalls,
      failedRecalls: failedRecalls,
      lapseCount: lapseCount,
      ease: ease,
      intervalDays: intervalDays,
      masteryState: masteryState,
      lastResponseTimeMs: responseTimeMs,
      lastExerciseType: exerciseType,
      typingSuccesses: typingSuccesses,
      firstRecallAt: firstRecallAt ?? intro,
    );
  }

  group('ReviewCorpusIdentity & State Reconciliation', () {
    late ReviewCorpusIdentityMap baseCorpus;

    setUp(() {
      baseCorpus = ReviewCorpusIdentityMap(
        activeWordIds: {'w_active1', 'w_active2', 'w_target'},
        activeSentenceIds: {'s_active1', 's_target'},
        aliases: [
          const ReviewIdAlias(
            itemType: ReviewItemType.word,
            from: 'w_old',
            to: 'w_target',
          ),
          const ReviewIdAlias(
            itemType: ReviewItemType.sentence,
            from: 's_old',
            to: 's_target',
          ),
        ],
        tombstones: [
          const ReviewIdTombstone(
            itemType: ReviewItemType.word,
            id: 'w_deleted',
          ),
          const ReviewIdTombstone(
            itemType: ReviewItemType.sentence,
            id: 's_deleted',
          ),
        ],
      );
    });

    test('active word remains unchanged', () {
      final item = makeItem(id: 'w_active1');
      final res = ReviewStateReconciler.reconcile(
        states: {item.itemId: item},
        corpusMap: baseCorpus,
      );
      expect(res.activeStates, hasLength(1));
      expect(res.activeStates['w_active1'], equals(item));
      expect(res.renamedOldIds, isEmpty);
      expect(res.tombstonedIds, isEmpty);
      expect(res.quarantinedStates, isEmpty);
    });

    test('active sentence remains unchanged', () {
      final item = makeItem(id: 's_active1', type: ReviewItemType.sentence);
      final res = ReviewStateReconciler.reconcile(
        states: {item.itemId: item},
        corpusMap: baseCorpus,
      );
      expect(res.activeStates, hasLength(1));
      expect(res.activeStates['s_active1'], equals(item));
    });

    test('word rename preserves every scheduler field', () {
      final old = makeItem(
        id: 'w_old',
        introducedAt: t0,
        lastReviewedAt: t1,
        successfulRecalls: 7,
        failedRecalls: 2,
        lapseCount: 1,
        ease: 2.3,
        intervalDays: 5.5,
        masteryState: MasteryState.mastered,
        responseTimeMs: 850,
        typingSuccesses: 5,
        firstRecallAt: t0,
      );

      final res = ReviewStateReconciler.reconcile(
        states: {old.itemId: old},
        corpusMap: baseCorpus,
      );

      expect(res.activeStates.containsKey('w_target'), isTrue);
      expect(res.renamedOldIds, contains('w_old'));
      final target = res.activeStates['w_target']!;

      expect(target.itemId, 'w_target');
      expect(target.itemType, old.itemType);
      expect(target.introducedAt, old.introducedAt);
      expect(target.lastPresentedAt, old.lastPresentedAt);
      expect(target.lastReviewedAt, old.lastReviewedAt);
      expect(target.nextReviewAt, old.nextReviewAt);
      expect(target.intervalDays, old.intervalDays);
      expect(target.ease, old.ease);
      expect(target.successfulRecalls, old.successfulRecalls);
      expect(target.failedRecalls, old.failedRecalls);
      expect(target.lapseCount, old.lapseCount);
      expect(target.masteryState, old.masteryState);
      expect(target.lastResponseTimeMs, old.lastResponseTimeMs);
      expect(target.lastExerciseType, old.lastExerciseType);
      expect(target.typingSuccesses, old.typingSuccesses);
      expect(target.firstRecallAt, old.firstRecallAt);
    });

    test('sentence rename preserves every scheduler field', () {
      final old = makeItem(
        id: 's_old',
        type: ReviewItemType.sentence,
        introducedAt: t0,
        lastReviewedAt: t1,
        successfulRecalls: 4,
        failedRecalls: 0,
        exerciseType: ReviewExerciseType.recognition,
      );

      final res = ReviewStateReconciler.reconcile(
        states: {old.itemId: old},
        corpusMap: baseCorpus,
      );

      expect(res.activeStates.containsKey('s_target'), isTrue);
      expect(res.renamedOldIds, contains('s_old'));
      final target = res.activeStates['s_target']!;
      expect(target.itemId, 's_target');
      expect(target.itemType, ReviewItemType.sentence);
      expect(target.successfulRecalls, 4);
    });

    test('alias chain resolves to the final canonical ID', () {
      final chainCorpus = ReviewCorpusIdentityMap(
        activeWordIds: {'w_target'},
        activeSentenceIds: const {},
        aliases: [
          const ReviewIdAlias(
            itemType: ReviewItemType.word,
            from: 'w_step1',
            to: 'w_step2',
          ),
          const ReviewIdAlias(
            itemType: ReviewItemType.word,
            from: 'w_step2',
            to: 'w_target',
          ),
        ],
        tombstones: const [],
      );

      final state = makeItem(id: 'w_step1');
      final res = ReviewStateReconciler.reconcile(
        states: {state.itemId: state},
        corpusMap: chainCorpus,
      );

      expect(res.activeStates.containsKey('w_target'), isTrue);
      expect(res.activeStates['w_target']!.itemId, 'w_target');
      expect(res.renamedOldIds, contains('w_step1'));
    });

    test('alias cycle is rejected and quarantined safely', () {
      final cycleCorpus = ReviewCorpusIdentityMap(
        activeWordIds: {'w_target'},
        activeSentenceIds: const {},
        aliases: [
          const ReviewIdAlias(
            itemType: ReviewItemType.word,
            from: 'w_c1',
            to: 'w_c2',
          ),
          const ReviewIdAlias(
            itemType: ReviewItemType.word,
            from: 'w_c2',
            to: 'w_c1',
          ),
        ],
        tombstones: const [],
      );

      final state = makeItem(id: 'w_c1');
      final res = ReviewStateReconciler.reconcile(
        states: {state.itemId: state},
        corpusMap: cycleCorpus,
      );

      expect(res.activeStates, isEmpty);
      expect(res.quarantinedStates.containsKey('w_c1'), isTrue);
    });

    test('missing alias target is rejected and quarantined safely', () {
      final missingTargetCorpus = ReviewCorpusIdentityMap(
        activeWordIds: {'w_target'},
        activeSentenceIds: const {},
        aliases: [
          const ReviewIdAlias(
            itemType: ReviewItemType.word,
            from: 'w_orphan_alias',
            to: 'w_does_not_exist',
          ),
        ],
        tombstones: const [],
      );

      final state = makeItem(id: 'w_orphan_alias');
      final res = ReviewStateReconciler.reconcile(
        states: {state.itemId: state},
        corpusMap: missingTargetCorpus,
      );

      expect(res.activeStates, isEmpty);
      expect(res.quarantinedStates.containsKey('w_orphan_alias'), isTrue);
    });

    test('alias type mismatch is rejected and quarantined safely', () {
      // Alias specifies word, but points to s_active1 (sentence)
      final mismatchCorpus = ReviewCorpusIdentityMap(
        activeWordIds: {'w_active1'},
        activeSentenceIds: {'s_active1'},
        aliases: [
          const ReviewIdAlias(
            itemType: ReviewItemType.word,
            from: 'w_mismatch',
            to: 's_active1',
          ),
        ],
        tombstones: const [],
      );

      final state = makeItem(id: 'w_mismatch');
      final res = ReviewStateReconciler.reconcile(
        states: {state.itemId: state},
        corpusMap: mismatchCorpus,
      );

      expect(res.activeStates, isEmpty);
      expect(res.quarantinedStates.containsKey('w_mismatch'), isTrue);
    });

    test('tombstoned item is excluded from due and active states', () {
      final tombstoned = makeItem(id: 'w_deleted', lastReviewedAt: t0);
      final res = ReviewStateReconciler.reconcile(
        states: {tombstoned.itemId: tombstoned},
        corpusMap: baseCorpus,
      );

      expect(res.activeStates, isEmpty);
      expect(res.tombstonedIds, contains('w_deleted'));
      expect(res.quarantinedStates, isEmpty);
    });

    test(
      'unknown orphan is quarantined and reported, not silently deleted',
      () {
        final orphan = makeItem(id: 'mystery_item_123');
        final res = ReviewStateReconciler.reconcile(
          states: {orphan.itemId: orphan},
          corpusMap: baseCorpus,
        );

        expect(res.activeStates, isEmpty);
        expect(res.quarantinedStates.containsKey('mystery_item_123'), isTrue);
        expect(res.quarantinedStates['mystery_item_123'], equals(orphan));
        expect(res.tombstonedIds, isEmpty);
        expect(res.orphanCount, 1);
      },
    );

    test('reconciliation is idempotent', () {
      final items = {
        'w_active1': makeItem(id: 'w_active1'),
        'w_old': makeItem(id: 'w_old'),
        'w_deleted': makeItem(id: 'w_deleted'),
        'orphan_1': makeItem(id: 'orphan_1'),
      };

      final firstPass = ReviewStateReconciler.reconcile(
        states: items,
        corpusMap: baseCorpus,
      );

      final secondPass = ReviewStateReconciler.reconcile(
        states: firstPass.activeStates,
        corpusMap: baseCorpus,
        existingQuarantine: firstPass.quarantinedStates,
      );

      expect(secondPass.activeStates, equals(firstPass.activeStates));
      expect(secondPass.quarantinedStates, equals(firstPass.quarantinedStates));
      expect(secondPass.hasChanges, isFalse);
    });

    group('alias collision resolution', () {
      test(
        'all fields come from selected legacy winner when newer, no fields/counters merged or leaked',
        () {
          final olderCanonical = MemoryItemState(
            itemId: 'w_target',
            itemType: ReviewItemType.word,
            introducedAt: t0,
            nextReviewAt: t1.add(const Duration(days: 2)),
            lastPresentedAt: t1,
            lastReviewedAt: t1,
            successfulRecalls: 11,
            failedRecalls: 12,
            lapseCount: 13,
            ease: 1.4,
            intervalDays: 1.5,
            masteryState: MasteryState.learning,
            lastResponseTimeMs: 1600,
            lastExerciseType: ReviewExerciseType.listening,
            typingSuccesses: 17,
            firstRecallAt: t0,
          );
          final newerOldState = MemoryItemState(
            itemId: 'w_old',
            itemType: ReviewItemType.word,
            introducedAt: t0,
            nextReviewAt: t2.add(const Duration(days: 5)),
            lastPresentedAt: t2,
            lastReviewedAt: t2, // newer than t1
            successfulRecalls: 21,
            failedRecalls: 22,
            lapseCount: 23,
            ease: 2.4,
            intervalDays: 4.5,
            masteryState: MasteryState.mastered,
            lastResponseTimeMs: 800,
            lastExerciseType: ReviewExerciseType.typing,
            typingSuccesses: 27,
            firstRecallAt: t0.add(const Duration(hours: 1)),
          );

          final res = ReviewStateReconciler.reconcile(
            states: {'w_target': olderCanonical, 'w_old': newerOldState},
            corpusMap: baseCorpus,
          );

          expect(res.activeStates, hasLength(1));
          final winner = res.activeStates['w_target']!;

          // Every field must match newer legacy winner with itemId renamed to canonical
          expect(winner.itemId, 'w_target');
          expect(winner.itemType, ReviewItemType.word);
          expect(winner.introducedAt, newerOldState.introducedAt);
          expect(winner.nextReviewAt, newerOldState.nextReviewAt);
          expect(winner.lastPresentedAt, newerOldState.lastPresentedAt);
          expect(winner.lastReviewedAt, newerOldState.lastReviewedAt);
          expect(winner.successfulRecalls, 21);
          expect(winner.failedRecalls, 22);
          expect(winner.lapseCount, 23);
          expect(winner.ease, 2.4);
          expect(winner.intervalDays, 4.5);
          expect(winner.masteryState, MasteryState.mastered);
          expect(winner.lastResponseTimeMs, 800);
          expect(winner.lastExerciseType, ReviewExerciseType.typing);
          expect(winner.typingSuccesses, 27);
          expect(winner.firstRecallAt, newerOldState.firstRecallAt);

          // Proving no counters or fields leaked from losing canonical state
          expect(winner.successfulRecalls, isNot(11));
          expect(winner.successfulRecalls, isNot(32)); // 11 + 21
          expect(winner.failedRecalls, isNot(12));
          expect(winner.failedRecalls, isNot(34)); // 12 + 22
          expect(winner.lapseCount, isNot(13));
          expect(winner.lapseCount, isNot(36)); // 13 + 23
          expect(winner.typingSuccesses, isNot(17));
          expect(winner.typingSuccesses, isNot(44)); // 17 + 27
          expect(winner.ease, isNot(1.4));
          expect(winner.intervalDays, isNot(1.5));
          expect(winner.masteryState, isNot(MasteryState.learning));
          expect(winner.lastResponseTimeMs, isNot(1600));
          expect(winner.lastExerciseType, isNot(ReviewExerciseType.listening));

          expect(res.collisionsResolved, 1);
        },
      );

      test(
        'all fields come from canonical state when canonical is newer, no fields/counters merged or leaked',
        () {
          final newerCanonical = MemoryItemState(
            itemId: 'w_target',
            itemType: ReviewItemType.word,
            introducedAt: t0,
            nextReviewAt: t2.add(const Duration(days: 4)),
            lastPresentedAt: t2,
            lastReviewedAt: t2, // newer than t1
            successfulRecalls: 31,
            failedRecalls: 32,
            lapseCount: 33,
            ease: 2.7,
            intervalDays: 6.0,
            masteryState: MasteryState.mastered,
            lastResponseTimeMs: 750,
            lastExerciseType: ReviewExerciseType.typing,
            typingSuccesses: 37,
            firstRecallAt: t0,
          );
          final olderOldState = MemoryItemState(
            itemId: 'w_old',
            itemType: ReviewItemType.word,
            introducedAt: t0,
            nextReviewAt: t1.add(const Duration(days: 1)),
            lastPresentedAt: t1,
            lastReviewedAt: t1,
            successfulRecalls: 41,
            failedRecalls: 42,
            lapseCount: 43,
            ease: 1.5,
            intervalDays: 2.0,
            masteryState: MasteryState.review,
            lastResponseTimeMs: 1400,
            lastExerciseType: ReviewExerciseType.recognition,
            typingSuccesses: 47,
            firstRecallAt: t0.add(const Duration(hours: 2)),
          );

          final res = ReviewStateReconciler.reconcile(
            states: {'w_target': newerCanonical, 'w_old': olderOldState},
            corpusMap: baseCorpus,
          );

          expect(res.activeStates, hasLength(1));
          final winner = res.activeStates['w_target']!;

          // Every field matches canonical
          expect(winner.itemId, 'w_target');
          expect(winner.successfulRecalls, 31);
          expect(winner.failedRecalls, 32);
          expect(winner.lapseCount, 33);
          expect(winner.ease, 2.7);
          expect(winner.intervalDays, 6.0);
          expect(winner.masteryState, MasteryState.mastered);
          expect(winner.lastResponseTimeMs, 750);
          expect(winner.lastExerciseType, ReviewExerciseType.typing);
          expect(winner.typingSuccesses, 37);

          // Proving no counters or fields leaked from losing legacy state
          expect(winner.successfulRecalls, isNot(41));
          expect(winner.successfulRecalls, isNot(72)); // 31 + 41
          expect(winner.failedRecalls, isNot(42));
          expect(winner.failedRecalls, isNot(74)); // 32 + 42
          expect(winner.lapseCount, isNot(43));
          expect(winner.lapseCount, isNot(76)); // 33 + 43
          expect(winner.typingSuccesses, isNot(47));
          expect(winner.typingSuccesses, isNot(84)); // 37 + 47
          expect(winner.ease, isNot(1.5));
          expect(winner.intervalDays, isNot(2.0));
          expect(winner.masteryState, isNot(MasteryState.review));
          expect(winner.lastResponseTimeMs, isNot(1400));
          expect(
            winner.lastExerciseType,
            isNot(ReviewExerciseType.recognition),
          );

          expect(res.collisionsResolved, 1);
        },
      );

      test(
        'canonical state wins when effective timestamps are equal without counter merging',
        () {
          final canonical = MemoryItemState(
            itemId: 'w_target',
            itemType: ReviewItemType.word,
            introducedAt: t0,
            nextReviewAt: t1.add(const Duration(days: 3)),
            lastPresentedAt: t1,
            lastReviewedAt: t1,
            successfulRecalls: 50,
            failedRecalls: 51,
            lapseCount: 52,
            intervalDays: 3.5,
            masteryState: MasteryState.review,
            lastResponseTimeMs: 900,
            lastExerciseType: ReviewExerciseType.typing,
            typingSuccesses: 55,
            firstRecallAt: t0,
          );
          final oldState = MemoryItemState(
            itemId: 'w_old',
            itemType: ReviewItemType.word,
            introducedAt: t0,
            nextReviewAt: t1.add(const Duration(days: 3)),
            lastPresentedAt: t1,
            lastReviewedAt: t1, // equal timestamp
            successfulRecalls: 60,
            failedRecalls: 61,
            lapseCount: 62,
            ease: 1.8,
            intervalDays: 1.5,
            masteryState: MasteryState.learning,
            lastResponseTimeMs: 1500,
            lastExerciseType: ReviewExerciseType.listening,
            typingSuccesses: 65,
            firstRecallAt: t0,
          );

          final res = ReviewStateReconciler.reconcile(
            states: {'w_target': canonical, 'w_old': oldState},
            corpusMap: baseCorpus,
          );

          expect(res.activeStates, hasLength(1));
          final winner = res.activeStates['w_target']!;
          expect(winner.successfulRecalls, 50); // canonical won
          expect(winner.failedRecalls, 51);
          expect(winner.successfulRecalls, isNot(110)); // not merged
          expect(winner.failedRecalls, isNot(112));
          expect(winner.ease, 2.5);
          expect(winner.masteryState, MasteryState.review);
          expect(res.collisionsResolved, 1);
        },
      );
    });

    group('Manifest and corpus load failure handling and safe fallbacks', () {
      final sampleStates = {
        'w1': makeItem(id: 'w1', lastReviewedAt: t1),
        'w_legacy': makeItem(id: 'w_legacy', lastReviewedAt: t1),
      };

      test('missing manifest string degrades safely without throwing', () {
        final map = ReviewCorpusIdentityMap.fromStringCatalogs(
          wordsJson: jsonEncode([
            {'id': 'w1'},
          ]),
          sentencesJson: '[]',
          manifestJson: '',
        );

        expect(map.isDegraded, isTrue);
        expect(map.activeWordIds, contains('w1'));

        final res = ReviewStateReconciler.reconcile(
          states: sampleStates,
          corpusMap: map,
        );

        // State preserved, no destructive quarantine
        expect(res.hasChanges, isFalse);
        expect(res.activeStates, equals(sampleStates));
        expect(res.quarantinedStates, isEmpty);
      });

      test(
        'malformed manifest JSON degrades safely and preserves learner state',
        () {
          final map = ReviewCorpusIdentityMap.fromStringCatalogs(
            wordsJson: jsonEncode([
              {'id': 'w1'},
            ]),
            sentencesJson: '[]',
            manifestJson: '{ broken json: true ',
          );

          expect(map.isDegraded, isTrue);

          final res = ReviewStateReconciler.reconcile(
            states: sampleStates,
            corpusMap: map,
          );

          expect(res.hasChanges, isFalse);
          expect(res.activeStates, equals(sampleStates));
          expect(res.quarantinedStates, isEmpty);
        },
      );

      test(
        'unsupported manifest schemaVersion degrades safely and preserves local state',
        () {
          final map = ReviewCorpusIdentityMap.fromStringCatalogs(
            wordsJson: jsonEncode([
              {'id': 'w1'},
            ]),
            sentencesJson: '[]',
            manifestJson: jsonEncode({
              'schemaVersion': 99, // unsupported future schema
              'aliases': [
                {'from': 'w_legacy', 'to': 'w1', 'itemType': 'word'},
              ],
              'tombstones': [],
            }),
          );

          expect(map.isDegraded, isTrue);

          final res = ReviewStateReconciler.reconcile(
            states: sampleStates,
            corpusMap: map,
          );

          // Skips destructive reconciliation; preserves states
          expect(res.hasChanges, isFalse);
          expect(res.activeStates, equals(sampleStates));
        },
      );

      test('invalid alias cycle degrades manifest safely', () {
        final map = ReviewCorpusIdentityMap.fromStringCatalogs(
          wordsJson: jsonEncode([
            {'id': 'w1'},
          ]),
          sentencesJson: '[]',
          manifestJson: jsonEncode({
            'schemaVersion': 1,
            'aliases': [
              {'from': 'cycle_a', 'to': 'cycle_b', 'itemType': 'word'},
              {'from': 'cycle_b', 'to': 'cycle_a', 'itemType': 'word'},
            ],
            'tombstones': [],
          }),
        );

        expect(map.isDegraded, isTrue);

        final res = ReviewStateReconciler.reconcile(
          states: sampleStates,
          corpusMap: map,
        );

        expect(res.hasChanges, isFalse);
        expect(res.activeStates, equals(sampleStates));
      });

      test(
        'corpus loading failure degrades safely and preserves learner state',
        () {
          final map = ReviewCorpusIdentityMap.fromStringCatalogs(
            wordsJson: 'broken words json',
            sentencesJson: 'broken sentences json',
            manifestJson: jsonEncode({
              'schemaVersion': 1,
              'aliases': [],
              'tombstones': [],
            }),
          );

          expect(map.isDegraded, isTrue);
          expect(
            map.availabilityState,
            CorpusAvailabilityState.corpusUnavailable,
          );

          final res = ReviewStateReconciler.reconcile(
            states: sampleStates,
            corpusMap: map,
          );

          expect(res.hasChanges, isFalse);
          expect(res.activeStates, equals(sampleStates));
          expect(res.quarantinedStates, isEmpty);
        },
      );

      test(
        'explicit availability state transitions and non-destructive reconciliation',
        () {
          // 1. corpusUnavailable
          final unavailableMap = ReviewCorpusIdentityMap.degraded();
          expect(
            unavailableMap.availabilityState,
            CorpusAvailabilityState.corpusUnavailable,
          );
          final resUnavailable = ReviewStateReconciler.reconcile(
            states: sampleStates,
            corpusMap: unavailableMap,
          );
          expect(resUnavailable.hasChanges, isFalse);
          expect(resUnavailable.activeStates, equals(sampleStates));

          // 2. corpusAvailableManifestUnavailable
          final manifestUnavailableMap = ReviewCorpusIdentityMap.degraded(
            activeWordIds: {'w1'},
          );
          expect(
            manifestUnavailableMap.availabilityState,
            CorpusAvailabilityState.corpusAvailableManifestUnavailable,
          );
          final resManifestUnavailable = ReviewStateReconciler.reconcile(
            states: sampleStates,
            corpusMap: manifestUnavailableMap,
          );
          expect(resManifestUnavailable.hasChanges, isFalse);
          expect(resManifestUnavailable.activeStates, equals(sampleStates));

          // 3. ready
          final readyMap = ReviewCorpusIdentityMap(
            activeWordIds: {'w1', 'w_alias_target'},
            activeSentenceIds: const {},
            aliases: [
              const ReviewIdAlias(
                itemType: ReviewItemType.word,
                from: 'w_legacy',
                to: 'w_alias_target',
              ),
            ],
            tombstones: const [],
          );
          expect(readyMap.availabilityState, CorpusAvailabilityState.ready);

          // Reconcile with ready map applies migrations cleanly
          final resReady = ReviewStateReconciler.reconcile(
            states: sampleStates,
            corpusMap: readyMap,
          );
          expect(resReady.hasChanges, isTrue);
          expect(resReady.activeStates.containsKey('w_alias_target'), isTrue);
          expect(resReady.renamedOldIds, contains('w_legacy'));
        },
      );
    });
  });
}
