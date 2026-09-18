// Guest -> account migration engine + legacy-global claim policy.
// (Receipts, ledger, and fingerprints live in review_migration_ledger.dart.)
//
// Exactly-once semantics: per-item deltas recorded in the receipt are
// applied at most once; reruns reconcile arithmetically against the
// recorded pre-image instead of re-adding.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/auth/account_scope.dart';
import '../domain/memory_scheduler.dart';
import '../domain/review_item.dart';
import 'review_migration_ledger.dart';
import 'review_store.dart';

class ReviewMigrationEngine {
  const ReviewMigrationEngine._();

  static String guestMigrationId(String sourceFingerprint) =>
      'guest2account_guest_account_$sourceFingerprint';

  /// Idempotent, crash-safe guest -> account migration.
  ///
  /// Exactly-once semantics: the per-item deltas recorded in the receipt are
  /// applied at most once. A rerun detects destination state that already
  /// includes the recorded deltas (relative to the recorded pre-image) and
  /// skips re-application, then finishes source clearing and completion.
  static Future<ReviewStateMigrationResult> migrateGuestToAccount({
    required ReviewStore guestStore,
    required ReviewStore accountStore,
    required SharedPreferences prefs,
    required String destinationOwnerKey,
    DateTime? now,
  }) async {
    final guestItems = guestStore.all();
    if (guestItems.isEmpty) {
      return const ReviewStateMigrationResult(
        guestItemsCount: 0,
        adoptedCount: 0,
        mergedCount: 0,
      );
    }
    final fingerprint = fingerprintItems(guestItems);
    final migrationId = guestMigrationId(fingerprint);
    final ledger = MigrationLedger(prefs, destinationOwnerKey);
    final existing = ledger.loadAll()[migrationId];

    // Fast path: completed receipt with matching fingerprint.
    if (existing != null && existing.status == MigrationStatus.completed) {
      if (guestStore.all().isEmpty) {
        return ReviewStateMigrationResult(
          guestItemsCount: guestItems.length,
          adoptedCount: 0,
          mergedCount: 0,
        );
      }
      // Source clear failed last time: same fingerprint → clear now.
      if (fingerprintItems(guestStore.all()) == existing.sourceFingerprint) {
        await guestStore.clear();
        return ReviewStateMigrationResult(
          guestItemsCount: guestItems.length,
          adoptedCount: 0,
          mergedCount: 0,
        );
      }
      // Different fingerprint: genuinely new guest study — fall through as
      // a new migration below (new migrationId derived from new fingerprint).
      return migrateGuestToAccount(
        guestStore: guestStore,
        accountStore: accountStore,
        prefs: prefs,
        destinationOwnerKey: destinationOwnerKey,
        now: now,
      );
    }

    // Resume path: a prepared/applied receipt for the same fingerprint.
    if (existing != null &&
        (existing.status == MigrationStatus.prepared ||
            existing.status == MigrationStatus.applied ||
            existing.status == MigrationStatus.sourceCleared)) {
      return _resumeMigration(
        guestStore: guestStore,
        accountStore: accountStore,
        prefs: prefs,
        ledger: ledger,
        receipt: existing,
        now: now,
      );
    }

    // Fresh migration: record `prepared` BEFORE touching the destination.
    final preCounters = <String, Map<String, int>>{};
    final deltas = <String, Map<String, int>>{};
    final adopted = <String>[];
    for (final guestItem in guestItems) {
      if (guestItem.itemId.isEmpty) continue;
      final accountItem = accountStore.get(guestItem.itemId);
      if (accountItem == null) {
        adopted.add(guestItem.itemId);
      } else {
        preCounters[guestItem.itemId] = _countersOf(accountItem);
        deltas[guestItem.itemId] = _deltaOf(guestItem);
      }
    }
    var receipt = MigrationReceipt(
      migrationId: migrationId,
      sourceOwner: 'guest',
      destinationOwner: destinationOwnerKey,
      sourceSchemaVersion: ReviewStore.schemaVersion,
      destinationSchemaVersion: ReviewStore.schemaVersion,
      sourceFingerprint: fingerprint,
      status: MigrationStatus.prepared,
      startedAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      destinationPreCounters: preCounters,
      appliedDeltas: deltas,
      adoptedIds: adopted,
    );
    await ledger.saveReceipt(receipt);

    _applyMerge(
      guestItems: guestItems,
      accountStore: accountStore,
      skipMergedIds: const {},
    );
    final persisted = await accountStore.persist();
    if (!persisted) {
      receipt = _withStatus(
        receipt,
        MigrationStatus.failed,
        'destination persist failed',
      );
      await ledger.saveReceipt(receipt);
      throw const ReviewStorageExceptionForMigration(
        'Guest migration destination persist failed; will resume on retry.',
      );
    }
    receipt = _withStatus(receipt, MigrationStatus.applied, null);
    await ledger.saveReceipt(receipt);

    await guestStore.clear();
    receipt = _withStatus(receipt, MigrationStatus.sourceCleared, null);
    await ledger.saveReceipt(receipt);
    receipt = _withStatus(receipt, MigrationStatus.completed, null);
    await ledger.saveReceipt(receipt);

    return ReviewStateMigrationResult(
      guestItemsCount: guestItems.length,
      adoptedCount: adopted.length,
      mergedCount: deltas.length,
    );
  }

  /// Resumes a migration interrupted after `prepared`/`applied`.
  /// Destination state already containing the recorded deltas is NOT
  /// merged again: per-item current counters are compared against
  /// pre-image + delta, and only missing evidence is applied.
  static Future<ReviewStateMigrationResult> _resumeMigration({
    required ReviewStore guestStore,
    required ReviewStore accountStore,
    required SharedPreferences prefs,
    required MigrationLedger ledger,
    required MigrationReceipt receipt,
    DateTime? now,
  }) async {
    // Destination may have advanced (user studied meanwhile) — reconcile
    // arithmetically per item instead of blindly re-adding.
    final missingDeltas = <String, Map<String, int>>{};
    for (final entry in receipt.appliedDeltas.entries) {
      final item = accountStore.get(entry.key);
      final pre =
          receipt.destinationPreCounters[entry.key] ??
          {'s': 0, 'f': 0, 't': 0, 'l': 0};
      final want = {
        's': (pre['s'] ?? 0) + (entry.value['s'] ?? 0),
        'f': (pre['f'] ?? 0) + (entry.value['f'] ?? 0),
        't': (pre['t'] ?? 0) + (entry.value['t'] ?? 0),
        'l': (pre['l'] ?? 0) + (entry.value['l'] ?? 0),
      };
      if (item == null) {
        missingDeltas[entry.key] = entry.value;
        continue;
      }
      final has = _countersOf(item);
      final missing = {
        's': (want['s']! - (has['s'] ?? 0)).clamp(0, 1 << 30),
        'f': (want['f']! - (has['f'] ?? 0)).clamp(0, 1 << 30),
        't': (want['t']! - (has['t'] ?? 0)).clamp(0, 1 << 30),
        'l': (want['l']! - (has['l'] ?? 0)).clamp(0, 1 << 30),
      };
      if (missing.values.any((v) => v > 0)) missingDeltas[entry.key] = missing;
    }
    // Adopted ids missing from the destination are re-adopted from source.
    final guestById = {for (final g in guestStore.all()) g.itemId: g};
    for (final id in receipt.adoptedIds) {
      if (accountStore.get(id) == null && guestById[id] != null) {
        accountStore.adoptRemote(guestById[id]!);
      }
    }
    _applyMissingDeltas(
      accountStore: accountStore,
      guestById: guestById,
      missingDeltas: missingDeltas,
    );
    final persisted = await accountStore.persist();
    if (!persisted) {
      await ledger.saveReceipt(
        _withStatus(receipt, MigrationStatus.failed, 'resume persist failed'),
      );
      throw const ReviewStorageExceptionForMigration(
        'Guest migration resume persist failed; will resume on retry.',
      );
    }
    await ledger.saveReceipt(
      _withStatus(receipt, MigrationStatus.applied, null),
    );
    await guestStore.clear();
    await ledger.saveReceipt(
      _withStatus(receipt, MigrationStatus.sourceCleared, null),
    );
    await ledger.saveReceipt(
      _withStatus(receipt, MigrationStatus.completed, null),
    );
    return ReviewStateMigrationResult(
      guestItemsCount: guestById.length,
      adoptedCount: receipt.adoptedIds.length,
      mergedCount: receipt.appliedDeltas.length,
    );
  }

  static Map<String, int> _countersOf(MemoryItemState item) => {
    's': item.successfulRecalls,
    'f': item.failedRecalls,
    't': item.typingSuccesses,
    'l': item.lapseCount,
  };

  static Map<String, int> _deltaOf(MemoryItemState guest) => {
    's': guest.successfulRecalls,
    'f': guest.failedRecalls,
    't': guest.typingSuccesses,
    'l': guest.lapseCount,
  };

  /// Full merge for a fresh migration (in-memory; caller persists once).
  static void _applyMerge({
    required List<MemoryItemState> guestItems,
    required ReviewStore accountStore,
    required Set<String> skipMergedIds,
  }) {
    for (final guestItem in guestItems) {
      if (guestItem.itemId.isEmpty) continue;
      final accountItem = accountStore.get(guestItem.itemId);
      if (accountItem == null) {
        accountStore.adoptRemote(guestItem);
      } else if (!skipMergedIds.contains(guestItem.itemId)) {
        accountStore.adoptRemote(
          mergeGuestAndAccountItem(guestItem, accountItem),
        );
      }
    }
  }

  /// Applies only the missing counter evidence on resume, then re-derives
  /// scheduling deterministically from the same merge function.
  static void _applyMissingDeltas({
    required ReviewStore accountStore,
    required Map<String, MemoryItemState> guestById,
    required Map<String, Map<String, int>> missingDeltas,
  }) {
    for (final entry in missingDeltas.entries) {
      final guest = guestById[entry.key];
      final current = accountStore.get(entry.key);
      if (guest == null) continue;
      if (current == null) {
        accountStore.adoptRemote(guest);
        continue;
      }
      final missing = entry.value;
      if (missing.values.every((v) => v == 0)) continue;
      // Rebuild a synthetic guest contribution carrying only missing
      // evidence, then run the SAME deterministic merge.
      final partial = MemoryItemState(
        itemId: guest.itemId,
        itemType: guest.itemType,
        introducedAt: guest.introducedAt,
        lastPresentedAt: guest.lastPresentedAt,
        lastReviewedAt: guest.lastReviewedAt,
        nextReviewAt: guest.nextReviewAt,
        intervalDays: guest.intervalDays,
        ease: guest.ease,
        successfulRecalls: missing['s'] ?? 0,
        failedRecalls: missing['f'] ?? 0,
        lapseCount: missing['l'] ?? 0,
        masteryState: guest.masteryState,
        lastResponseTimeMs: guest.lastResponseTimeMs,
        lastExerciseType: guest.lastExerciseType,
        typingSuccesses: missing['t'] ?? 0,
        firstRecallAt: guest.firstRecallAt,
      );
      accountStore.adoptRemote(mergeGuestAndAccountItem(partial, current));
    }
  }

  static MigrationReceipt _withStatus(
    MigrationReceipt receipt,
    MigrationStatus status,
    String? failureReason,
  ) => MigrationReceipt(
    migrationId: receipt.migrationId,
    sourceOwner: receipt.sourceOwner,
    destinationOwner: receipt.destinationOwner,
    sourceSchemaVersion: receipt.sourceSchemaVersion,
    destinationSchemaVersion: receipt.destinationSchemaVersion,
    sourceFingerprint: receipt.sourceFingerprint,
    status: status,
    startedAt: receipt.startedAt,
    updatedAt: DateTime.now().toUtc(),
    failureReason: failureReason,
    destinationPreCounters: receipt.destinationPreCounters,
    appliedDeltas: receipt.appliedDeltas,
    adoptedIds: receipt.adoptedIds,
  );

  /// Deterministic guest+account merge for one item. Item-type mismatch is
  /// rejected (never silently merged across types).
  static MemoryItemState mergeGuestAndAccountItem(
    MemoryItemState guest,
    MemoryItemState account,
  ) {
    if (guest.itemType != account.itemType) {
      throw ArgumentError(
        'Cannot migrate item "${guest.itemId}" across types '
        '(${guest.itemType} vs ${account.itemType})',
      );
    }
    final introducedAt = guest.introducedAt.isBefore(account.introducedAt)
        ? guest.introducedAt
        : account.introducedAt;

    final DateTime? firstRecallAt =
        (guest.firstRecallAt != null && account.firstRecallAt != null)
        ? (guest.firstRecallAt!.isBefore(account.firstRecallAt!)
              ? guest.firstRecallAt
              : account.firstRecallAt)
        : (guest.firstRecallAt ?? account.firstRecallAt);

    final gLast = guest.lastReviewedAt;
    final aLast = account.lastReviewedAt;
    final bool guestIsNewer =
        (aLast == null && gLast != null) ||
        (gLast != null && aLast != null && gLast.isAfter(aLast));

    final lastReviewedAt = guestIsNewer ? gLast : (aLast ?? gLast);
    final lastPresentedAt =
        (guest.lastPresentedAt != null && account.lastPresentedAt != null)
        ? (guest.lastPresentedAt!.isAfter(account.lastPresentedAt!)
              ? guest.lastPresentedAt
              : account.lastPresentedAt)
        : (guest.lastPresentedAt ?? account.lastPresentedAt);

    final lastExerciseType = guestIsNewer
        ? (guest.lastExerciseType ?? account.lastExerciseType)
        : (account.lastExerciseType ?? guest.lastExerciseType);
    final lastResponseTimeMs = guestIsNewer
        ? (guest.lastResponseTimeMs ?? account.lastResponseTimeMs)
        : (account.lastResponseTimeMs ?? guest.lastResponseTimeMs);

    final successfulRecalls =
        account.successfulRecalls + guest.successfulRecalls;
    final failedRecalls = account.failedRecalls + guest.failedRecalls;
    final typingSuccesses = account.typingSuccesses + guest.typingSuccesses;
    final lapseCount = account.lapseCount + guest.lapseCount;

    final ease = (guestIsNewer ? guest.ease : account.ease).clamp(
      MemoryScheduler.minEase,
      MemoryScheduler.maxEase,
    );

    final intervalDays = _maxDouble(account.intervalDays, guest.intervalDays);
    DateTime nextReviewAt = guestIsNewer
        ? guest.nextReviewAt
        : account.nextReviewAt;
    if (guest.failedRecalls > 0 || account.failedRecalls > 0) {
      if (guest.nextReviewAt.isBefore(account.nextReviewAt)) {
        nextReviewAt = guest.nextReviewAt;
      } else {
        nextReviewAt = account.nextReviewAt;
      }
    }

    MasteryState mastery;
    if (successfulRecalls >= MemoryScheduler.successesForMastered &&
        intervalDays >= MemoryScheduler.intervalForMasteredDays &&
        successfulRecalls > failedRecalls) {
      mastery = MasteryState.mastered;
    } else if (successfulRecalls >= MemoryScheduler.successesForReview) {
      mastery = MasteryState.review;
    } else if (successfulRecalls > 0 || failedRecalls > 0) {
      mastery = MasteryState.learning;
    } else {
      mastery = MasteryState.fresh;
    }

    return MemoryItemState(
      itemId: account.itemId,
      itemType: account.itemType,
      introducedAt: introducedAt,
      lastPresentedAt: lastPresentedAt,
      lastReviewedAt: lastReviewedAt,
      nextReviewAt: nextReviewAt,
      intervalDays: intervalDays,
      ease: ease,
      successfulRecalls: successfulRecalls,
      failedRecalls: failedRecalls,
      lapseCount: lapseCount,
      masteryState: mastery,
      lastResponseTimeMs: lastResponseTimeMs,
      lastExerciseType: lastExerciseType,
      typingSuccesses: typingSuccesses,
      firstRecallAt: firstRecallAt,
    );
  }

  static double _maxDouble(double a, double b) => a >= b ? a : b;

  // --- Legacy global claim policy ---

  /// Claims the unowned legacy key `review_states_v1` for at most one owner.
  ///
  /// Fail-safe rules:
  /// - If a durable claim marker already names a DIFFERENT owner, this
  ///   account never imports the legacy data (returns claimed=false).
  /// - If ownership is provable from [scope] (known account/guest with a
  ///   matching live session), the claim marker is recorded durably BEFORE
  ///   any import, then the legacy payload is adopted once.
  /// - If ownership is NOT provable (unknown/corrupt/unresolved scope),
  ///   nothing is imported and nothing is destroyed: the payload is moved
  ///   to the unowned quarantine for an explicit one-time recovery decision.
  static Future<LegacyClaimOutcome> claimLegacyGlobal({
    required SharedPreferences prefs,
    required AccountScope scope,
    required ReviewStore ownerStore,
  }) async {
    if (!prefs.containsKey(ReviewStore.storageKey)) {
      return const LegacyClaimOutcome(
        claimed: false,
        quarantined: false,
        reason: 'no legacy data',
      );
    }
    try {
      final rawClaim = prefs.getString(MigrationLedger.legacyClaimKey);
      if (rawClaim != null && rawClaim.isNotEmpty) {
        final claim = Map<String, dynamic>.from(jsonDecode(rawClaim) as Map);
        final claimedOwner = (claim['owner'] ?? '').toString();
        if (claimedOwner.isNotEmpty &&
            claimedOwner != ownerStore.storageKeyUsed) {
          return const LegacyClaimOutcome(
            claimed: false,
            quarantined: false,
            reason: 'already claimed by another owner',
          );
        }
        if (claimedOwner == ownerStore.storageKeyUsed) {
          return const LegacyClaimOutcome(
            claimed: false,
            quarantined: false,
            reason: 'already claimed by this owner',
          );
        }
      }
    } catch (_) {
      // Corrupt claim marker: fail closed (do not import).
      return const LegacyClaimOutcome(
        claimed: false,
        quarantined: false,
        reason: 'corrupt claim marker',
      );
    }

    if (!scope.isKnown) {
      // Ownership unprovable: quarantine without destroying, never import.
      final raw = prefs.getString(ReviewStore.storageKey);
      if (raw != null && raw.isNotEmpty) {
        await prefs.setString(MigrationLedger.unownedLegacyKey, raw);
        await prefs.remove(ReviewStore.storageKey);
      }
      return const LegacyClaimOutcome(
        claimed: false,
        quarantined: true,
        reason: 'ownership unprovable; quarantined as unowned legacy',
      );
    }

    // Ownership provable: record the claim marker FIRST (single-flight),
    // then adopt once.
    final marker = jsonEncode({
      'owner': ownerStore.storageKeyUsed,
      'claimedAt': DateTime.now().toUtc().toIso8601String(),
      'sourceSchema': ReviewStore.schemaVersion,
    });
    final markerOk = await prefs.setString(
      MigrationLedger.legacyClaimKey,
      marker,
    );
    if (!markerOk) {
      return const LegacyClaimOutcome(
        claimed: false,
        quarantined: false,
        reason: 'claim marker persist failed',
      );
    }
    final raw = prefs.getString(ReviewStore.storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          final map = Map<String, dynamic>.from(decoded);
          final itemsRaw = map['items'] is Map
              ? Map<String, dynamic>.from(map['items'] as Map)
              : Map<String, dynamic>.from(map);
          for (final value in itemsRaw.values) {
            try {
              if (value is Map) {
                final item = MemoryItemState.fromMap(
                  Map<String, dynamic>.from(value),
                );
                if (item.itemId.isNotEmpty &&
                    ownerStore.get(item.itemId) == null) {
                  ownerStore.adoptRemote(item);
                }
              }
            } catch (_) {
              // Skip corrupt entries.
            }
          }
          await ownerStore.persist();
        }
      } catch (_) {
        // Corrupt legacy payload: leave it for quarantine tooling.
        return const LegacyClaimOutcome(
          claimed: true,
          quarantined: false,
          reason: 'claim recorded; legacy payload corrupt, nothing adopted',
        );
      }
      await prefs.remove(ReviewStore.storageKey);
    }
    return const LegacyClaimOutcome(
      claimed: true,
      quarantined: false,
      reason: 'claimed once for proven owner',
    );
  }
}

class LegacyClaimOutcome {
  final bool claimed;
  final bool quarantined;
  final String reason;
  const LegacyClaimOutcome({
    required this.claimed,
    required this.quarantined,
    required this.reason,
  });
}

class ReviewStorageExceptionForMigration implements Exception {
  final String message;
  const ReviewStorageExceptionForMigration(this.message);
  @override
  String toString() => 'ReviewStorageExceptionForMigration: $message';
}
