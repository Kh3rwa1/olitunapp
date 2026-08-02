import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  factory PendingMutation.fromJson(Map<String, dynamic> json) => PendingMutation(
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

class MutationOutboxService {
  static const String _storagePrefix = 'mutation_outbox:';
  static const int maxRetryAttempts = 5;

  static String _getKey(String userId) => '$_storagePrefix$userId';

  /// Add operation to durable user outbox
  Future<void> enqueueMutation(PendingMutation mutation) async {
    final key = _getKey(mutation.userId);
    final existing = await getPendingMutations(mutation.userId);

    // Prevent duplicate operationId (idempotency)
    existing.removeWhere((m) => m.operationId == mutation.operationId);
    existing.add(mutation);

    await CacheService.set(
      key,
      {'mutations': existing.map((m) => m.toJson()).toList()},
    );
    AppLogger.debug('Outbox: Enqueued operation ${mutation.operationId} for user ${mutation.userId}');
  }

  /// Get pending operations for a user
  Future<List<PendingMutation>> getPendingMutations(String userId) async {
    if (userId.isEmpty) return [];

    final key = _getKey(userId);
    final data = await CacheService.get(
      key,
      (json) => (json['mutations'] as List)
          .map((item) => PendingMutation.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );

    return data ?? [];
  }

  /// Record retry attempt with exponential backoff
  Future<void> recordAttemptFailed(String userId, String operationId, String error) async {
    final list = await getPendingMutations(userId);
    final index = list.indexWhere((m) => m.operationId == operationId);

    if (index != -1) {
      final mutation = list[index];
      mutation.attemptCount += 1;
      mutation.lastError = error;

      if (mutation.attemptCount >= maxRetryAttempts) {
        mutation.status = MutationStatus.deadLetter;
        AppLogger.debug('Outbox: Operation $operationId moved to dead-letter state after $maxRetryAttempts attempts');
      } else {
        mutation.status = MutationStatus.failed;
        // Exponential backoff: 2^attemptCount seconds
        final backoffSeconds = 1 << mutation.attemptCount;
        mutation.nextRetryAt = DateTime.now().add(Duration(seconds: backoffSeconds));
      }

      await CacheService.set(_getKey(userId), {'mutations': list.map((m) => m.toJson()).toList()});
    }
  }

  /// Remove completed mutation
  Future<void> markCompleted(String userId, String operationId) async {
    final list = await getPendingMutations(userId);
    list.removeWhere((m) => m.operationId == operationId);
    await CacheService.set(_getKey(userId), {'mutations': list.map((m) => m.toJson()).toList()});
  }

  /// Purge/isolate queue on account logout
  Future<void> clearQueueForUser(String userId) async {
    if (userId.isNotEmpty) {
      await CacheService.delete(_getKey(userId));
    }
  }
}

final mutationOutboxProvider = Provider<MutationOutboxService>((ref) {
  return MutationOutboxService();
});
