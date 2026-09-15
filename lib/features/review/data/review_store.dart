// Offline-first persistence for item-level learning state.
//
// Storage: single SharedPreferences JSON map (key `review_states_v1`),
// versioned via [schemaVersion]. Format v3:
//   {"schemaVersion": 3, "items": {itemId: <MemoryItemState.toMap()>}, "quarantine": {itemId: <MemoryItemState.toMap()>}}
// Legacy v1 (flat itemId -> state, no version key) and v2 (schemaVersion: 2)
// are migrated on load and rewritten in v3 on the next persist — learner progress survives
// app updates (P12). Cloud sync (Appwrite `review_states`) layers on
// top of this local cache: see review_state_sync.dart.
//
// Performance: one prefs read at startup; every mutation is a single
// prefs write of the compact map. No Appwrite reads on home open — the
// provider caches the decoded map and exposes cheap derived counts.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/hive_service.dart';
import '../domain/memory_scheduler.dart';
import '../domain/review_corpus_identity.dart';
import '../domain/review_item.dart';
import 'review_state_sync.dart';

class ReviewStore {
  static const storageKey = 'review_states_v1';

  /// Bump on any format change; load() migrates older persisted data.
  static const int schemaVersion = 3;
  static const maxItems = 2000;

  final SharedPreferences _prefs;
  final Map<String, MemoryItemState> _states;
  final Map<String, MemoryItemState> _quarantined;
  ReviewCorpusIdentityMap? _corpusMap;

  ReviewStore._(
    this._prefs,
    this._states, [
    Map<String, MemoryItemState>? quarantined,
    this._corpusMap,
  ]) : _quarantined = quarantined ?? {};

  static Future<ReviewStore> load(
    SharedPreferences prefs, {
    ReviewCorpusIdentityMap? corpusMap,
  }) async {
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      final store = ReviewStore._(prefs, {}, null, corpusMap);
      if (corpusMap != null) {
        store.reconcile(corpusMap);
      }
      return store;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return ReviewStore._(prefs, {});
      // v3 format: {"schemaVersion": 3, "items": {...}, "quarantine": {...}}.
      // v2 format: {"schemaVersion": 2, "items": {...}}.
      // v1 legacy: flat {itemId: state} — migrated in place, then
      // rewritten as v3 on the next persist.
      final itemsMap = decoded['items'] is Map
          ? Map<String, dynamic>.from(decoded['items'] as Map)
          : Map<String, dynamic>.from(decoded);
      final states = <String, MemoryItemState>{};
      itemsMap.forEach((key, value) {
        try {
          if (value is Map) {
            final item = MemoryItemState.fromMap(
              Map<String, dynamic>.from(value),
            );
            if (item.itemId.isNotEmpty) states[item.itemId] = item;
          }
        } catch (_) {
          // Corrupt entry: skip, keep the rest.
        }
      });

      final quarantined = <String, MemoryItemState>{};
      if (decoded['quarantine'] is Map) {
        final qMap = Map<String, dynamic>.from(decoded['quarantine'] as Map);
        qMap.forEach((key, value) {
          try {
            if (value is Map) {
              final item = MemoryItemState.fromMap(
                Map<String, dynamic>.from(value),
              );
              if (item.itemId.isNotEmpty) quarantined[item.itemId] = item;
            }
          } catch (_) {
            // Corrupt entry: skip.
          }
        });
      }

      final store = ReviewStore._(prefs, states, quarantined, corpusMap);
      if (corpusMap != null) {
        store.reconcile(corpusMap);
      }
      return store;
    } catch (_) {
      return ReviewStore._(prefs, {});
    }
  }

  List<MemoryItemState> all() => _states.values.toList(growable: false);

  MemoryItemState? get(String itemId) => _states[itemId];

  /// Writes a server state into the local cache during sync (server-newer
  /// wins, or item unknown locally). Bypasses the dirty/enqueue path so
  /// pull-merge cannot loop back into pushes. The local persist wins on
  /// the next mutation only via the normal scheduler flow.
  MemoryItemState adoptRemote(MemoryItemState item) {
    if (item.itemId.isEmpty) return item;
    _states[item.itemId] = item;
    _persist();
    return item;
  }

  /// Introduce if absent. Returns the (new or existing) state.
  /// Never overwrites existing scheduling data (duplicate-safe).
  MemoryItemState ensureIntroduced({
    required String itemId,
    required ReviewItemType itemType,
    required DateTime now,
  }) {
    final existing = _states[itemId];
    if (existing != null) return existing;
    if (_states.length >= maxItems) {
      return _evictAndIntroduce(itemId, itemType, now);
    }
    final introduced = MemoryScheduler.introduce(
      itemId: itemId,
      itemType: itemType,
      now: now,
    );
    _states[itemId] = introduced;
    _persist();
    return introduced;
  }

  /// Record a recall and reschedule. Auto-introduces unknown items first
  /// (so callers never need a separate "is this tracked?" check).
  /// Returns the new state plus whether a mastery threshold was just
  /// crossed (REVIEW / MASTERED) — used for retention analytics.
  ({MemoryItemState state, bool becameReview, bool becameMastered})
  recordRecall({
    required String itemId,
    required ReviewItemType itemType,
    required bool correct,
    required ReviewExerciseType exerciseType,
    required DateTime now,
    int? responseTimeMs,
  }) {
    final before =
        _states[itemId] ??
        ensureIntroduced(itemId: itemId, itemType: itemType, now: now);
    final wasReview = before.masteryState == MasteryState.review;
    final wasMastered = before.masteryState == MasteryState.mastered;
    final after = MemoryScheduler.recordRecall(
      before,
      RecallInput(
        correct: correct,
        exerciseType: exerciseType,
        now: now,
        responseTimeMs: responseTimeMs,
      ),
    );
    _states[itemId] = after;
    _persist();
    return (
      state: after,
      becameReview: !wasReview && after.masteryState == MasteryState.review,
      becameMastered:
          !wasMastered && after.masteryState == MasteryState.mastered,
    );
  }

  ReviewCorpusIdentityMap? get corpusMap => _corpusMap;

  CorpusAvailabilityState get availabilityState =>
      _corpusMap?.availabilityState ?? CorpusAvailabilityState.ready;

  Iterable<MemoryItemState> get _exposedStates {
    final map = _corpusMap;
    if (map == null) return _states.values;
    switch (map.availabilityState) {
      case CorpusAvailabilityState.ready:
        return _states.values;
      case CorpusAvailabilityState.corpusAvailableManifestUnavailable:
        return _states.values.where((item) => map.isActive(item.itemId));
      case CorpusAvailabilityState.corpusUnavailable:
        return const [];
    }
  }

  List<MemoryItemState> due(DateTime now, {int limit = 20}) =>
      MemoryScheduler.selectDue(_exposedStates, now, limit: limit);

  int dueCount(DateTime now) {
    var count = 0;
    for (final item in _exposedStates) {
      if (item.isDue(now)) count++;
    }
    return count;
  }

  int retainedCount() {
    var count = 0;
    for (final item in _exposedStates) {
      if (item.isRetained) count++;
    }
    return count;
  }

  Map<MasteryState, int> countsByState() {
    final counts = {
      MasteryState.fresh: 0,
      MasteryState.learning: 0,
      MasteryState.review: 0,
      MasteryState.mastered: 0,
    };
    for (final item in _exposedStates) {
      counts[item.masteryState] = (counts[item.masteryState] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> clear() async {
    _states.clear();
    await _prefs.remove(storageKey);
  }

  /// Hard cap guard: evict the least-valuable mastered item to make room.
  /// (Mastered items with the longest intervals are safest to drop; their
  /// content remains re-introducible from the verified corpus.)
  MemoryItemState _evictAndIntroduce(
    String itemId,
    ReviewItemType itemType,
    DateTime now,
  ) {
    MemoryItemState? victim;
    for (final item in _states.values) {
      if (item.masteryState != MasteryState.mastered) continue;
      if (victim == null || item.intervalDays > victim.intervalDays) {
        victim = item;
      }
    }
    victim ??= _states.values.first;
    _states.remove(victim.itemId);
    final introduced = MemoryScheduler.introduce(
      itemId: itemId,
      itemType: itemType,
      now: now,
    );
    _states[itemId] = introduced;
    _persist();
    return introduced;
  }

  ReviewReconciliationResult reconcile(ReviewCorpusIdentityMap corpusMap) {
    _corpusMap = corpusMap;
    final result = ReviewStateReconciler.reconcile(
      states: _states,
      corpusMap: corpusMap,
      existingQuarantine: _quarantined,
    );
    if (result.hasChanges) {
      _states
        ..clear()
        ..addAll(result.activeStates);
      _quarantined
        ..clear()
        ..addAll(result.quarantinedStates);
      _persist();
    }
    return result;
  }

  List<MemoryItemState> quarantined() =>
      _quarantined.values.toList(growable: false);

  MemoryItemState? getQuarantined(String itemId) => _quarantined[itemId];

  int quarantinedCount() => _quarantined.length;

  void _persist() {
    try {
      final payload = <String, dynamic>{
        'schemaVersion': schemaVersion,
        'items': {for (final e in _states.entries) e.key: e.value.toMap()},
        'quarantine': {
          for (final e in _quarantined.entries) e.key: e.value.toMap(),
        },
      };
      _prefs.setString(storageKey, jsonEncode(payload));
    } catch (_) {
      // Persistence must never break learning.
    }
  }
}

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

  @override
  Future<ReviewStore> build() async {
    final prefs = ref.watch(sharedPreferencesProvider);
    ReviewCorpusIdentityMap corpusMap;
    try {
      corpusMap = await ref.watch(corpusIdentityMapProvider.future);
    } catch (_) {
      corpusMap = ReviewCorpusIdentityMap.degraded();
    }
    return ReviewStore.load(prefs, corpusMap: corpusMap);
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
  /// sync can never break learning.
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

  /// Mutate then re-emit (state object is mutable internally; emit a new
  /// AsyncValue so watchers rebuild).
  ///
  /// Awaits the provider's own build future rather than loading a second
  /// store instance: a fallback load racing the in-flight build() would
  /// let the empty build result overwrite the just-recorded item.
  Future<({MemoryItemState state, bool becameReview, bool becameMastered})>
  recordRecall({
    required String itemId,
    required ReviewItemType itemType,
    required bool correct,
    required ReviewExerciseType exerciseType,
    int? responseTimeMs,
    DateTime? now,
  }) async {
    final store = await future;
    final result = store.recordRecall(
      itemId: itemId,
      itemType: itemType,
      correct: correct,
      exerciseType: exerciseType,
      now: (now ?? DateTime.now()).toUtc(),
      responseTimeMs: responseTimeMs,
    );
    state = AsyncValue.data(store);
    _enqueueCloudWrite(result.state);
    return result;
  }

  Future<MemoryItemState> ensureIntroduced({
    required String itemId,
    required ReviewItemType itemType,
    DateTime? now,
  }) async {
    final store = await future;
    final item = store.ensureIntroduced(
      itemId: itemId,
      itemType: itemType,
      now: (now ?? DateTime.now()).toUtc(),
    );
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
