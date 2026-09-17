// Repository abstraction for review state persistence.
//
// The memory engine (MemoryScheduler) stays the domain authority; this
// interface keeps local cache <-> cloud persistence as implementation
// details. Implementations: Appwrite (production) / fakes (tests).

import 'review_item.dart';

/// Stable recall operation payload (mirrors
/// `lib/features/review/data/review_recall_operation.dart` without importing
/// data-layer code into the domain contract).
class ReviewRecallOperationPayload {
  final String operationId;
  final String userId;
  final String itemId;
  final ReviewItemType itemType;
  final ReviewExerciseType exerciseType;
  final bool correct;
  final int? responseTimeMs;
  final DateTime occurredAt;
  final String deviceId;
  final int localSequence;
  final int schemaVersion;

  const ReviewRecallOperationPayload({
    required this.operationId,
    required this.userId,
    required this.itemId,
    required this.itemType,
    required this.exerciseType,
    required this.correct,
    this.responseTimeMs,
    required this.occurredAt,
    required this.deviceId,
    required this.localSequence,
    required this.schemaVersion,
  });

  Map<String, dynamic> toMap() => {
    'operationId': operationId,
    'userId': userId,
    'itemId': itemId,
    'itemType': itemType.json,
    'exerciseType': exerciseType.json,
    'correct': correct,
    'responseTimeMs': responseTimeMs,
    'occurredAt': occurredAt.toIso8601String(),
    'deviceId': deviceId,
    'localSequence': localSequence,
    'schemaVersion': schemaVersion,
  };
}

/// Where a remote state came from relative to the local cache.
enum ReviewMergeAction { adopted, keptLocal, pushedLocal, skipped }

class ReviewSyncResult {
  final int pulled;
  final int adopted;
  final int keptLocal;
  final int pushedLocal;
  final int failed;
  final int skipped;

  const ReviewSyncResult({
    required this.pulled,
    required this.adopted,
    required this.keptLocal,
    required this.pushedLocal,
    required this.failed,
    required this.skipped,
  });

  bool get isClean => failed == 0;

  static const empty = ReviewSyncResult(
    pulled: 0,
    adopted: 0,
    keptLocal: 0,
    pushedLocal: 0,
    failed: 0,
    skipped: 0,
  );
}

abstract class ReviewRepository {
  /// All remote states for [userId]. Malformed rows are skipped by the
  /// implementation (deleted/deprecated content must never break sync).
  Future<List<MemoryItemState>> loadRemoteStates(String userId);

  /// Upsert one state. Deterministic per-user identity; implementations
  /// must tolerate duplicate pushes (idempotent).
  Future<void> pushState(String userId, MemoryItemState item);

  /// Delete one state. Deterministic per-user identity; implementations
  /// must tolerate missing remote rows (idempotent).
  Future<void> deleteState(String userId, String itemId);
}

/// Optional operation-aware extension. Repositories that speak the
/// `applyRecall` function action implement this; [ReviewStateSync] falls
/// back to snapshot push when the repository does not support it.
abstract class ReviewOperationRepository extends ReviewRepository {
  /// Applies one stable recall operation idempotently by operationId.
  /// Returns true when newly applied, false when it was a duplicate.
  Future<bool> applyRecallOperation(
    String userId,
    ReviewRecallOperationPayload op,
  );
}
