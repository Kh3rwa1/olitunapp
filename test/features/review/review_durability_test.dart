// WS1 durability characterization: delayed/out-of-order/failed storage,
// account-switch mid-write, restart survival, single-write-per-mutation,
// quarantine scoping, owner-scoped clear, and no-eviction.
//
// Uses [InMemoryDelayedReviewStateRepository] — a controllable delayed
// fake — never SharedPreferences mocks alone.

import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/auth/account_scope.dart';
import 'package:itun/features/review/data/review_state_local_repository.dart';
import 'package:itun/features/review/data/review_store.dart';
import 'package:itun/features/review/domain/review_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final t0 = DateTime.utc(2026, 2, 1, 10);

  Future<SharedPreferences> freshPrefs() async {
    SharedPreferences.setMockInitialValues({});
    return SharedPreferences.getInstance();
  }

  Future<ReviewStore> loadWithFake(
    SharedPreferences prefs,
    InMemoryDelayedReviewStateRepository repo, {
    String? storageKey,
    AccountScope? scope,
  }) => ReviewStore.loadWithRepository(
    repo,
    prefs: prefs,
    storageKey: storageKey ?? 'review_states_test',
  );

  group('WS1 persistence boundary', () {
    test(
      'serialized: B never invokes persistence before A completes',
      () async {
        final prefs = await freshPrefs();
        final repo = InMemoryDelayedReviewStateRepository()
          ..delay = const Duration(milliseconds: 60);
        final store = await loadWithFake(prefs, repo);

        store.recordRecall(
          itemId: 'w1',
          itemType: ReviewItemType.word,
          correct: true,
          exerciseType: ReviewExerciseType.recognition,
          now: t0,
        );
        final futureA = store.persist();
        store.recordRecall(
          itemId: 'w1',
          itemType: ReviewItemType.word,
          correct: true,
          exerciseType: ReviewExerciseType.recognition,
          now: t0.add(const Duration(minutes: 1)),
        );
        final futureB = store.persist();

        await Future.wait([futureA, futureB]);
        // Two invocations, strictly in call order.
        expect(repo.invocationLog, hasLength(2));
        // Final durable state contains B (2 successes).
        final reloaded = await ReviewStore.loadWithRepository(
          repo,
          prefs: prefs,
          storageKey: 'review_states_test',
        );
        expect(reloaded.get('w1')?.successfulRecalls, 2);
      },
    );

    test(
      'failed A does not block B; policy is documented and observed',
      () async {
        final prefs = await freshPrefs();
        final failures = <String>[];
        final repo = InMemoryDelayedReviewStateRepository(
          observer: _RecordingObserver(failures),
        );
        final store = await loadWithFake(prefs, repo);

        store.recordRecall(
          itemId: 'w1',
          itemType: ReviewItemType.word,
          correct: true,
          exerciseType: ReviewExerciseType.recognition,
          now: t0,
        );
        repo.failNext = true;
        final okA = await store.persist();
        expect(okA, isFalse);

        store.recordRecall(
          itemId: 'w1',
          itemType: ReviewItemType.word,
          correct: false,
          exerciseType: ReviewExerciseType.recognition,
          now: t0.add(const Duration(minutes: 1)),
        );
        final okB = await store.persist();
        expect(okB, isTrue);

        // Failure was observed (never swallowed).
        expect(failures, hasLength(1));
        // Final durable state contains B's evidence.
        final reloaded = await ReviewStore.loadWithRepository(
          repo,
          prefs: prefs,
          storageKey: 'review_states_test',
        );
        expect(reloaded.get('w1')?.successfulRecalls, 1);
        expect(reloaded.get('w1')?.failedRecalls, 1);
      },
    );

    test('one logical recall causes exactly one durable write', () async {
      final prefs = await freshPrefs();
      final repo = InMemoryDelayedReviewStateRepository();
      final store = await loadWithFake(prefs, repo);
      await store.recordRecallDurable(
        itemId: 'w1',
        itemType: ReviewItemType.word,
        correct: true,
        exerciseType: ReviewExerciseType.typing,
        now: t0,
      );
      expect(repo.saveCallCount, 1);
    });

    test('one logical introduction causes exactly one durable write', () async {
      final prefs = await freshPrefs();
      final repo = InMemoryDelayedReviewStateRepository();
      final store = await loadWithFake(prefs, repo);
      await store.ensureIntroducedDurable(
        itemId: 'w1',
        itemType: ReviewItemType.word,
        now: t0,
      );
      expect(repo.saveCallCount, 1);
    });

    test('pure mutations never persist implicitly', () async {
      final prefs = await freshPrefs();
      final repo = InMemoryDelayedReviewStateRepository();
      final store = await loadWithFake(prefs, repo);
      store.recordRecall(
        itemId: 'w1',
        itemType: ReviewItemType.word,
        correct: true,
        exerciseType: ReviewExerciseType.recognition,
        now: t0,
      );
      store.ensureIntroduced(
        itemId: 'w2',
        itemType: ReviewItemType.word,
        now: t0,
      );
      store.adoptRemote(
        MemoryItemState(
          itemId: 'w3',
          itemType: ReviewItemType.word,
          introducedAt: t0,
          nextReviewAt: t0,
        ),
      );
      expect(repo.saveCallCount, 0);
    });

    test('latest acknowledged mutation survives process restart', () async {
      final prefs = await freshPrefs();
      final repo = InMemoryDelayedReviewStateRepository();
      var store = await loadWithFake(prefs, repo);
      await store.recordRecallDurable(
        itemId: 'w1',
        itemType: ReviewItemType.word,
        correct: true,
        exerciseType: ReviewExerciseType.typing,
        now: t0,
      );
      await store.recordRecallDurable(
        itemId: 'w1',
        itemType: ReviewItemType.word,
        correct: true,
        exerciseType: ReviewExerciseType.typing,
        now: t0.add(const Duration(hours: 1)),
      );
      // Simulate restart: new store over the same repository.
      store = await ReviewStore.loadWithRepository(
        repo,
        prefs: prefs,
        storageKey: 'review_states_test',
      );
      expect(store.get('w1')?.successfulRecalls, 4); // typing counts double
      expect(store.get('w1')?.typingSuccesses, 2);
    });

    test(
      'no cross-account write when scope changes (captured key wins)',
      () async {
        final prefs = await freshPrefs();
        final repo = InMemoryDelayedReviewStateRepository();
        final scopeA = AccountScope.forTest(prefs, userId: 'userA');
        final storeA = await ReviewStore.loadWithRepository(
          repo,
          prefs: prefs,
          storageKey: scopeA.reviewKey,
        );
        storeA.recordRecall(
          itemId: 'w1',
          itemType: ReviewItemType.word,
          correct: true,
          exerciseType: ReviewExerciseType.recognition,
          now: t0,
        );
        // Account switches before durability completes.
        await AccountScope.signOut(prefs);
        final scopeB = AccountScope.forTest(prefs, userId: 'userB');
        // The pending write still lands under A's captured key.
        await storeA.persist();
        expect(repo.backing[scopeA.reviewKey], isNotNull);
        expect(repo.backing[scopeB.reviewKey], isNull);
        expect(repo.backing[scopeA.reviewKey]!, contains('w1'));
      },
    );

    test('account B never sees account A state (scoped keys)', () async {
      final prefs = await freshPrefs();
      final repo = InMemoryDelayedReviewStateRepository();
      final scopeA = AccountScope.forTest(prefs, userId: 'userA');
      final scopeB = AccountScope.forTest(prefs, userId: 'userB');
      final storeA = await ReviewStore.loadWithRepository(
        repo,
        prefs: prefs,
        storageKey: scopeA.reviewKey,
      );
      await storeA.recordRecallDurable(
        itemId: 'w1',
        itemType: ReviewItemType.word,
        correct: true,
        exerciseType: ReviewExerciseType.recognition,
        now: t0,
      );
      final storeB = await ReviewStore.loadWithRepository(
        repo,
        prefs: prefs,
        storageKey: scopeB.reviewKey,
      );
      expect(storeB.get('w1'), isNull);
      expect(storeB.all(), isEmpty);
    });

    test('quarantine is account-scoped', () async {
      final prefs = await freshPrefs();
      final repo = InMemoryDelayedReviewStateRepository();
      final scopeA = AccountScope.forTest(prefs, userId: 'userA');
      final scopeB = AccountScope.forTest(prefs, userId: 'userB');
      final storeA = await ReviewStore.loadWithRepository(
        repo,
        prefs: prefs,
        storageKey: scopeA.reviewKey,
      );
      storeA.ensureIntroduced(
        itemId: 'w_orphan',
        itemType: ReviewItemType.word,
        now: t0,
      );
      await storeA.persist();
      final storeB = await ReviewStore.loadWithRepository(
        repo,
        prefs: prefs,
        storageKey: scopeB.reviewKey,
      );
      expect(storeB.quarantinedCount(), 0);
      expect(storeB.get('w_orphan'), isNull);
    });

    test(
      'clear removes active+quarantine for only the current owner',
      () async {
        final prefs = await freshPrefs();
        final repo = InMemoryDelayedReviewStateRepository();
        final scopeA = AccountScope.forTest(prefs, userId: 'userA');
        final scopeB = AccountScope.forTest(prefs, userId: 'userB');
        final storeA = await ReviewStore.loadWithRepository(
          repo,
          prefs: prefs,
          storageKey: scopeA.reviewKey,
        );
        final storeB = await ReviewStore.loadWithRepository(
          repo,
          prefs: prefs,
          storageKey: scopeB.reviewKey,
        );
        await storeA.ensureIntroducedDurable(
          itemId: 'w_a',
          itemType: ReviewItemType.word,
          now: t0,
        );
        await storeB.ensureIntroducedDurable(
          itemId: 'w_b',
          itemType: ReviewItemType.word,
          now: t0,
        );
        await storeA.clear();
        expect(storeA.all(), isEmpty);
        final reloadedB = await ReviewStore.loadWithRepository(
          repo,
          prefs: prefs,
          storageKey: scopeB.reviewKey,
        );
        expect(reloadedB.get('w_b'), isNotNull);
      },
    );

    test('no arbitrary learning item is ever evicted (cap removed)', () async {
      final prefs = await freshPrefs();
      final repo = InMemoryDelayedReviewStateRepository();
      final store = await loadWithFake(prefs, repo);
      // Exceed the retired 2,000 cap with fresh items: all must survive.
      for (var i = 0; i < 2100; i++) {
        store.ensureIntroduced(
          itemId: 'w_$i',
          itemType: ReviewItemType.word,
          now: t0,
        );
      }
      expect(store.all(), hasLength(2100));
      expect(await store.persist(), isTrue);
      final reloaded = await ReviewStore.loadWithRepository(
        repo,
        prefs: prefs,
        storageKey: 'review_states_test',
      );
      expect(reloaded.all(), hasLength(2100));
    });

    test('storage corruption degrades to empty without throwing', () async {
      final prefs = await freshPrefs();
      final repo = InMemoryDelayedReviewStateRepository();
      repo.backing['review_states_test'] = 'not-json{{{';
      final store = await loadWithFake(prefs, repo);
      expect(store.all(), isEmpty);
    });
  });
}

class _RecordingObserver implements ReviewStorageObserver {
  final List<String> failures;
  _RecordingObserver(this.failures);
  @override
  void onSaveFailure({
    required String storageKey,
    required Object error,
    required int itemCount,
  }) {
    failures.add(storageKey);
  }

  @override
  void onLoadFailure({required String storageKey, required Object error}) {}
}
