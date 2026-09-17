// Review sync outbox port: operation-type constants, the minimal outbox
// contract (+ production adapter), and sync health metrics.
// (Orchestration lives in review_state_sync.dart.)

import 'dart:async';

import '../../../core/offline/mutation_outbox_service.dart';

/// Outbox operation type for stable recall operations (preferred path: one
/// entry per answered question, idempotent by `operationId`).
const reviewRecallOperationType = 'review_state.recall';

/// Outbox operation type for review-state upserts (one replay handler).
/// Compatibility path: snapshot upserts for old clients and pull-adoption.
/// New recalls enqueue [reviewRecallOperationType] instead.
const reviewStateOperationType = 'review_state.upsert';

/// Sync health metrics (WS7). Updated by [ReviewStateSync]; surfaced to
/// diagnostics. Never includes raw learning text or sensitive data.
class ReviewSyncMetrics {
  int pendingOperations = 0;
  Duration oldestPendingAge = Duration.zero;
  int replaySuccess = 0;
  int replayFailure = 0;
  int deadLetterCount = 0;
  int duplicateOperationCount = 0;
  int totalRecallOperations = 0;
  int totalAnsweredQuestions = 0;
  Duration lastSyncDuration = Duration.zero;
  int lastBytesWritten = 0;

  /// Mean operations enqueued per answered question. Healthy == ~1.0;
  /// values >> 1 indicate redundant snapshot spam.
  double get averageOperationsPerAnswer => totalAnsweredQuestions == 0
      ? 0
      : totalRecallOperations / totalAnsweredQuestions;

  Map<String, Object?> toMap() => {
    'pendingOperations': pendingOperations,
    'oldestPendingAgeMs': oldestPendingAge.inMilliseconds,
    'replaySuccess': replaySuccess,
    'replayFailure': replayFailure,
    'deadLetterCount': deadLetterCount,
    'duplicateOperationCount': duplicateOperationCount,
    'averageOperationsPerAnswer': averageOperationsPerAnswer,
    'lastSyncDurationMs': lastSyncDuration.inMilliseconds,
    'lastBytesWritten': lastBytesWritten,
  };
}

/// Outbox operation type for review-state cloud deletion (idempotent).
const reviewStateDeleteOperationType = 'review_state.delete';

/// Minimal outbox contract needed by review sync. MutationOutboxService
/// satisfies it in production (adapter in review_sync_init.dart); tests
/// use an in-memory fake — no Hive, no Appwrite.
abstract class ReviewOutbox {
  Future<void> enqueueMutation(PendingMutation mutation);
  Future<List<PendingMutation>> getPendingMutations(String userId);
  Future<void> recordAttemptFailed(
    String userId,
    String operationId,
    String error, {
    bool isPermanent = false,
  });
  Future<void> markCompleted(String userId, String operationId);
  Future<MutationStatus?> getMutationStatus(String userId, String operationId);
  Future<PendingMutation?> getMutation(String userId, String operationId);
}

class MutationOutboxAdapter implements ReviewOutbox {
  final MutationOutboxService _service;
  const MutationOutboxAdapter(this._service);

  @override
  Future<void> enqueueMutation(PendingMutation mutation) =>
      _service.enqueueMutation(mutation);

  @override
  Future<List<PendingMutation>> getPendingMutations(String userId) =>
      _service.getPendingMutations(userId);

  @override
  Future<void> recordAttemptFailed(
    String userId,
    String operationId,
    String error, {
    bool isPermanent = false,
  }) => _service.recordAttemptFailed(
    userId,
    operationId,
    error,
    isPermanent: isPermanent,
  );

  @override
  Future<void> markCompleted(String userId, String operationId) =>
      _service.markCompleted(userId, operationId);

  @override
  Future<MutationStatus?> getMutationStatus(
    String userId,
    String operationId,
  ) => _service.getMutationStatus(userId, operationId);

  @override
  Future<PendingMutation?> getMutation(String userId, String operationId) =>
      _service.getMutation(userId, operationId);
}
