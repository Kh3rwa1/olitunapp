// ReviewStore tests: offline-first persistence, duplicate prevention,
// sync-conflict-safe merge (last-writer-wins per item is acceptable v1;
// ensureIntroduced never clobbers scheduling data).

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/review/data/review_store.dart';
import 'package:itun/features/review/domain/review_corpus_identity.dart';
import 'package:itun/features/review/domain/review_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final t0 = DateTime.utc(2026, 1, 1, 9);

  Future<ReviewStore> freshStore() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return ReviewStore.load(prefs);
  }

  group('ReviewStore', () {
    test('loads empty when nothing persisted (offline-first)', () async {
      final store = await freshStore();
      expect(store.all(), isEmpty);
      expect(store.dueCount(t0), 0);
      expect(store.retainedCount(), 0);
    });

    test(
      'ensureIntroduced is duplicate-safe (never resets progress)',
      () async {
        final store = await freshStore();
        final first = store.ensureIntroduced(
          itemId: 'w1',
          itemType: ReviewItemType.word,
          now: t0,
        );
        final progressed = store.recordRecall(
          itemId: 'w1',
          itemType: ReviewItemType.word,
          correct: true,
          exerciseType: ReviewExerciseType.recognition,
          now: t0,
        );
        final again = store.ensureIntroduced(
          itemId: 'w1',
          itemType: ReviewItemType.word,
          now: t0.add(const Duration(days: 30)),
        );
        expect(again.successfulRecalls, progressed.state.successfulRecalls);
        expect(again.nextReviewAt, progressed.state.nextReviewAt);
        expect(first.introducedAt, again.introducedAt);
      },
    );

    test('wrong answers cause earlier review than correct ones', () async {
      final store = await freshStore();
      final ok = store.recordRecall(
        itemId: 'good',
        itemType: ReviewItemType.word,
        correct: true,
        exerciseType: ReviewExerciseType.recognition,
        now: t0,
      );
      final bad = store.recordRecall(
        itemId: 'bad',
        itemType: ReviewItemType.word,
        correct: false,
        exerciseType: ReviewExerciseType.recognition,
        now: t0,
      );
      expect(bad.state.nextReviewAt.isBefore(ok.state.nextReviewAt), isTrue);
      // The failed item is due again within the hour; the passed one is not
      // due for a day.
      expect(
        store.due(t0.add(const Duration(hours: 1))).map((e) => e.itemId),
        contains('bad'),
      );
      expect(
        store.due(t0.add(const Duration(hours: 1))).map((e) => e.itemId),
        isNot(contains('good')),
      );
    });

    test('typing results affect mastery faster than taps', () async {
      final store = await freshStore();
      final typed = store.recordRecall(
        itemId: 'w-type',
        itemType: ReviewItemType.word,
        correct: true,
        exerciseType: ReviewExerciseType.typing,
        now: t0,
      );
      final tapped = store.recordRecall(
        itemId: 'w-tap',
        itemType: ReviewItemType.word,
        correct: true,
        exerciseType: ReviewExerciseType.recognition,
        now: t0,
      );
      expect(
        typed.state.successfulRecalls,
        greaterThan(tapped.state.successfulRecalls),
      );
    });

    test('persists across loads (offline reload)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final first = await ReviewStore.load(prefs);
      first.recordRecall(
        itemId: 'w1',
        itemType: ReviewItemType.word,
        correct: true,
        exerciseType: ReviewExerciseType.typing,
        now: t0,
      );
      // Durability is explicit: pure mutations never persist implicitly.
      await first.persist();
      final second = await ReviewStore.load(prefs);
      expect(second.get('w1')?.successfulRecalls, 2);
      expect(second.get('w1')?.typingSuccesses, 1);
    });

    test('corrupt storage degrades to empty, never throws', () async {
      SharedPreferences.setMockInitialValues({
        'review_states_v1': 'not-json{{{',
      });
      final prefs = await SharedPreferences.getInstance();
      final store = await ReviewStore.load(prefs);
      expect(store.all(), isEmpty);
    });

    test('corrupt entries are skipped, good ones survive', () async {
      SharedPreferences.setMockInitialValues({
        'review_states_v1': jsonEncode({
          'good': {
            'itemId': 'good',
            'itemType': 'word',
            'introducedAt': t0.toIso8601String(),
            'nextReviewAt': t0.toIso8601String(),
          },
          'bad': 'garbage',
        }),
      });
      final prefs = await SharedPreferences.getInstance();
      final store = await ReviewStore.load(prefs);
      expect(store.get('good')?.itemId, 'good');
      expect(store.all(), hasLength(1));
    });

    test('retainedCount/countsByState reflect real learning', () async {
      final store = await freshStore();
      store.ensureIntroduced(
        itemId: 'new',
        itemType: ReviewItemType.word,
        now: t0,
      );
      var now = t0;
      for (var i = 0; i < 2; i++) {
        store.recordRecall(
          itemId: 'kept',
          itemType: ReviewItemType.word,
          correct: true,
          exerciseType: ReviewExerciseType.recognition,
          now: now,
        );
        now = store.get('kept')!.nextReviewAt;
      }
      expect(store.retainedCount(), 1);
      final counts = store.countsByState();
      expect(counts[MasteryState.fresh], 1);
      expect(counts[MasteryState.review], 1);
    });

    test('becameMastered fires exactly once', () async {
      final store = await freshStore();
      var now = t0;
      var firings = 0;
      for (var i = 0; i < 8; i++) {
        final result = store.recordRecall(
          itemId: 'w1',
          itemType: ReviewItemType.word,
          correct: true,
          exerciseType: ReviewExerciseType.recognition,
          now: now,
        );
        if (result.becameMastered) firings++;
        now = result.state.nextReviewAt;
      }
      expect(firings, 1);
    });

    test('clear wipes local state', () async {
      final store = await freshStore();
      store.ensureIntroduced(
        itemId: 'w1',
        itemType: ReviewItemType.word,
        now: t0,
      );
      await store.clear();
      expect(store.all(), isEmpty);
    });

    group('Schema versions, migrations, and quarantine persistence', () {
      Map<String, dynamic> itemMap(
        String id, {
        ReviewItemType type = ReviewItemType.word,
      }) => {
        'itemId': id,
        'itemType': type == ReviewItemType.word ? 'word' : 'sentence',
        'introducedAt': t0.toIso8601String(),
        'nextReviewAt': t0.add(const Duration(days: 3)).toIso8601String(),
        'lastPresentedAt': t0.toIso8601String(),
        'lastReviewedAt': t0.toIso8601String(),
        'successfulRecalls': 4,
        'failedRecalls': 1,
        'lapseCount': 0,
        'ease': 2.5,
        'intervalDays': 3.0,
        'masteryState': 'review',
        'responseTimeMs': 950,
        'exerciseType': 'typing',
        'typingSuccesses': 3,
        'firstRecallAt': t0.toIso8601String(),
      };

      test('v1 flat format migrates to v3 without losing state', () async {
        final v1Payload = jsonEncode({
          'w1': itemMap('w1'),
          'w2': itemMap('w2'),
        });
        SharedPreferences.setMockInitialValues({
          ReviewStore.storageKey: v1Payload,
        });
        final prefs = await SharedPreferences.getInstance();
        final store = await ReviewStore.load(prefs);

        expect(store.all(), hasLength(2));
        expect(store.get('w1')?.successfulRecalls, 4);
        expect(store.get('w2')?.typingSuccesses, 3);
        expect(store.quarantined(), isEmpty);

        // Next mutation persists in v3 format (explicit durability: pure
        // mutations never persist implicitly).
        store.recordRecall(
          itemId: 'w1',
          itemType: ReviewItemType.word,
          correct: true,
          exerciseType: ReviewExerciseType.typing,
          now: t0.add(const Duration(days: 3)),
        );
        await store.persist();

        final rawAfter = prefs.getString(ReviewStore.storageKey)!;
        final decoded = jsonDecode(rawAfter) as Map<String, dynamic>;
        expect(decoded['schemaVersion'], 3);
        expect(decoded['items'], isA<Map>());
        expect(decoded['quarantine'], isA<Map>());
      });

      test('v2 format migrates to v3 without losing state', () async {
        final v2Payload = jsonEncode({
          'schemaVersion': 2,
          'items': {'w1': itemMap('w1')},
        });
        SharedPreferences.setMockInitialValues({
          ReviewStore.storageKey: v2Payload,
        });
        final prefs = await SharedPreferences.getInstance();
        final store = await ReviewStore.load(prefs);

        expect(store.all(), hasLength(1));
        expect(store.get('w1')?.itemId, 'w1');
        expect(store.quarantined(), isEmpty);

        // Mutate to trigger persist in v3 format (explicit durability).
        store.recordRecall(
          itemId: 'w1',
          itemType: ReviewItemType.word,
          correct: true,
          exerciseType: ReviewExerciseType.recognition,
          now: t0.add(const Duration(days: 3)),
        );
        await store.persist();

        final rawAfter = prefs.getString(ReviewStore.storageKey)!;
        final decoded = jsonDecode(rawAfter) as Map<String, dynamic>;
        expect(decoded['schemaVersion'], 3);
        expect(decoded['quarantine'], isA<Map>());
      });

      test(
        'v3 round trip preserves both active and quarantined states',
        () async {
          final v3Payload = jsonEncode({
            'schemaVersion': 3,
            'items': {'w_active': itemMap('w_active')},
            'quarantine': {'w_orphan': itemMap('w_orphan')},
          });
          SharedPreferences.setMockInitialValues({
            ReviewStore.storageKey: v3Payload,
          });
          final prefs = await SharedPreferences.getInstance();
          final store = await ReviewStore.load(prefs);

          expect(store.all(), hasLength(1));
          expect(store.get('w_active')?.itemId, 'w_active');
          expect(store.quarantinedCount(), 1);
          expect(store.getQuarantined('w_orphan')?.itemId, 'w_orphan');
        },
      );

      test('quarantine persists across restart', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final store = await ReviewStore.load(prefs);

        store.ensureIntroduced(
          itemId: 'w_orphan',
          itemType: ReviewItemType.word,
          now: t0,
        );

        final corpus = ReviewCorpusIdentityMap(
          activeWordIds: {'w_other'},
          activeSentenceIds: const {},
          aliases: const [],
          tombstones: const [],
        );
        final recon = store.reconcile(corpus);
        expect(recon.hasChanges, isTrue);
        expect(store.quarantinedCount(), 1);
        expect(store.get('w_orphan'), isNull);
        // Reconciliation is pure in memory; durability is explicit.
        await store.persist();

        // Restart store by reloading from prefs
        final store2 = await ReviewStore.load(prefs);
        expect(store2.get('w_orphan'), isNull);
        expect(store2.quarantinedCount(), 1);
        expect(store2.getQuarantined('w_orphan')?.itemId, 'w_orphan');
      });

      test(
        'malformed quarantine entry is skipped safely without crashing',
        () async {
          final payload = jsonEncode({
            'schemaVersion': 3,
            'items': {'w_good': itemMap('w_good')},
            'quarantine': {
              'corrupt1': 'not a map',
              'corrupt2': {'itemId': ''},
              'corrupt3': {'broken': 123},
              'q_good': itemMap('q_good'),
            },
          });
          SharedPreferences.setMockInitialValues({
            ReviewStore.storageKey: payload,
          });
          final prefs = await SharedPreferences.getInstance();
          final store = await ReviewStore.load(prefs);

          expect(store.get('w_good')?.itemId, 'w_good');
          expect(store.quarantinedCount(), 1);
          expect(store.getQuarantined('q_good')?.itemId, 'q_good');
        },
      );

      test('idempotent loading and reconciliation', () async {
        final v2Payload = jsonEncode({
          'schemaVersion': 2,
          'items': {'w_alias': itemMap('w_alias')},
        });
        SharedPreferences.setMockInitialValues({
          ReviewStore.storageKey: v2Payload,
        });
        final prefs = await SharedPreferences.getInstance();

        final corpus = ReviewCorpusIdentityMap(
          activeWordIds: {'w_canonical'},
          activeSentenceIds: const {},
          aliases: const [
            ReviewIdAlias(
              itemType: ReviewItemType.word,
              from: 'w_alias',
              to: 'w_canonical',
            ),
          ],
          tombstones: const [],
        );

        final store1 = await ReviewStore.load(prefs, corpusMap: corpus);
        expect(store1.get('w_canonical')?.itemId, 'w_canonical');

        // Second reconcile with same corpus produces no changes
        final recon2 = store1.reconcile(corpus);
        expect(recon2.hasChanges, isFalse);
        expect(recon2.renamedOldIds, isEmpty);

        // Reload store
        final store2 = await ReviewStore.load(prefs, corpusMap: corpus);
        expect(store2.get('w_canonical')?.itemId, 'w_canonical');
      });

      test('no storage rewrite when reconciliation makes no changes', () async {
        final originalPayload = jsonEncode({
          'schemaVersion': 2,
          'items': {'w_valid': itemMap('w_valid')},
        });
        SharedPreferences.setMockInitialValues({
          ReviewStore.storageKey: originalPayload,
        });
        final prefs = await SharedPreferences.getInstance();

        final corpus = ReviewCorpusIdentityMap(
          activeWordIds: {'w_valid'},
          activeSentenceIds: const {},
          aliases: const [],
          tombstones: const [],
        );

        // Load and reconcile
        final store = await ReviewStore.load(prefs, corpusMap: corpus);
        expect(store.get('w_valid')?.itemId, 'w_valid');

        // Storage was NOT rewritten because reconciliation made no changes
        final stored = prefs.getString(ReviewStore.storageKey);
        expect(stored, equals(originalPayload));
      });
    });

    group('Degraded corpus mode and availability states', () {
      Map<String, dynamic> itemMap(
        String id, {
        ReviewItemType type = ReviewItemType.word,
      }) => {
        'itemId': id,
        'itemType': type == ReviewItemType.word ? 'word' : 'sentence',
        'introducedAt': t0.toIso8601String(),
        'nextReviewAt': t0.add(const Duration(days: 3)).toIso8601String(),
        'lastPresentedAt': t0.toIso8601String(),
        'lastReviewedAt': t0.toIso8601String(),
        'successfulRecalls': 4,
        'failedRecalls': 0,
        'lapseCount': 0,
        'ease': 2.5,
        'intervalDays': 3.0,
        'masteryState': 'learning',
        'lastResponseTimeMs': 1200,
        'lastExerciseType': 'flashcard',
        'typingSuccesses': 0,
        'firstRecallAt': t0.toIso8601String(),
      };

      test(
        'corpusAvailableManifestUnavailable excludes unverified items from queues without deleting them',
        () async {
          SharedPreferences.setMockInitialValues({});
          final prefs = await SharedPreferences.getInstance();
          final degradedMap = ReviewCorpusIdentityMap.degraded(
            activeWordIds: {'w_verified'},
          );
          expect(
            degradedMap.availabilityState,
            CorpusAvailabilityState.corpusAvailableManifestUnavailable,
          );

          final store = await ReviewStore.load(prefs, corpusMap: degradedMap);
          store.ensureIntroduced(
            itemId: 'w_verified',
            itemType: ReviewItemType.word,
            now: t0,
          );
          store.ensureIntroduced(
            itemId: 'w_unverified',
            itemType: ReviewItemType.word,
            now: t0,
          );

          expect(
            store.availabilityState,
            CorpusAvailabilityState.corpusAvailableManifestUnavailable,
          );
          // Stored items are preserved in memory and storage
          expect(store.get('w_verified'), isNotNull);
          expect(store.get('w_unverified'), isNotNull);
          expect(store.all(), hasLength(2));
          expect(store.quarantined(), isEmpty);

          // Queues and counts exclude unverified items
          final dueList = store.due(t0.add(const Duration(days: 10)));
          expect(dueList.map((e) => e.itemId), contains('w_verified'));
          expect(dueList.map((e) => e.itemId), isNot(contains('w_unverified')));
          expect(store.dueCount(t0.add(const Duration(days: 10))), 1);
          expect(store.retainedCount(), 0);
          final counts = store.countsByState();
          expect(counts[MasteryState.fresh], 1); // Only w_verified is counted
        },
      );

      test(
        'corpusUnavailable excludes all items from queues without deleting them',
        () async {
          SharedPreferences.setMockInitialValues({});
          final prefs = await SharedPreferences.getInstance();
          final unavailableMap = ReviewCorpusIdentityMap.degraded();
          expect(
            unavailableMap.availabilityState,
            CorpusAvailabilityState.corpusUnavailable,
          );

          final store = await ReviewStore.load(
            prefs,
            corpusMap: unavailableMap,
          );
          store.ensureIntroduced(
            itemId: 'w1',
            itemType: ReviewItemType.word,
            now: t0,
          );

          expect(
            store.availabilityState,
            CorpusAvailabilityState.corpusUnavailable,
          );
          expect(store.get('w1'), isNotNull);
          expect(store.all(), hasLength(1));
          expect(store.due(t0.add(const Duration(days: 10))), isEmpty);
          expect(store.dueCount(t0.add(const Duration(days: 10))), 0);
          expect(store.retainedCount(), 0);
          final counts = store.countsByState();
          expect(counts[MasteryState.fresh], 0);
        },
      );

      test(
        'clean recovery to ready restores queues and performs normal reconciliation',
        () async {
          SharedPreferences.setMockInitialValues({});
          final prefs = await SharedPreferences.getInstance();
          final degradedMap = ReviewCorpusIdentityMap.degraded(
            activeWordIds: {'w_verified'},
          );
          final store = await ReviewStore.load(prefs, corpusMap: degradedMap);
          store.ensureIntroduced(
            itemId: 'w_verified',
            itemType: ReviewItemType.word,
            now: t0,
          );
          store.ensureIntroduced(
            itemId: 'w_unverified',
            itemType: ReviewItemType.word,
            now: t0,
          );

          // In degraded mode: 1 due item exposed
          expect(store.due(t0.add(const Duration(days: 10))), hasLength(1));

          // Now manifest and full corpus load successfully
          final readyMap = ReviewCorpusIdentityMap(
            activeWordIds: {'w_verified', 'w_unverified'},
            activeSentenceIds: const {},
            aliases: const [],
            tombstones: const [],
          );
          expect(readyMap.availabilityState, CorpusAvailabilityState.ready);

          final result = store.reconcile(readyMap);
          expect(store.availabilityState, CorpusAvailabilityState.ready);
          expect(store.due(t0.add(const Duration(days: 10))), hasLength(2));
          expect(store.dueCount(t0.add(const Duration(days: 10))), 2);
          expect(result.quarantinedStates, isEmpty);
        },
      );

      test(
        'ReviewStoreNotifier build falls back to degraded map on error and avoids AsyncError',
        () async {
          final v2Payload = jsonEncode({
            'schemaVersion': 2,
            'items': {'w_persisted': itemMap('w_persisted')},
          });
          SharedPreferences.setMockInitialValues({
            ReviewStore.storageKey: v2Payload,
          });
          final prefs = await SharedPreferences.getInstance();
          final container = ProviderContainer(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              corpusIdentityMapProvider.overrideWith(
                (ref) =>
                    Future.error(Exception('Failed to load asset manifest')),
              ),
            ],
          );
          addTearDown(container.dispose);

          // Await notifier future - must not throw AsyncError
          final store = await container.read(reviewStoreProvider.future);
          expect(store, isNotNull);
          expect(
            store.availabilityState,
            CorpusAvailabilityState.corpusUnavailable,
          );
          // Persisted state was loaded cleanly
          expect(store.get('w_persisted'), isNotNull);
          // Home screen providers reading store directly or derived providers will not throw
          final dueItems = container.read(dueReviewItemsProvider);
          expect(dueItems, isEmpty);
          final dueCount = container.read(dueReviewCountProvider);
          expect(dueCount, 0);
        },
      );
    });
  });
}
