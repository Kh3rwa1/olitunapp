import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../storage/hive_compat.dart';

enum MutationStatus { pending, inFlight, failed, succeeded, deadLetter }

class PendingMutation {
  final String operationId;
  final String userId;
  final String operationType;
  final String entityId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int attemptCount;
  final DateTime? lastAttemptAt;
  final DateTime? nextRetryAt;
  final String? lastError;
  final MutationStatus status;

  const PendingMutation({
    required this.operationId,
    required this.userId,
    required this.operationType,
    required this.entityId,
    required this.payload,
    required this.createdAt,
    this.attemptCount = 0,
    this.lastAttemptAt,
    this.nextRetryAt,
    this.lastError,
    this.status = MutationStatus.pending,
  });

  PendingMutation copyWith({
    int? attemptCount,
    DateTime? lastAttemptAt,
    DateTime? nextRetryAt,
    bool clearNextRetryAt = false,
    String? lastError,
    bool clearLastError = false,
    MutationStatus? status,
  }) {
    return PendingMutation(
      operationId: operationId,
      userId: userId,
      operationType: operationType,
      entityId: entityId,
      payload: Map<String, dynamic>.from(payload),
      createdAt: createdAt,
      attemptCount: attemptCount ?? this.attemptCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      nextRetryAt: clearNextRetryAt ? null : (nextRetryAt ?? this.nextRetryAt),
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() => {
    'operationId': operationId,
    'userId': userId,
    'operationType': operationType,
    'entityId': entityId,
    'payload': payload,
    'createdAt': createdAt.toIso8601String(),
    'attemptCount': attemptCount,
    'lastAttemptAt': lastAttemptAt?.toIso8601String(),
    'nextRetryAt': nextRetryAt?.toIso8601String(),
    'lastError': lastError,
    'status': status.name,
  };

  factory PendingMutation.fromMap(Map<String, dynamic> map) {
    return PendingMutation(
      operationId: map['operationId'] as String,
      userId: map['userId'] as String,
      operationType: map['operationType'] as String,
      entityId: map['entityId'] as String,
      payload: Map<String, dynamic>.from(
        (map['payload'] as Map?) ?? const <String, dynamic>{},
      ),
      createdAt: DateTime.parse(map['createdAt'] as String),
      attemptCount: map['attemptCount'] as int? ?? 0,
      lastAttemptAt: _parseDate(map['lastAttemptAt']),
      nextRetryAt: _parseDate(map['nextRetryAt']),
      lastError: map['lastError'] as String?,
      status: MutationStatus.values.firstWhere(
        (value) => value.name == map['status'],
        orElse: () => MutationStatus.pending,
      ),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}

class ReplayReport {
  final int attempted;
  final int succeeded;
  final int failed;
  final int skipped;

  const ReplayReport({
    required this.attempted,
    required this.succeeded,
    required this.failed,
    required this.skipped,
  });
}

class MutationOutboxService {
  MutationOutboxService();

  static const int schemaVersion = 3;

  /// Kept for source compatibility with older callers. Transient mutations no
  /// longer become dead letters after a fixed number of attempts.
  @Deprecated('Transient mutations retry indefinitely with capped backoff.')
  static const int maxRetryAttempts = 5;

  static const Duration maxRetryDelay = Duration(minutes: 15);
  static const int maxTerminalRecordsPerUser = 100;
  static const Duration terminalRetention = Duration(days: 7);
  static const Duration inFlightLease = Duration(minutes: 2);
  static const String _boxName = 'mutation_outbox_v1';
  static const String _migrationKey = '__schema_version__';
  static const int _maxBackoffExponent = 12;

  Box<String>? _box;
  bool _initialized = false;
  Future<void> _serial = Future<void>.value();
  final StreamController<String> _changes =
      StreamController<String>.broadcast();

  bool get isInitialized => _initialized;
  Stream<String> get changes => _changes.stream;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await HiveCompat.ensureInitialized();
      _box = await Hive.openBox<String>(_boxName);
      await _migrate();
      await _recoverExpiredInFlightMutations();
      _initialized = true;
    } catch (_) {
      _box = null;
      _initialized = false;
      rethrow;
    }
  }

  Future<void> dispose() async {
    await _changes.close();
  }

  Future<void> enqueueMutation(PendingMutation mutation) {
    return _synchronized(() async {
      _requireInitialized();
      if (mutation.operationId.isEmpty || mutation.userId.isEmpty) {
        throw ArgumentError('Mutation requires operationId and userId.');
      }
      final key = _storageKey(mutation.userId, mutation.operationId);
      if (_box!.containsKey(key)) return;
      await _box!.put(key, jsonEncode(mutation.toMap()));
      _changes.add(mutation.userId);
    });
  }

  Future<List<PendingMutation>> getPendingMutations(String userId) {
    return _synchronized(() async {
      _requireInitialized();
      final items = _mutationsForUser(userId);
      items.sort((left, right) => left.createdAt.compareTo(right.createdAt));
      return items;
    });
  }

  Future<ReplayReport> replayPendingMutations({
    required String userId,
    required Future<void> Function(PendingMutation mutation) handler,
    DateTime? now,
  }) {
    return _synchronized(() async {
      _requireInitialized();
      final replayStartedAt = now ?? DateTime.now().toUtc();
      var attempted = 0;
      var succeeded = 0;
      var failed = 0;
      var skipped = 0;

      final blockedEntities = <String>{};
      final items = _mutationsForUser(userId)
        ..sort((left, right) => left.createdAt.compareTo(right.createdAt));

      for (final mutation in items) {
        final entityKey = '${mutation.operationType}:${mutation.entityId}';
        if (mutation.status == MutationStatus.succeeded ||
            mutation.status == MutationStatus.deadLetter) {
          skipped++;
          continue;
        }
        if (blockedEntities.contains(entityKey)) {
          skipped++;
          continue;
        }
        if (mutation.nextRetryAt != null &&
            mutation.nextRetryAt!.isAfter(replayStartedAt)) {
          skipped++;
          continue;
        }

        attempted++;
        final inFlight = mutation.copyWith(
          status: MutationStatus.inFlight,
          lastAttemptAt: replayStartedAt,
          clearNextRetryAt: true,
        );
        await _persist(inFlight);

        try {
          await handler(inFlight);
          await _persist(
            inFlight.copyWith(
              status: MutationStatus.succeeded,
              clearLastError: true,
              clearNextRetryAt: true,
            ),
          );
          succeeded++;
        } catch (error) {
          final permanent = _isPermanentFailure(error);
          await _recordAttemptFailedInternal(
            mutation: inFlight,
            error: error,
            isPermanent: permanent,
            now: replayStartedAt,
          );
          blockedEntities.add(entityKey);
          failed++;
        }
      }

      return ReplayReport(
        attempted: attempted,
        succeeded: succeeded,
        failed: failed,
        skipped: skipped,
      );
    });
  }

  Future<void> recordAttemptFailed({
    required String userId,
    required String operationId,
    required Object error,
    bool isPermanent = false,
    DateTime? now,
  }) {
    return _synchronized(() async {
      _requireInitialized();
      final mutation = _findMutation(userId, operationId);
      if (mutation == null) return;
      await _recordAttemptFailedInternal(
        mutation: mutation,
        error: error,
        isPermanent: isPermanent,
        now: now ?? DateTime.now().toUtc(),
      );
    });
  }

  /// Requeues a permanent dead letter after an operator or app update has
  /// corrected the underlying payload or server-side validation problem.
  Future<void> retryDeadLetter({
    required String userId,
    required String operationId,
  }) {
    return _synchronized(() async {
      _requireInitialized();
      final mutation = _findMutation(userId, operationId);
      if (mutation == null || mutation.status != MutationStatus.deadLetter) {
        return;
      }
      await _persist(
        mutation.copyWith(
          attemptCount: 0,
          status: MutationStatus.pending,
          clearLastError: true,
          clearNextRetryAt: true,
        ),
      );
      _changes.add(userId);
    });
  }

  Future<void> markSucceeded({
    required String userId,
    required String operationId,
  }) {
    return _synchronized(() async {
      _requireInitialized();
      final mutation = _findMutation(userId, operationId);
      if (mutation == null) return;
      await _persist(
        mutation.copyWith(
          status: MutationStatus.succeeded,
          clearLastError: true,
          clearNextRetryAt: true,
        ),
      );
    });
  }

  Future<void> removeTerminalMutations({
    required String userId,
    DateTime? now,
  }) {
    return _synchronized(() async {
      _requireInitialized();
      final cleanupAt = now ?? DateTime.now().toUtc();
      final items = _mutationsForUser(userId);
      final pendingEntityKeys = items
          .where(
            (item) =>
                item.status != MutationStatus.succeeded &&
                item.status != MutationStatus.deadLetter,
          )
          .map((item) => '${item.operationType}:${item.entityId}')
          .toSet();

      final terminal =
          items
              .where(
                (item) =>
                    item.status == MutationStatus.succeeded ||
                    item.status == MutationStatus.deadLetter,
              )
              .toList()
            ..sort((left, right) => right.createdAt.compareTo(left.createdAt));

      final keysToDelete = <String>[];
      for (var index = 0; index < terminal.length; index++) {
        final item = terminal[index];
        final itemAge = cleanupAt.difference(
          item.lastAttemptAt ?? item.createdAt,
        );
        final entityKey = '${item.operationType}:${item.entityId}';
        final dependencyExists = pendingEntityKeys.contains(entityKey);
        if (!dependencyExists &&
            (itemAge > terminalRetention ||
                index >= maxTerminalRecordsPerUser)) {
          keysToDelete.add(_storageKey(userId, item.operationId));
        }
      }
      await _box!.deleteAll(keysToDelete);
    });
  }

  Future<void> clearUser(String userId) {
    return _synchronized(() async {
      _requireInitialized();
      await _box!.deleteAll(_keysForUser(userId));
    });
  }

  Future<void> _recordAttemptFailedInternal({
    required PendingMutation mutation,
    required Object error,
    required bool isPermanent,
    required DateTime now,
  }) async {
    final attemptCount = mutation.attemptCount + 1;
    final status = isPermanent
        ? MutationStatus.deadLetter
        : MutationStatus.failed;
    DateTime? nextRetryAt;
    if (status == MutationStatus.failed) {
      final exponent = math.min(attemptCount, _maxBackoffExponent);
      final delaySeconds = math.min(1 << exponent, maxRetryDelay.inSeconds);
      final jitterMilliseconds = mutation.operationId.hashCode.abs() % 1000;
      nextRetryAt = now.add(
        Duration(seconds: delaySeconds, milliseconds: jitterMilliseconds),
      );
    }

    await _persist(
      mutation.copyWith(
        attemptCount: attemptCount,
        lastAttemptAt: now,
        nextRetryAt: nextRetryAt,
        clearNextRetryAt: nextRetryAt == null,
        lastError: _redactError(error.toString()),
        status: status,
      ),
    );
  }

  Future<void> _recoverExpiredInFlightMutations() async {
    final box = _box;
    if (box == null) return;
    final now = DateTime.now().toUtc();
    for (final entry in box.toMap().entries) {
      if (entry.key == _migrationKey) continue;
      final mutation = _decodeMutation(entry.value);
      if (mutation == null || mutation.status != MutationStatus.inFlight) {
        continue;
      }
      final leaseStart = mutation.lastAttemptAt ?? mutation.createdAt;
      if (now.difference(leaseStart) < inFlightLease) continue;
      await _persist(
        mutation.copyWith(
          status: MutationStatus.failed,
          nextRetryAt: now,
          lastError: 'Interrupted before acknowledgement',
        ),
      );
    }
  }

  Future<void> _migrate() async {
    final box = _box!;
    final current = int.tryParse(box.get(_migrationKey) ?? '') ?? 0;
    if (current >= schemaVersion) return;
    await box.put(_migrationKey, '$schemaVersion');
  }

  List<PendingMutation> _mutationsForUser(String userId) {
    final expectedHash = _userHash(userId);
    final items = <PendingMutation>[];
    for (final entry in _box!.toMap().entries) {
      if (entry.key == _migrationKey) continue;
      final scoped = _scopedIndex(entry.key);
      if (scoped == null || scoped.userHash != expectedHash) continue;
      final mutation = _decodeMutation(entry.value);
      if (mutation == null || mutation.userId != userId) continue;
      items.add(mutation);
    }
    return items;
  }

  PendingMutation? _findMutation(String userId, String operationId) {
    final raw = _box!.get(_storageKey(userId, operationId));
    final mutation = _decodeMutation(raw);
    if (mutation?.userId != userId || mutation?.operationId != operationId) {
      return null;
    }
    return mutation;
  }

  PendingMutation? _decodeMutation(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return PendingMutation.fromMap(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  Iterable<String> _keysForUser(String userId) {
    final expectedHash = _userHash(userId);
    return _box!.keys.whereType<String>().where((key) {
      final scoped = _scopedIndex(key);
      return scoped?.userHash == expectedHash;
    });
  }

  Future<void> _persist(PendingMutation mutation) async {
    await _box!.put(
      _storageKey(mutation.userId, mutation.operationId),
      jsonEncode(mutation.toMap()),
    );
  }

  String _storageKey(String userId, String operationId) =>
      '${_userHash(userId)}::$operationId';

  String _userHash(String userId) =>
      sha256.convert(utf8.encode(userId)).toString();

  _ScopedIndex? _scopedIndex(String key) {
    final split = key.indexOf('::');
    if (split <= 0 || split >= key.length - 2) return null;
    return _ScopedIndex(
      userHash: key.substring(0, split),
      operationId: key.substring(split + 2),
    );
  }

  bool _isPermanentFailure(Object error) {
    if (error is FormatException || error is ArgumentError) return true;
    final text = error.toString().toLowerCase();
    return text.contains('invalid payload') ||
        text.contains('unsupported operation') ||
        text.contains('permission denied');
  }

  String _redactError(String input) {
    var redacted = input;
    redacted = redacted.replaceAll(
      RegExp(
        r'([A-Za-z0-9._%+-]+)@([A-Za-z0-9.-]+\.[A-Za-z]{2,})',
        caseSensitive: false,
      ),
      '[redacted-email]',
    );
    redacted = redacted.replaceAll(
      RegExp(
        r'(token|secret|authorization|cookie|session|password)\s*[:=]\s*[^\s,;]+',
        caseSensitive: false,
      ),
      r'$1=[redacted]',
    );
    if (redacted.length > 500) return redacted.substring(0, 500);
    return redacted;
  }

  void _requireInitialized() {
    if (!_initialized || _box == null) {
      throw StateError('MutationOutboxService has not been initialized.');
    }
  }

  Future<T> _synchronized<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _serial = _serial.then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }
}

class _ScopedIndex {
  final String userHash;
  final String operationId;

  const _ScopedIndex({required this.userHash, required this.operationId});
}

final mutationOutboxProvider = Provider<MutationOutboxService>((ref) {
  throw UnimplementedError(
    'mutationOutboxProvider must be overridden after initialization.',
  );
});
