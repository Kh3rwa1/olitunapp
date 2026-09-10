import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../logging/app_logger.dart';
import '../logging/redaction_helper.dart';
import '../storage/cache_service.dart';

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
          (value) => value.name == json['status'],
          orElse: () => MutationStatus.pending,
        ),
        lastError: json['lastError'] as String?,
      );
}

/// Durable, non-expiring mutation outbox powered by a dedicated Hive box.
class MutationOutboxService {
  static const String _outboxBoxName = 'durable_mutation_outbox';
  static const int maxRetryAttempts = 5;
  static const int _maxStoredErrorLength = 512;
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
            mutation.status != MutationStatus.completed) {
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

      if (isPermanent || mutation.attemptCount >= maxRetryAttempts) {
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
        final baseSeconds = 1 << mutation.attemptCount;
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

  Future<void> markCompleted(String userId, String operationId) async {
    final box = await _getBox();
    await box.delete(_storageKey(userId, operationId));
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
