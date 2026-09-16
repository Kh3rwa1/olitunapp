import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../logging/app_logger.dart';
import '../logging/redaction_helper.dart';
import '../storage/cache_service.dart';

enum MutationStatus {
  pending,
  syncing,
  completed,
  failed,
  deadLetter,
  cancelled,
}

class PendingMutation {
  final String operationId;
  final String userId;
  final String operationType;
  final String entityId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  int attemptCount;
  DateTime nextRetryAt;
  MutationStatus status;
  String? lastError;

  PendingMutation({
    required this.operationId,
    required this.userId,
    required this.operationType,
    required this.entityId,
    required this.payload,
    required this.createdAt,
    this.attemptCount = 0,
    DateTime? nextRetryAt,
    this.status = MutationStatus.pending,
    this.lastError,
  }) : nextRetryAt = nextRetryAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'operationId': operationId,
    'userId': userId,
    'operationType': operationType,
    'entityId': entityId,
    'payload': payload,
    'createdAt': createdAt.toIso8601String(),
    'attemptCount': attemptCount,
    'nextRetryAt': nextRetryAt.toIso8601String(),
    'status': status.name,
    'lastError': lastError,
  };

  factory PendingMutation.fromJson(Map<String, dynamic> json) =>
      PendingMutation(
        operationId: json['operationId'] as String,
        userId: json['userId'] as String,
        operationType: json['operationType'] as String,
        entityId: json['entityId'] as String,
        payload: Map<String, dynamic>.from(json['payload'] as Map),
        createdAt: DateTime.parse(json['createdAt'] as String),
        attemptCount: json['attemptCount'] as int? ?? 0,
        nextRetryAt: DateTime.parse(json['nextRetryAt'] as String),
        status: MutationStatus.values.firstWhere(
          (value) => value.name == json['status'],
          orElse: () => MutationStatus.pending,
        ),
        lastError: json['lastError'] as String?,
      );
}

/// Durable, non-expiring mutation outbox powered by a dedicated Hive box.
class MutationOutboxService {
  static const String _outboxBoxName = 'durable_mutation_outbox';

  /// Retained for compatibility with existing monitoring and tests. Transient
  /// failures no longer become dead letters at this historical threshold.
  static const int maxRetryAttempts = 5;
  static const Duration maxRetryDelay = Duration(minutes: 15);
  static const int _maxBackoffExponent = 12;
  static const int _maxStoredErrorLength = 512;
  static final Random _random = Random();

  /// Default retention period for completed or cancelled outbox records.
  /// Records older than this threshold are eligible for garbage collection,
  /// provided they are not retained as prerequisites for active dependents.
  static const Duration defaultRetentionPeriod = Duration(days: 7);

  /// Maximum number of terminal (completed or cancelled) records retained
  /// per user in the outbox. Excess records beyond this cap are pruned
  /// oldest-first, without ever evicting a prerequisite required by an active dependent.
  static const int defaultMaxTerminalRecords = 100;

  static Box<String>? _box;
  static Future<Box<String>>? _openFuture;

  @visibleForTesting
  static void resetForTesting() {
    _box = null;
    _openFuture = null;
  }

  static Future<Box<String>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    if (_openFuture != null) return _openFuture!;

    final opening = Hive.openBox<String>(_outboxBoxName);
    _openFuture = opening;
    try {
      _box = await opening;
      return _box!;
    } finally {
      if (identical(_openFuture, opening)) _openFuture = null;
    }
  }

  static String _storageKey(String userId, String operationId) =>
      '${userId}_$operationId';

  static String _safeStoredError(String error) {
    final redacted = RedactionHelper.sanitize(error).trim();
    if (redacted.length <= _maxStoredErrorLength) return redacted;
    return '${redacted.substring(0, _maxStoredErrorLength - 1)}…';
  }

  Future<void> enqueueMutation(PendingMutation mutation) async {
    await _migrateLegacyOutboxIfNeeded(mutation.userId);
    final box = await _getBox();
    final key = _storageKey(mutation.userId, mutation.operationId);
    await box.put(key, jsonEncode(mutation.toJson()));

    AppLogger.debug(
      'Outbox: Enqueued ${mutation.operationType}',
      name: 'MutationOutbox',
      fields: {'operationId': mutation.operationId},
    );
  }

  Future<List<PendingMutation>> getPendingMutations(String userId) async {
    if (userId.isEmpty) return [];
    await _migrateLegacyOutboxIfNeeded(userId);

    final box = await _getBox();
    final prefix = '${userId}_';
    final result = <PendingMutation>[];

    for (final key in box.keys) {
      if (!key.toString().startsWith(prefix)) continue;
      final raw = box.get(key);
      if (raw == null) continue;
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final mutation = PendingMutation.fromJson(json);
        if (mutation.userId == userId &&
            mutation.status != MutationStatus.completed &&
            mutation.status != MutationStatus.cancelled) {
          result.add(mutation);
        }
      } catch (error) {
        AppLogger.warning(
          'Ignoring a corrupt outbox record.',
          name: 'MutationOutbox',
          fields: {'error': _safeStoredError(error.toString())},
        );
      }
    }

    result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return result;
  }

  Future<void> recordAttemptFailed(
    String userId,
    String operationId,
    String error, {
    bool isPermanent = false,
  }) async {
    final box = await _getBox();
    final key = _storageKey(userId, operationId);
    final raw = box.get(key);
    if (raw == null) return;

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final mutation = PendingMutation.fromJson(json);
      mutation.attemptCount += 1;
      mutation.lastError = _safeStoredError(error);

      if (isPermanent) {
        mutation.status = MutationStatus.deadLetter;
        AppLogger.warning(
          'Mutation moved to dead-letter state.',
          name: 'MutationOutbox',
          fields: {
            'operationId': operationId,
            'attemptCount': mutation.attemptCount,
          },
        );
      } else {
        mutation.status = MutationStatus.failed;
        final exponent = min(mutation.attemptCount, _maxBackoffExponent);
        final baseSeconds = min(1 << exponent, maxRetryDelay.inSeconds);
        final jitter = 0.8 + (_random.nextDouble() * 0.4);
        mutation.nextRetryAt = DateTime.now().add(
          Duration(seconds: (baseSeconds * jitter).round()),
        );
      }

      await box.put(key, jsonEncode(mutation.toJson()));
    } catch (storageError) {
      AppLogger.warning(
        'Failed to persist an outbox retry.',
        name: 'MutationOutbox',
        fields: {'error': _safeStoredError(storageError.toString())},
      );
      rethrow;
    }
  }

  /// Durably records completed status for an operation.
  /// Completion outcomes remain stored in Hive while dependent operations may query them.
  Future<void> markCompleted(String userId, String operationId) async {
    final box = await _getBox();
    final key = _storageKey(userId, operationId);
    final raw = box.get(key);
    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final mutation = PendingMutation.fromJson(json);
        mutation.status = MutationStatus.completed;
        await box.put(key, jsonEncode(mutation.toJson()));
        return;
      } catch (_) {}
    }
    // Record durable completed stub if original record was not found
    final stub = PendingMutation(
      operationId: operationId,
      userId: userId,
      operationType: 'completed_outcome',
      entityId: '',
      payload: const {},
      createdAt: DateTime.now(),
      status: MutationStatus.completed,
    );
    await box.put(key, jsonEncode(stub.toJson()));
  }

  /// Durably marks an operation as cancelled.
  Future<void> markCancelled(String userId, String operationId) async {
    final box = await _getBox();
    final key = _storageKey(userId, operationId);
    final raw = box.get(key);
    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final mutation = PendingMutation.fromJson(json);
        mutation.status = MutationStatus.cancelled;
        await box.put(key, jsonEncode(mutation.toJson()));
        return;
      } catch (_) {}
    }
    final stub = PendingMutation(
      operationId: operationId,
      userId: userId,
      operationType: 'cancelled_outcome',
      entityId: '',
      payload: const {},
      createdAt: DateTime.now(),
      status: MutationStatus.cancelled,
    );
    await box.put(key, jsonEncode(stub.toJson()));
  }

  /// Queries the durable status of a specific operation.
  Future<MutationStatus?> getMutationStatus(
    String userId,
    String operationId,
  ) async {
    if (userId.isEmpty || operationId.isEmpty) return null;
    final box = await _getBox();
    final key = _storageKey(userId, operationId);
    final raw = box.get(key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final statusStr = json['status'] as String?;
      if (statusStr == null) return null;
      return MutationStatus.values.firstWhere(
        (v) => v.name == statusStr,
        orElse: () => MutationStatus.pending,
      );
    } catch (_) {
      return null;
    }
  }

  /// Retrieves a specific mutation by its operation ID.
  Future<PendingMutation?> getMutation(
    String userId,
    String operationId,
  ) async {
    if (userId.isEmpty || operationId.isEmpty) return null;
    final box = await _getBox();
    final key = _storageKey(userId, operationId);
    final raw = box.get(key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return PendingMutation.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearQueueForUser(String userId) async {
    if (userId.isEmpty) return;
    final box = await _getBox();
    final prefix = '${userId}_';
    final keysToDelete = <dynamic>[];
    for (final key in box.keys) {
      if (!key.toString().startsWith(prefix)) continue;
      try {
        final raw = box.get(key);
        if (raw == null) continue;
        final data = jsonDecode(raw) as Map<String, dynamic>;
        if (data['userId'] == userId) keysToDelete.add(key);
      } catch (_) {
        // Never delete a record whose owner cannot be established.
      }
    }
    await box.deleteAll(keysToDelete);
  }

  /// Bounded garbage collection of terminal (completed and cancelled) outbox records.
  ///
  /// Guarantees:
  /// 1. Dependency-aware retention: Retains any completed or cancelled prerequisite
  ///    as long as at least one active ([MutationStatus.pending], [MutationStatus.syncing],
  ///    or [MutationStatus.failed]) dependent references its `dependsOnOperationId`.
  ///    A prerequisite can be removed only after all dependents reach a terminal state
  ///    ([MutationStatus.completed] or [MutationStatus.cancelled]).
  /// 2. Retention window: Unreferenced terminal records older than [retentionPeriod]
  ///    (default: 7 days) are evicted.
  /// 3. Bounded capacity: If the number of unreferenced terminal records exceeds
  ///    [maxTerminalRecords] (default: 100), the oldest are evicted to respect the cap.
  ///    Active dependents' prerequisites are strictly protected and NEVER evicted by the cap.
  ///
  /// Returns the count of deleted outbox records.
  Future<int> cleanUpTerminalMutations(
    String userId, {
    Duration retentionPeriod = defaultRetentionPeriod,
    int maxTerminalRecords = defaultMaxTerminalRecords,
    DateTime? now,
  }) async {
    if (userId.isEmpty) return 0;
    await _migrateLegacyOutboxIfNeeded(userId);

    final box = await _getBox();
    final prefix = '${userId}_';
    final currentTime = now ?? DateTime.now();
    final expirationCutoff = currentTime.subtract(retentionPeriod);

    final activePrerequisiteOpIds = <String>{};
    final terminalRecords = <({dynamic key, PendingMutation mutation})>[];

    // Single pass over the user's outbox records
    for (final key in box.keys) {
      if (!key.toString().startsWith(prefix)) continue;
      final raw = box.get(key);
      if (raw == null) continue;

      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final mutation = PendingMutation.fromJson(json);
        if (mutation.userId != userId) continue;

        final isTerminal =
            mutation.status == MutationStatus.completed ||
            mutation.status == MutationStatus.cancelled;

        if (!isTerminal) {
          // Active dependent: inspect payload for dependsOnOperationId
          final depOpId = mutation.payload['dependsOnOperationId'] as String?;
          if (depOpId != null && depOpId.isNotEmpty) {
            activePrerequisiteOpIds.add(depOpId);
          }
        } else {
          terminalRecords.add((key: key, mutation: mutation));
        }
      } catch (error) {
        // Leave unparseable records untouched during GC
      }
    }

    if (terminalRecords.isEmpty) return 0;

    // Partition terminal records into protected (referenced by an active dependent)
    // and candidate (eligible for expiration or capacity eviction).
    final candidateRecords = <({dynamic key, PendingMutation mutation})>[];

    for (final record in terminalRecords) {
      if (activePrerequisiteOpIds.contains(record.mutation.operationId)) {
        // Protected prerequisite: MUST NOT be evicted
        continue;
      }
      candidateRecords.add(record);
    }

    // Sort candidate records oldest-first by createdAt for deterministic eviction
    candidateRecords.sort(
      (a, b) => a.mutation.createdAt.compareTo(b.mutation.createdAt),
    );

    final keysToDelete = <dynamic>[];
    final remainingCandidates = <({dynamic key, PendingMutation mutation})>[];

    // 1. Time-based eviction for candidates older than the retention period
    for (final record in candidateRecords) {
      if (record.mutation.createdAt.isBefore(expirationCutoff)) {
        keysToDelete.add(record.key);
      } else {
        remainingCandidates.add(record);
      }
    }

    // 2. Capacity cap enforcement:
    // If remaining candidates + protected records exceed maxTerminalRecords,
    // evict the oldest remaining candidates until bounded or exhausted.
    final totalRetainedTerminal =
        remainingCandidates.length +
        (terminalRecords.length - candidateRecords.length);
    if (totalRetainedTerminal > maxTerminalRecords &&
        remainingCandidates.isNotEmpty) {
      final excessCount = totalRetainedTerminal - maxTerminalRecords;
      final toEvictCount = min(excessCount, remainingCandidates.length);
      for (var i = 0; i < toEvictCount; i++) {
        keysToDelete.add(remainingCandidates[i].key);
      }
    }

    if (keysToDelete.isNotEmpty) {
      await box.deleteAll(keysToDelete);
      AppLogger.debug(
        'Outbox: Cleaned up ${keysToDelete.length} terminal records for user $userId',
        name: 'MutationOutbox',
        fields: {
          'deletedCount': keysToDelete.length,
          'activePrerequisitesProtected': activePrerequisiteOpIds.length,
        },
      );
    }

    return keysToDelete.length;
  }

  Future<void> _migrateLegacyOutboxIfNeeded(String userId) async {
    if (userId.isEmpty) return;
    final legacyKey = 'mutation_outbox:$userId';

    try {
      final legacyData = await CacheService.get(
        legacyKey,
        (json) => (json['mutations'] as List?)
            ?.map(
              (item) => PendingMutation.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(),
      );

      if (legacyData != null && legacyData.isNotEmpty) {
        final box = await _getBox();
        for (final mutation in legacyData) {
          final key = _storageKey(userId, mutation.operationId);
          if (!box.containsKey(key)) {
            await box.put(key, jsonEncode(mutation.toJson()));
          }
        }
        await CacheService.delete(legacyKey);
        AppLogger.debug(
          'Migrated legacy outbox operations.',
          name: 'MutationOutbox',
          fields: {'count': legacyData.length},
        );
      }
    } catch (error) {
      AppLogger.warning(
        'Legacy outbox migration could not complete.',
        name: 'MutationOutbox',
        fields: {'error': _safeStoredError(error.toString())},
      );
    }
  }
}

final mutationOutboxProvider = Provider<MutationOutboxService>((ref) {
  return MutationOutboxService();
});
