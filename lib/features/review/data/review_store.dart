// Offline-first persistence for item-level learning state.
//
// Storage: one versioned JSON document per account owner
// (key `review_states_<scope>`, legacy `review_states_v1` claimed once via
// the migration ledger), versioned via [schemaVersion]. Format v3:
//   {"schemaVersion": 3, "items": {itemId: <MemoryItemState.toMap()>}, "quarantine": {itemId: <MemoryItemState.toMap()>}}
// Legacy v1 (flat itemId -> state, no version key) and v2 (schemaVersion: 2)
// are migrated on load and rewritten in v3 on the next persist — learner progress survives
// app updates (P12). Cloud sync (Appwrite `review_states`) layers on
// top of this local cache: see review_state_sync.dart.
//
// Persistence boundary: exactly one — [ReviewStateLocalRepository]
// (see review_state_local_repository.dart). [ReviewStore] mutation methods
// ([recordRecall], [ensureIntroduced], [adoptRemote], [reconcile]) are pure
// in-memory transitions and NEVER persist implicitly. Durability is owned
// by [ReviewStoreNotifier], which executes the single mandated transaction
// sequence per logical mutation:
//
//   1. capture current account scope
//   2. validate item identity
//   3. compute next state (pure)
//   4. persist state under the captured account scope (awaited)
//   5. confirm the account scope is still current
//   6. publish Riverpod state
//   7. enqueue cloud mutation (only after local durability)
//   8. trigger opportunistic replay
//
// Retention: there is NO fixed item cap. A local cleanup must never delete
// fresh/learning/review items without explicit archival and remote
// coordination (see REMOTE coordination in review_state_sync.dart); the
// previous 2,000-item arbitrary eviction has been removed.
//
// Performance: one prefs read at startup; every mutation is a single
// serialized repository write. No Appwrite reads on home open — the
// provider caches the decoded map and exposes cheap derived counts.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/auth/account_scope.dart';
import '../domain/memory_scheduler.dart';
import '../domain/review_corpus_identity.dart';
import '../domain/review_item.dart';
import 'review_state_local_repository.dart';

class ReviewStore {
  static const storageKey = 'review_states_v1';

  /// Returns the account-scoped SharedPreferences key for the given scope.
  static String storageKeyForScope(AccountScope scope) => scope.reviewKey;

  /// Bump on any format change; load() migrates older persisted data.
  static const int schemaVersion = 3;

  /// Previous fixed cap, retained for documentation only.
  ///
  /// The cap used to evict an arbitrary active item once reached. It is NO
  /// LONGER enforced: learner state is never silently evicted merely because
  /// a threshold was reached. Local cleanup of mastered items requires
  /// explicit archival with remote coordination (not yet implemented; any
  /// future policy must preserve the no-active-eviction invariant and keep
  /// deleted state from reappearing via cloud sync).
  // ignore: unused_field
  static const int maxItems = 2000;

  final ReviewStateLocalRepository _repository;
  final String _storageKey;

  /// Owner label captured at load, used to detect cross-account misuse.
  /// Compared by [ReviewStoreNotifier] against the live scope; the store
  /// itself always persists under [_storageKey] (the captured owner's key)
  /// and never re-derives the key mid-transaction.
  final String _capturedOwnerLabel;
  final Map<String, MemoryItemState> _states;
  final Map<String, MemoryItemState> _quarantined;
  ReviewCorpusIdentityMap? _corpusMap;

  ReviewStore._(
    this._repository,
    this._states, [
    Map<String, MemoryItemState>? quarantined,
    this._corpusMap,
    String? storageKey,
    String? capturedOwnerLabel,
  ]) : _quarantined = quarantined ?? {},
       _storageKey = storageKey ?? ReviewStore.storageKey,
       _capturedOwnerLabel =
           capturedOwnerLabel ?? storageKey ?? ReviewStore.storageKey;

  String get storageKeyUsed => _storageKey;

  /// Owner label captured when this store was loaded. The notifier compares
  /// it with the live scope after each durable write.
  String get capturedOwnerLabel => _capturedOwnerLabel;

  @visibleForTesting
  ReviewStateLocalRepository get repository => _repository;

  /// Immutable snapshot of the current in-memory state for durability.
  ReviewStateSnapshot snapshot() => ReviewStateSnapshot(
    schemaVersion: schemaVersion,
    items: Map<String, MemoryItemState>.unmodifiable(Map.of(_states)),
    quarantine: Map<String, MemoryItemState>.unmodifiable(Map.of(_quarantined)),
  );

  static Future<ReviewStore> load(
    SharedPreferences prefs, {
    ReviewCorpusIdentityMap? corpusMap,
    String? storageKey,
    AccountScope? scope,
  }) async {
    final repository = SharedPreferencesReviewStateRepository(prefs);
    return loadWithRepository(
      repository,
      prefs: prefs,
      corpusMap: corpusMap,
      storageKey: storageKey,
      scope: scope,
    );
  }

  /// Test seam: load using an injected repository (e.g. the delayed fake).
  /// [prefs] is still required for the legacy-claim read path.
  static Future<ReviewStore> loadWithRepository(
    ReviewStateLocalRepository repository, {
    required SharedPreferences prefs,
    ReviewCorpusIdentityMap? corpusMap,
    String? storageKey,
    AccountScope? scope,
  }) async {
    final effectiveKey =
        storageKey ??
        (scope != null ? scope.reviewKey : ReviewStore.storageKey);
    final ownerLabel = scope != null
        ? scope.reviewKey
        : (storageKey ?? ReviewStore.storageKey);

    String? raw;
    bool needsLegacyMigration = false;
    final snapshot = await repository.load(effectiveKey);
    if (snapshot.items.isEmpty && snapshot.quarantine.isEmpty) {
      // Fall through to the legacy-claim path below (raw prefs read) so
      // unowned `review_states_v1` data is handled exactly once by the
      // migration ledger instead of being silently imported.
      raw = prefs.getString(effectiveKey);
      if ((raw == null || raw.isEmpty) &&
          effectiveKey != ReviewStore.storageKey &&
          prefs.containsKey(ReviewStore.storageKey)) {
        raw = prefs.getString(ReviewStore.storageKey);
        needsLegacyMigration = true;
      }
    }

    if (snapshot.items.isNotEmpty || snapshot.quarantine.isNotEmpty) {
      final store = ReviewStore._(
        repository,
        Map.of(snapshot.items),
        Map.of(snapshot.quarantine),
        corpusMap,
        effectiveKey,
        ownerLabel,
      );
      if (corpusMap != null) {
        store.reconcile(corpusMap);
      }
      return store;
    }

    if (raw == null || raw.isEmpty) {
      final store = ReviewStore._(
        repository,
        {},
        null,
        corpusMap,
        effectiveKey,
        ownerLabel,
      );
      if (corpusMap != null) {
        store.reconcile(corpusMap);
      }
      return store;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return ReviewStore._(
          repository,
          {},
          null,
          corpusMap,
          effectiveKey,
          ownerLabel,
        );
      }
      final map = Map<String, dynamic>.from(decoded);
      final itemsRaw = map['items'] is Map
          ? Map<String, dynamic>.from(map['items'] as Map)
          : Map<String, dynamic>.from(map);
      final items = <String, MemoryItemState>{};
      itemsRaw.forEach((key, value) {
        try {
          if (value is Map) {
            final item = MemoryItemState.fromMap(
              Map<String, dynamic>.from(value),
            );
            if (item.itemId.isNotEmpty) items[item.itemId] = item;
          }
        } catch (_) {
          // Corrupt entry: skip, keep the rest.
        }
      });
      final quarantined = <String, MemoryItemState>{};
      if (map['quarantine'] is Map) {
        final qMap = Map<String, dynamic>.from(map['quarantine'] as Map);
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
      final store = ReviewStore._(
        repository,
        items,
        quarantined,
        corpusMap,
        effectiveKey,
        ownerLabel,
      );
      if (corpusMap != null) {
        store.reconcile(corpusMap);
      }
      if (needsLegacyMigration) {
        // Best-effort legacy claim: failure is observed, never silent.
        await store.persist();
      }
      return store;
    } catch (_) {
      return ReviewStore._(
        repository,
        {},
        null,
        corpusMap,
        effectiveKey,
        ownerLabel,
      );
    }
  }

  List<MemoryItemState> all() => _states.values.toList(growable: false);

  MemoryItemState? get(String itemId) => _states[itemId];

  /// Applies a server state to the in-memory cache during sync. PURE: does
  /// not persist. Callers ([ReviewStateSync], migration) persist explicitly
  /// so one logical adoption causes exactly one durable write.
  MemoryItemState adoptRemote(MemoryItemState item) {
    if (item.itemId.isEmpty) return item;
    _states[item.itemId] = item;
    return item;
  }

  /// Introduce if absent. PURE: returns the (new or existing) state without
  /// persisting. Never overwrites existing scheduling data (duplicate-safe).
  /// There is no eviction: every introduced item is retained locally until
  /// an explicit, remotely-coordinated archival policy exists.
  MemoryItemState ensureIntroduced({
    required String itemId,
    required ReviewItemType itemType,
    required DateTime now,
  }) {
    final existing = _states[itemId];
    if (existing != null) return existing;
    final introduced = MemoryScheduler.introduce(
      itemId: itemId,
      itemType: itemType,
      now: now,
    );
    _states[itemId] = introduced;
    return introduced;
  }

  /// Record a recall and reschedule. PURE: auto-introduces unknown items
  /// first, computes the next scheduler state, and returns it — without
  /// persisting. Returns the new state plus whether a mastery threshold was
  /// just crossed (REVIEW / MASTERED) — used for retention analytics.
  ///
  /// Durability note: [becameReview]/[becameMastered] describe the
  /// in-memory transition only. They become durable (and safe to report as
  /// product progress) once the owning transaction's [persist] succeeds;
  /// see [ReviewStoreNotifier.recordRecall].
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

  /// Removes active AND quarantined state for exactly this store's captured
  /// owner. Never touches another owner's key.
  Future<void> clear() async {
    _states.clear();
    _quarantined.clear();
    await _repository.clear(_storageKey);
  }

  /// Reconciles in-memory state against the corpus map. PURE: applies the
  /// reconciled maps in memory and returns the result without persisting;
  /// the caller persists once if [ReviewReconciliationResult.hasChanges].
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
    }
    return result;
  }

  List<MemoryItemState> quarantined() =>
      _quarantined.values.toList(growable: false);

  MemoryItemState? getQuarantined(String itemId) => _quarantined[itemId];

  int quarantinedCount() => _quarantined.length;

  /// The ONE durable write path. Serialized by the repository (invocation
  /// order preserved), awaited by the caller, with deterministic
  /// true/false propagation. Failures are exposed to the repository's
  /// [ReviewStorageObserver] — never silently swallowed.
  Future<bool> persist() => _repository.save(_storageKey, snapshot());

  /// Awaits [persist] and throws [ReviewStorageException] on failure so a
  /// correctness-critical mutation cannot be mistaken for durable success.
  Future<void> persistOrThrow() =>
      _repository.saveOrThrow(_storageKey, snapshot());

  /// Records a recall in memory, then performs exactly ONE durable write.
  /// Prefer the notifier transaction ([ReviewStoreNotifier.recordRecall])
  /// in production; this helper exists for call sites that own a store
  /// directly (sync, migration, tests).
  Future<({MemoryItemState state, bool becameReview, bool becameMastered})>
  recordRecallDurable({
    required String itemId,
    required ReviewItemType itemType,
    required bool correct,
    required ReviewExerciseType exerciseType,
    DateTime? now,
    int? responseTimeMs,
  }) async {
    final result = recordRecall(
      itemId: itemId,
      itemType: itemType,
      correct: correct,
      exerciseType: exerciseType,
      now: now ?? DateTime.now(),
      responseTimeMs: responseTimeMs,
    );
    await persist();
    return result;
  }

  /// Introduces an item in memory, then performs exactly ONE durable write.
  Future<MemoryItemState> ensureIntroducedDurable({
    required String itemId,
    required ReviewItemType itemType,
    DateTime? now,
  }) async {
    final result = ensureIntroduced(
      itemId: itemId,
      itemType: itemType,
      now: now ?? DateTime.now(),
    );
    await persist();
    return result;
  }
}
