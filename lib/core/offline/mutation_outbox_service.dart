import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../storage/cache_service.dart';
import '../logging/app_logger.dart';

enum MutationStatus { pending, syncing, completed, failed, deadLetter }

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
          (e) => e.name == json['status'],
          orElse: () => MutationStatus.pending,
        ),
        lastError: json['lastError'] as String?,
      );
}

/// Durable, non-expiring mutation outbox powered by a dedicated Hive box.
class MutationOutboxService {
  static const String _outboxBoxName = 'durable_mutation_outbox';
  static const int maxRetryAttempts = 5;
  static final Random _random = Random();

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
      // Cache only an in-flight open, never a rejected Future or closed box.
      if (identical(_openFuture, opening)) _openFuture = null;
    }
  }

  static String _storageKey(String userId, String operationId) =>
      '${userId}_$operationId';

  /// Add or update operation in dedicated durable storage.
  /// Automatically migrates any legacy outbox records stored in CacheService.
  Future<void> enqueueMutation(PendingMutation mutation) async {
    await _migrateLegacyOutboxIfNeeded(mutation.userId);
    final box = await _getBox();
    final key = _storageKey(mutation.userId, mutation.operationId);

    final jsonStr = jsonEncode(mutation.toJson());
    await box.put(key, jsonStr);

    AppLogger.debug(
      'Outbox: Enqueued mutation ${mutation.operationId} (type: ${mutation.operationType}) for user ${mutation.userId}',
    );
  }

  /// Retrieve all non-completed pending/failed mutations for a given user.
  Future<List<PendingMutation>> getPendingMutations(String userId) async {
    if (userId.isEmpty) return [];
    await _migrateLegacyOutboxIfNeeded(userId);

    final box = await _getBox();
    final prefix = '${userId}_';
    final result = <PendingMutation>[];

    for (final key in box.keys) {
      if (key.toString().startsWith(prefix)) {
        final raw = box.get(key);
        if (raw == null) continue;
        try {
          final json = jsonDecode(raw) as Map<String, dynamic>;
          final mutation = PendingMutation.fromJson(json);
          if (mutation.userId == userId &&
              mutation.status != MutationStatus.completed) {
            result.add(mutation);
          }
        } catch (e) {
          AppLogger.debug('Outbox: Corrupted record at key $key: $e');
        }
      }
    }

    result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return result;
  }

  /// Record retry attempt with bounded exponential backoff and jitter.
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
      mutation.lastError = error;

      if (isPermanent || mutation.attemptCount >= maxRetryAttempts) {
        mutation.status = MutationStatus.deadLetter;
        AppLogger.debug(
          'Outbox: Operation $operationId moved to dead-letter state after ${mutation.attemptCount} attempts',
        );
      } else {
        mutation.status = MutationStatus.failed;
        // Bounded exponential backoff with jitter
        final baseSeconds = 1 << mutation.attemptCount;
        final jitter = 0.8 + (_random.nextDouble() * 0.4);
        final backoffSeconds = (baseSeconds * jitter).round();
        mutation.nextRetryAt = DateTime.now().add(
          Duration(seconds: backoffSeconds),
        );
      }

      await box.put(key, jsonEncode(mutation.toJson()));
    } catch (e) {
      AppLogger.debug('Outbox: Failed to record failure for $operationId: $e');
      rethrow;
    }
  }

  /// Remove completed mutation upon server confirmation.
  Future<void> markCompleted(String userId, String operationId) async {
    final box = await _getBox();
    final key = _storageKey(userId, operationId);
    await box.delete(key);
  }

  /// Purge outbox queue on user logout.
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
        // User IDs may contain underscores: a prefix is not ownership proof.
        if (data['userId'] == userId) keysToDelete.add(key);
      } catch (_) {
        // Do not delete a record whose owner cannot be established.
      }
    }
    await box.deleteAll(keysToDelete);
  }

  /// Migrate legacy mutations from old CacheService box into dedicated Hive outbox box.
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
        for (final m in legacyData) {
          final k = _storageKey(userId, m.operationId);
          if (!box.containsKey(k)) {
            await box.put(k, jsonEncode(m.toJson()));
          }
        }
        await CacheService.delete(legacyKey);
        AppLogger.debug(
          'Outbox: Successfully migrated ${legacyData.length} legacy operations for user $userId',
        );
      }
    } catch (e) {
      AppLogger.debug('Outbox: Legacy migration note: $e');
    }
  }
}

final mutationOutboxProvider = Provider<MutationOutboxService>((ref) {
  return MutationOutboxService();
});
