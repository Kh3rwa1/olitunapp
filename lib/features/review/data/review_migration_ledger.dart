// Formal migration state machine for review-state ownership moves.
//
// Guarantees: owner-safe, idempotent, resumable, crash-safe at every step,
// observable, and unable to import the same source into multiple accounts
// or add the same guest counters twice.
//
// Two moves are covered:
// 1. Guest -> account (scoped keys `review_states_guest` ->
//    `review_states_<account>`).
// 2. Legacy global claim (`review_states_v1`, unowned) -> one proven owner,
//    once; ambiguous data is quarantined, never silently imported.
//
// Crash-safety mechanism: every migration writes a durable [MigrationReceipt]
// BEFORE mutating destination state. The receipt records the source
// fingerprint plus per-item applied deltas, so a rerun after a crash at ANY
// boundary (before/during/after destination write, before/during/after
// source clear, before receipt completion) converges to the exact same
// destination state instead of double-counting.
//
// A timestamp alone is NEVER the idempotency key: the key is
// `migrationId = <kind>_<srcOwner>_<dstOwner>_<sourceFingerprint>`.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/logging/app_logger.dart';
import '../domain/review_item.dart';

class ReviewStateMigrationResult {
  final int guestItemsCount;
  final int adoptedCount;
  final int mergedCount;

  const ReviewStateMigrationResult({
    required this.guestItemsCount,
    required this.adoptedCount,
    required this.mergedCount,
  });

  int get migratedCount => adoptedCount + mergedCount;
  bool get hasChanges => adoptedCount > 0 || mergedCount > 0;
}

/// Durable migration states.
enum MigrationStatus { prepared, applied, sourceCleared, completed, failed }

/// Durable receipt for one ownership move.
class MigrationReceipt {
  final String migrationId;
  final String sourceOwner;
  final String destinationOwner;
  final int sourceSchemaVersion;
  final int destinationSchemaVersion;
  final String sourceFingerprint;
  final MigrationStatus status;
  final DateTime startedAt;
  final DateTime updatedAt;
  final String? failureReason;

  /// Counters of the destination BEFORE this migration (overlapping items).
  final Map<String, Map<String, int>> destinationPreCounters;

  /// Deltas applied to the destination per item.
  final Map<String, Map<String, int>> appliedDeltas;

  /// Guest-only item ids adopted as-is.
  final List<String> adoptedIds;

  const MigrationReceipt({
    required this.migrationId,
    required this.sourceOwner,
    required this.destinationOwner,
    required this.sourceSchemaVersion,
    required this.destinationSchemaVersion,
    required this.sourceFingerprint,
    required this.status,
    required this.startedAt,
    required this.updatedAt,
    this.failureReason,
    this.destinationPreCounters = const {},
    this.appliedDeltas = const {},
    this.adoptedIds = const [],
  });

  Map<String, dynamic> toMap() => {
    'migrationId': migrationId,
    'sourceOwner': sourceOwner,
    'destinationOwner': destinationOwner,
    'sourceSchemaVersion': sourceSchemaVersion,
    'destinationSchemaVersion': destinationSchemaVersion,
    'sourceFingerprint': sourceFingerprint,
    'status': status.name,
    'startedAt': startedAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'failureReason': failureReason,
    'destinationPreCounters': destinationPreCounters,
    'appliedDeltas': appliedDeltas,
    'adoptedIds': adoptedIds,
  };

  factory MigrationReceipt.fromMap(Map<String, dynamic> map) {
    MigrationStatus statusFrom(String? raw) {
      for (final s in MigrationStatus.values) {
        if (s.name == raw) return s;
      }
      return MigrationStatus.failed;
    }

    Map<String, Map<String, int>> intMap(dynamic raw) {
      final out = <String, Map<String, int>>{};
      if (raw is Map) {
        raw.forEach((k, v) {
          if (v is Map) {
            out[k.toString()] = {
              for (final e in v.entries)
                e.key.toString(): (e.value as num?)?.toInt() ?? 0,
            };
          }
        });
      }
      return out;
    }

    DateTime parse(String? raw) =>
        DateTime.tryParse(raw ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
    return MigrationReceipt(
      migrationId: (map['migrationId'] ?? '').toString(),
      sourceOwner: (map['sourceOwner'] ?? '').toString(),
      destinationOwner: (map['destinationOwner'] ?? '').toString(),
      sourceSchemaVersion: (map['sourceSchemaVersion'] as num?)?.toInt() ?? 0,
      destinationSchemaVersion:
          (map['destinationSchemaVersion'] as num?)?.toInt() ?? 0,
      sourceFingerprint: (map['sourceFingerprint'] ?? '').toString(),
      status: statusFrom(map['status'] as String?),
      startedAt: parse(map['startedAt'] as String?),
      updatedAt: parse(map['updatedAt'] as String?),
      failureReason: map['failureReason'] as String?,
      destinationPreCounters: intMap(map['destinationPreCounters']),
      appliedDeltas: intMap(map['appliedDeltas']),
      adoptedIds: ((map['adoptedIds'] as List?) ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

/// Owner-partitioned receipt ledger. One ledger document per destination
/// owner: `review_migration_ledger_<scopeSuffix>`. Receipts contain only
/// ids, fingerprints, counters and statuses — no learning text — and are
/// never exposed across accounts.
class MigrationLedger {
  static String ledgerKeyForOwner(String ownerKey) =>
      'review_migration_ledger_$ownerKey';

  /// Key for the legacy-global claim marker (single-flight across owners).
  static const legacyClaimKey = 'review_legacy_claim_v1';

  /// Quarantine for ambiguous unowned legacy data. Never auto-imported.
  static const unownedLegacyKey = 'review_states_unowned_legacy_v1';

  final SharedPreferences _prefs;
  final String _ledgerKey;

  MigrationLedger(this._prefs, String destinationOwnerKey)
    : _ledgerKey = ledgerKeyForOwner(destinationOwnerKey);

  Map<String, MigrationReceipt> loadAll() {
    try {
      final raw = _prefs.getString(_ledgerKey);
      if (raw == null || raw.isEmpty) return {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final decodedMap = decoded;
      return {
        for (final e in decodedMap.entries)
          if (e.value is Map)
            e.key.toString(): MigrationReceipt.fromMap(
              Map<String, dynamic>.from(e.value as Map),
            ),
      };
    } catch (e) {
      AppLogger.debug('MigrationLedger: load failed: $e');
      return {};
    }
  }

  Future<bool> saveReceipt(MigrationReceipt receipt) async {
    final all = loadAll();
    all[receipt.migrationId] = receipt;
    try {
      return await _prefs.setString(
        _ledgerKey,
        jsonEncode({for (final e in all.entries) e.key: e.value.toMap()}),
      );
    } catch (e) {
      AppLogger.debug('MigrationLedger: save failed: $e');
      return false;
    }
  }
}

/// Stable fingerprint of a review snapshot: sorted per-item evidence.
/// Two snapshots with equal fingerprints merge identically.
///
/// 32-bit FNV-1a: all literals are exactly representable in JavaScript so
/// `flutter build web` (dart2js) compiles. Combined with the migration-kind
/// and owner prefixes in the migration id, collisions are not a practical
/// concern (equality only matches same-source reruns).
String fingerprintItems(Iterable<MemoryItemState> items) {
  final parts =
      items
          .map(
            (i) =>
                '${i.itemId}|${i.itemType.json}|${i.successfulRecalls}|${i.failedRecalls}|'
                '${i.typingSuccesses}|${i.lapseCount}|${i.introducedAt.toIso8601String()}|'
                '${i.lastReviewedAt?.toIso8601String() ?? ''}',
          )
          .toList()
        ..sort();
  var hash = 0x811c9dc5;
  final joined = parts.join(';');
  for (var i = 0; i < joined.length; i++) {
    hash ^= joined.codeUnitAt(i);
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}
