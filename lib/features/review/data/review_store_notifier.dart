// ReviewStore Riverpod wiring and the single mutation transaction.
// (Store + repository live in review_store.dart /
// review_state_local_repository.dart.)
//
// Transaction per logical mutation:
// capture scope, validate, compute (pure), persist under captured scope,
// re-verify scope, publish, enqueue cloud, replay. Scope change raises
// typed AccountScopeError without publishing stale state; persist failure
// reports durable:false and never enqueues cloud writes.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/auth/account_scope.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/storage/hive_service.dart';
import '../domain/review_corpus_identity.dart';
import '../domain/review_item.dart';
import 'review_state_local_repository.dart';
import 'review_state_sync.dart';
import 'review_store.dart';

/// Async load-once provider; UI watches the synchronous derived providers
/// below so home-screen open never awaits storage.
final reviewStoreProvider =
    AsyncNotifierProvider<ReviewStoreNotifier, ReviewStore>(
      ReviewStoreNotifier.new,
    );

class ReviewStoreNotifier extends AsyncNotifier<ReviewStore> {
  /// Cloud sync attached by the app-root sync loop (review_sync_init).
  /// Null in bare test containers and for guests — the notifier never
  /// constructs Appwrite providers itself, so unit tests keep running
  /// local-only with zero behavior change.
  ReviewStateSync? _attachedSync;
  AccountScope? _scope;
  StreamSubscription<SharedPreferences>? _scopeSubscription;

  @override
  Future<ReviewStore> build() async {
    final prefs = ref.watch(sharedPreferencesProvider);
    final scope = AccountScope.capture(prefs);
    _scope = scope;

    _scopeSubscription?.cancel();
    _scopeSubscription = AccountScope.changes.listen((changedPrefs) {
      final newScope = AccountScope.capture(changedPrefs);
      if (_scope?.userId != newScope.userId ||
          _scope?.isGuest != newScope.isGuest) {
        _scope = newScope;
        ref.invalidateSelf();
      }
    });

    ref.onDispose(() {
      _scopeSubscription?.cancel();
      _scopeSubscription = null;
    });

    ReviewCorpusIdentityMap corpusMap;
    try {
      corpusMap = await ref.watch(corpusIdentityMapProvider.future);
    } catch (_) {
      corpusMap = ReviewCorpusIdentityMap.degraded();
    }
    return ReviewStore.load(prefs, corpusMap: corpusMap, scope: scope);
  }

  /// Awaits the loaded store for external users (sync service). Public so
  /// plain providers can read it without touching the protected `future`.
  Future<ReviewStore> current() => future;

  /// Called once by the app-root sync wiring. Idempotent.
  void attachSync(ReviewStateSync sync) {
    _attachedSync = sync;
  }

  /// Re-emits the current store so Riverpod watchers (e.g. dueReviewCountProvider)
  /// update immediately when remote sync adopts new items.
  void notifyStoreChanged() {
    final currentStore = state.valueOrNull;
    if (currentStore != null) {
      state = AsyncValue.data(currentStore);
    }
  }

  /// Durable cloud write for one local mutation. Enqueues locally, then
  /// opportunistically drains the outbox (near-zero push latency online;
  /// a cheap local scan offline). No-op unless sync is attached — cloud
  /// sync can never break learning. Called ONLY after local durability
  /// has been confirmed; a failed local persist never reaches the cloud.
  void _enqueueCloudWrite(MemoryItemState item) {
    final sync = _attachedSync;
    if (sync == null) return;
    try {
      // ignore: discarded_futures
      sync.enqueueLocalMutation(item).then((_) => sync.replayQueued());
    } catch (_) {
      // Cloud sync must never break learning.
    }
  }

  /// ONE unambiguous transaction per logical mutation:
  /// 1. capture current account scope
  /// 2. validate item identity
  /// 3. compute next state (pure, in-memory)
  /// 4. persist state under the captured account scope (awaited)
  /// 5. confirm the account scope is still current
  /// 6. publish Riverpod state
  /// 7. enqueue cloud mutation (only after local durability)
  /// 8. trigger opportunistic replay
  ///
  /// If the account changes mid-operation the write already landed under
  /// the captured (original) owner's key, so it is retained for that
  /// owner — but stale state is NOT published and a typed [AccountScopeError]
  /// is thrown instead of silently crossing accounts.
  ///
  /// If local persistence fails, the mutation is NOT reported as durable:
  /// [durable] is false, no cloud write is enqueued, the failure is logged
  /// to observability, and the in-memory transition is still published so
  /// the session UI stays consistent (restart will reload the last
  /// acknowledged durable state).
  Future<
    ({
      MemoryItemState state,
      bool becameReview,
      bool becameMastered,
      bool durable,
    })
  >
  recordRecall({
    required String itemId,
    required ReviewItemType itemType,
    required bool correct,
    required ReviewExerciseType exerciseType,
    int? responseTimeMs,
    DateTime? now,
  }) async {
    // 1. Capture current account scope.
    final prefs = ref.read(sharedPreferencesProvider);
    final captured = AccountScope.capture(prefs);
    // 2. Validate item identity (never track empty/whitespace IDs).
    final trimmedId = itemId.trim();
    if (trimmedId.isEmpty) {
      throw ArgumentError('recordRecall requires a non-empty itemId');
    }
    // 3. Compute next state (pure — no implicit persistence).
    final store = await future;
    final result = store.recordRecall(
      itemId: trimmedId,
      itemType: itemType,
      correct: correct,
      exerciseType: exerciseType,
      now: (now ?? DateTime.now()).toUtc(),
      responseTimeMs: responseTimeMs,
    );
    // 4. Persist under the captured account scope (awaited; exactly one
    //    durable write per logical mutation).
    final durable = await store.persist();
    if (!durable) {
      AppLogger.debug(
        'ReviewStoreNotifier: local persist failed for $trimmedId '
        '(owner: ${captured.reviewKey}); mastery NOT reported as durable.',
      );
      // Publish in-memory so the session stays consistent, but mark
      // undurable and do NOT enqueue cloud writes.
      state = AsyncValue.data(store);
      return (
        state: result.state,
        becameReview: result.becameReview,
        becameMastered: result.becameMastered,
        durable: false,
      );
    }
    // 5. Confirm the account scope is still current.
    final live = AccountScope.capture(prefs);
    if (live.reviewKey != captured.reviewKey) {
      // The durable write landed under the captured owner's key and is
      // retained there; do not publish stale state into the new account.
      AppLogger.debug(
        'ReviewStoreNotifier: account changed mid-mutation; '
        'not publishing stale state.',
      );
      throw AccountScopeError(
        expectedOwner: captured.reviewKey,
        actualOwner: live.reviewKey,
      );
    }
    // 6. Publish.
    state = AsyncValue.data(store);
    // 7-8. Enqueue cloud mutation + opportunistic replay (post-durability).
    _enqueueCloudWrite(result.state);
    return (
      state: result.state,
      becameReview: result.becameReview,
      becameMastered: result.becameMastered,
      durable: true,
    );
  }

  Future<MemoryItemState> ensureIntroduced({
    required String itemId,
    required ReviewItemType itemType,
    DateTime? now,
  }) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final captured = AccountScope.capture(prefs);
    final trimmedId = itemId.trim();
    if (trimmedId.isEmpty) {
      throw ArgumentError('ensureIntroduced requires a non-empty itemId');
    }
    final store = await future;
    final item = store.ensureIntroduced(
      itemId: trimmedId,
      itemType: itemType,
      now: (now ?? DateTime.now()).toUtc(),
    );
    final durable = await store.persist();
    if (!durable) {
      AppLogger.debug(
        'ReviewStoreNotifier: local persist failed on introduce for '
        '$trimmedId; reporting undurable.',
      );
      state = AsyncValue.data(store);
      return item;
    }
    final live = AccountScope.capture(prefs);
    if (live.reviewKey != captured.reviewKey) {
      throw AccountScopeError(
        expectedOwner: captured.reviewKey,
        actualOwner: live.reviewKey,
      );
    }
    state = AsyncValue.data(store);
    _enqueueCloudWrite(item);
    return item;
  }
}

/// Injectable clock (tests override with a fixed time).
final reviewClockProvider = Provider<DateTime Function()>((ref) {
  return () => DateTime.now().toUtc();
});

/// Due queue (max 20). Synchronous off the loaded store; empty while loading.
final dueReviewItemsProvider = Provider<List<MemoryItemState>>((ref) {
  final store = ref.watch(reviewStoreProvider).valueOrNull;
  if (store == null) return const [];
  return store.due(ref.watch(reviewClockProvider)());
});

final dueReviewCountProvider = Provider<int>((ref) {
  final store = ref.watch(reviewStoreProvider).valueOrNull;
  if (store == null) return 0;
  return store.dueCount(ref.watch(reviewClockProvider)());
});

/// Measurable retention headline: "N items retained".
final retainedItemsCountProvider = Provider<int>((ref) {
  final store = ref.watch(reviewStoreProvider).valueOrNull;
  if (store == null) return 0;
  return store.retainedCount();
});
