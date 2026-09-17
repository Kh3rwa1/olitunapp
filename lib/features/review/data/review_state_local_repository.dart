// Local durability engine for review state.
//
// One unambiguous persistence boundary: all review-state bytes flow through
// [ReviewStateLocalRepository]. The default implementation is backed by
// SharedPreferences (a single versioned JSON document per account scope);
// tests inject [InMemoryDelayedReviewStateRepository] to reproduce delayed
// and out-of-order native persistence — something SharedPreferences mocks
// cannot do.
//
// Schema: `{"schemaVersion": 3, "items": {...}, "quarantine": {...}}`.
// Migration receipts for guest/account moves live in
// `review_migration_ledger.dart`, not here.

import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/auth/account_scope.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/review_item.dart';

/// Typed failure for account-scope violations during a mutation transaction.
///
/// Thrown (or returned) when the account scope changes between compute and
/// persist: the transaction must not write into the new account and must not
/// publish stale state.
class AccountScopeError extends StateError {
  final String? expectedOwner;
  final String? actualOwner;
  AccountScopeError({required this.expectedOwner, required this.actualOwner})
    : super(
        'Account scope changed during review mutation '
        '(expected: $expectedOwner, actual: $actualOwner). '
        'Local mutation retained under its original owner; stale state not published.',
      );
}

/// Typed failure for durable persistence errors.
///
/// Never swallowed: [ReviewStateLocalRepository] exposes failures through
/// [ReviewStorageObserver] and [save] returns false / throws this error via
/// [saveOrThrow] so callers cannot mistake an undurable mutation for success.
class ReviewStorageException implements Exception {
  final String message;
  final Object? cause;
  const ReviewStorageException(this.message, [this.cause]);

  @override
  String toString() =>
      'ReviewStorageException: $message'
      '${cause == null ? '' : ' (caused by $cause)'}';
}

/// Immutable snapshot of one account owner's review state.
class ReviewStateSnapshot {
  static const int currentSchemaVersion = 3;

  final int schemaVersion;
  final Map<String, MemoryItemState> items;
  final Map<String, MemoryItemState> quarantine;

  const ReviewStateSnapshot({
    required this.schemaVersion,
    required this.items,
    required this.quarantine,
  });

  const ReviewStateSnapshot.empty()
    : schemaVersion = currentSchemaVersion,
      items = const {},
      quarantine = const {};
}

/// Observability hook for durable storage failures.
///
/// Production wires this to crash reporting / diagnostics; tests assert on it.
/// No raw learning text is ever forwarded — only keys, sizes and errors.
abstract class ReviewStorageObserver {
  void onSaveFailure({
    required String storageKey,
    required Object error,
    required int itemCount,
  });
  void onLoadFailure({required String storageKey, required Object error});
}

class _NoopReviewStorageObserver implements ReviewStorageObserver {
  const _NoopReviewStorageObserver();
  @override
  void onSaveFailure({
    required String storageKey,
    required Object error,
    required int itemCount,
  }) {}
  @override
  void onLoadFailure({required String storageKey, required Object error}) {}
}

/// The single persistence boundary for review state.
///
/// Implementations must serialize mutations: a `save` invoked after an
/// earlier `save` began must not invoke the underlying persistence before
/// the earlier save completes (ordering guarantee), and the final durable
/// state must contain the latest acknowledged mutation.
abstract class ReviewStateLocalRepository {
  /// Loads the snapshot stored under [storageKey].
  Future<ReviewStateSnapshot> load(String storageKey);

  /// Durably saves [snapshot] under [storageKey].
  /// Returns true on success, false on (observed) failure.
  Future<bool> save(String storageKey, ReviewStateSnapshot snapshot);

  /// Like [save] but throws [ReviewStorageException] on failure.
  Future<void> saveOrThrow(String storageKey, ReviewStateSnapshot snapshot);

  /// Removes active and quarantined state for exactly [storageKey].
  Future<void> clear(String storageKey);
}

/// SharedPreferences-backed repository with a serialized invocation queue.
///
/// Unlike the previous `ReviewStore.persist()` (which invoked
/// `setString` *before* chaining onto the queue and therefore serialized
/// only waiting), this implementation chains the *invocation* itself:
/// the JSON encoding snapshot is captured inside the queued closure from
/// immutable input, so write B can never overtake write A.
class SharedPreferencesReviewStateRepository
    implements ReviewStateLocalRepository {
  final SharedPreferences _prefs;
  final ReviewStorageObserver _observer;

  /// Serializes mutation *invocations*, not just waiters.
  Future<void> _queue = Future<void>.value();

  SharedPreferencesReviewStateRepository(
    this._prefs, [
    ReviewStorageObserver? observer,
  ]) : _observer = observer ?? const _NoopReviewStorageObserver();

  @override
  Future<ReviewStateSnapshot> load(String storageKey) async {
    try {
      final raw = _prefs.getString(storageKey);
      if (raw == null || raw.isEmpty) return const ReviewStateSnapshot.empty();
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const ReviewStateSnapshot.empty();
      final map = Map<String, dynamic>.from(decoded);
      final items = _decodeStates(map['items'] ?? map);
      final quarantine = map['quarantine'] is Map
          ? _decodeStates(Map<String, dynamic>.from(map['quarantine'] as Map))
          : <String, MemoryItemState>{};
      return ReviewStateSnapshot(
        schemaVersion:
            (map['schemaVersion'] as num?)?.toInt() ??
            ReviewStateSnapshot.currentSchemaVersion,
        items: items,
        quarantine: quarantine,
      );
    } catch (e) {
      _observer.onLoadFailure(storageKey: storageKey, error: e);
      AppLogger.debug('ReviewStateRepository: load failed for $storageKey: $e');
      return const ReviewStateSnapshot.empty();
    }
  }

  @override
  Future<bool> save(String storageKey, ReviewStateSnapshot snapshot) {
    final completer = Completer<bool>();
    // Chain the whole invocation (encode + write) onto the queue so that
    // concurrent saves execute strictly in call order.
    _queue = _queue.then((_) async {
      try {
        final payload = <String, dynamic>{
          'schemaVersion': snapshot.schemaVersion,
          'items': {
            for (final e in snapshot.items.entries) e.key: e.value.toMap(),
          },
          'quarantine': {
            for (final e in snapshot.quarantine.entries) e.key: e.value.toMap(),
          },
        };
        final ok = await _prefs.setString(storageKey, jsonEncode(payload));
        if (!ok) {
          const err = ReviewStorageException('setString returned false');
          _observer.onSaveFailure(
            storageKey: storageKey,
            error: err,
            itemCount: snapshot.items.length,
          );
        }
        completer.complete(ok);
      } catch (e) {
        _observer.onSaveFailure(
          storageKey: storageKey,
          error: e,
          itemCount: snapshot.items.length,
        );
        AppLogger.debug('ReviewStateRepository: save failed for $storageKey');
        completer.complete(false);
      }
    });
    return completer.future;
  }

  @override
  Future<void> saveOrThrow(
    String storageKey,
    ReviewStateSnapshot snapshot,
  ) async {
    final ok = await save(storageKey, snapshot);
    if (!ok) {
      throw ReviewStorageException(
        'Failed to durably persist review state for $storageKey',
      );
    }
  }

  @override
  Future<void> clear(String storageKey) =>
      _prefs.remove(storageKey).then((_) {});
}

Map<String, MemoryItemState> _decodeStates(Map<dynamic, dynamic> raw) {
  final out = <String, MemoryItemState>{};
  raw.forEach((key, value) {
    try {
      if (value is Map) {
        final item = MemoryItemState.fromMap(Map<String, dynamic>.from(value));
        if (item.itemId.isNotEmpty) out[item.itemId] = item;
      }
    } catch (_) {
      // Corrupt entry: skip, keep the rest.
    }
  });
  return out;
}

/// Controllable fake for durability tests.
///
/// [delay] gates *invocation* of the underlying map write (not just the
/// waiters), reproducing delayed native persistence. [failNext] /
/// [failAll] inject deterministic failures. Invocation order is recorded
/// in [invocationLog] so tests can assert serialization.
class InMemoryDelayedReviewStateRepository
    implements ReviewStateLocalRepository {
  final Map<String, String> backing = {};
  final List<String> invocationLog = [];
  Duration delay = Duration.zero;
  bool failNext = false;
  bool failAll = false;
  int saveCallCount = 0;

  final ReviewStorageObserver? observer;
  Future<void> _queue = Future<void>.value();

  InMemoryDelayedReviewStateRepository({this.observer});

  @override
  Future<ReviewStateSnapshot> load(String storageKey) async {
    final raw = backing[storageKey];
    if (raw == null || raw.isEmpty) return const ReviewStateSnapshot.empty();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const ReviewStateSnapshot.empty();
      final map = Map<String, dynamic>.from(decoded);
      return ReviewStateSnapshot(
        schemaVersion:
            (map['schemaVersion'] as num?)?.toInt() ??
            ReviewStateSnapshot.currentSchemaVersion,
        items: _decodeStates(map['items'] ?? map),
        quarantine: map['quarantine'] is Map
            ? _decodeStates(Map<String, dynamic>.from(map['quarantine'] as Map))
            : <String, MemoryItemState>{},
      );
    } catch (_) {
      return const ReviewStateSnapshot.empty();
    }
  }

  @override
  Future<bool> save(String storageKey, ReviewStateSnapshot snapshot) {
    saveCallCount++;
    final completer = Completer<bool>();
    _queue = _queue.then((_) async {
      // Invocation happens here, strictly after all earlier saves.
      invocationLog.add(storageKey);
      if (delay > Duration.zero) await Future<void>.delayed(delay);
      final shouldFail = failAll || failNext;
      failNext = false;
      if (shouldFail) {
        const err = ReviewStorageException('injected fake failure');
        observer?.onSaveFailure(
          storageKey: storageKey,
          error: err,
          itemCount: snapshot.items.length,
        );
        completer.complete(false);
        return;
      }
      final payload = <String, dynamic>{
        'schemaVersion': snapshot.schemaVersion,
        'items': {
          for (final e in snapshot.items.entries) e.key: e.value.toMap(),
        },
        'quarantine': {
          for (final e in snapshot.quarantine.entries) e.key: e.value.toMap(),
        },
      };
      backing[storageKey] = jsonEncode(payload);
      completer.complete(true);
    });
    return completer.future;
  }

  @override
  Future<void> saveOrThrow(
    String storageKey,
    ReviewStateSnapshot snapshot,
  ) async {
    final ok = await save(storageKey, snapshot);
    if (!ok) throw ReviewStorageException('fake save failed for $storageKey');
  }

  @override
  Future<void> clear(String storageKey) async {
    backing.remove(storageKey);
  }
}

/// Derives the account-scoped storage key. Centralizes the rule that all
/// user-owned local review data is partitioned by [AccountScope].
String reviewStorageKeyForScope(AccountScope scope) => scope.reviewKey;
