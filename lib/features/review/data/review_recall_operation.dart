// Stable recall operations: the authority for multi-device review sync.
//
// Each answered question produces exactly one [ReviewRecallOperation] with a
// globally unique, retry-stable [operationId]. The server applies operations
// idempotently by [operationId]: duplicate delivery (retry after timeout,
// reconnect replay, process death between enqueue and acknowledgement)
// never applies the same recall twice.
//
// Rules enforced here and in `functions/mutateReviewState`:
// 1. The local scheduler applies the operation optimistically.
// 2. The operation is persisted to the durable outbox before UI success
//    depends on cloud state.
// 3. The server accepts operations idempotently by [operationId].
// 4. Duplicate delivery does not apply the recall twice.
// 5. The server applies operations in documented deterministic order
//    ([compareForServerApply]: occurredAt, then operationId).
// 6. The server maintains the derived review-state snapshot.
// 7. Pull returns the authoritative snapshot plus cursor/revision.
// 8. Pending local operations remain applicable after pulling server state.
// 9. Deletion/tombstone operations order explicitly after the operations
//    they depend on (see outbox dependency gates in review_state_sync.dart).
// 10. Clock skew never determines ownership and never loses operations:
//    ordering uses occurredAt only as a hint; convergence does not depend
//    on wall-clock agreement between devices.
//
// Transition: existing `review_states` snapshot rows are kept. They become
// the baseline snapshot/revision onto which operation effects apply; see
// docs/architecture/review_sync_operations.md. Old clients that only push
// snapshots remain safe: their writes are treated as single anonymous
// operations keyed by (userId, itemId, lastReviewedAt).

import '../domain/review_item.dart';

/// Where a recall happened. Kept for analytics/debugging; never affects
/// ordering, ownership, or counting.
enum RecallSource { quiz, review, typing, content, unknown }

extension RecallSourceX on RecallSource {
  String get json => name;
  static RecallSource fromJson(String? raw) {
    switch (raw) {
      case 'quiz':
        return RecallSource.quiz;
      case 'review':
        return RecallSource.review;
      case 'typing':
        return RecallSource.typing;
      case 'content':
        return RecallSource.content;
      case 'unknown':
      default:
        return RecallSource.unknown;
    }
  }
}

class ReviewRecallOperation {
  /// Globally unique and stable across retries. Format:
  /// `op_<userIdHash>_<deviceId>_<localSequence>` or a UUID v4.
  /// The server dedupes on this value.
  final String operationId;

  /// Client-claimed user id. NEVER trusted: the server derives ownership
  /// from the verified session and rejects mismatches (403).
  final String userId;

  final String itemId;
  final ReviewItemType itemType;
  final ReviewExerciseType exerciseType;
  final bool correct;
  final int? responseTimeMs;

  /// When the recall occurred on the device (UTC). Ordering hint only.
  final DateTime occurredAt;

  /// Stable per-install device/instance id. Distinguishes two devices that
  /// recall the same item at the same millisecond.
  final String deviceId;

  /// Monotonic counter per device. Together with [deviceId] gives a total
  /// order per device without trusting clocks.
  final int localSequence;

  final int schemaVersion;
  final RecallSource source;

  /// When the operation record was created locally (UTC).
  final DateTime createdAt;

  const ReviewRecallOperation({
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
    this.source = RecallSource.unknown,
    required this.createdAt,
  });

  /// Deterministic server apply order. Total: (occurredAt, deviceId,
  /// localSequence, operationId) — no wall-clock trust required for
  /// convergence, and ties can never depend on delivery order.
  static int compareForServerApply(
    ReviewRecallOperation a,
    ReviewRecallOperation b,
  ) {
    if (a.operationId == b.operationId) return 0;
    final t = a.occurredAt.compareTo(b.occurredAt);
    if (t != 0) return t;
    final d = a.deviceId.compareTo(b.deviceId);
    if (d != 0) return d;
    final s = a.localSequence.compareTo(b.localSequence);
    if (s != 0) return s;
    return a.operationId.compareTo(b.operationId);
  }

  /// Payload validation for the client enqueue path AND the server boundary.
  /// Returns null when valid, otherwise a machine-readable reason.
  String? validate({int maxItemIdLength = 256}) {
    if (operationId.isEmpty || operationId.length > 128) {
      return 'invalid operationId';
    }
    if (userId.isEmpty) return 'missing userId';
    final trimmedItem = itemId.trim();
    if (trimmedItem.isEmpty || trimmedItem.length > maxItemIdLength) {
      return 'invalid itemId';
    }
    if (responseTimeMs != null &&
        (responseTimeMs! < 0 || responseTimeMs! > 3600000)) {
      return 'invalid responseTimeMs';
    }
    if (localSequence < 0) return 'invalid localSequence';
    if (deviceId.isEmpty) return 'missing deviceId';
    return null;
  }

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
    'source': source.json,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ReviewRecallOperation.fromMap(Map<String, dynamic> map) {
    DateTime parse(String? raw) =>
        DateTime.tryParse(raw ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
    return ReviewRecallOperation(
      operationId: (map['operationId'] ?? '').toString(),
      userId: (map['userId'] ?? '').toString(),
      itemId: (map['itemId'] ?? '').toString(),
      itemType: ReviewItemTypeX.fromJson(map['itemType'] as String?),
      exerciseType: ReviewExerciseTypeX.fromJson(
        map['exerciseType'] as String?,
      ),
      correct: map['correct'] == true,
      responseTimeMs: (map['responseTimeMs'] as num?)?.toInt(),
      occurredAt: parse(map['occurredAt'] as String?),
      deviceId: (map['deviceId'] ?? '').toString(),
      localSequence: (map['localSequence'] as num?)?.toInt() ?? 0,
      schemaVersion: (map['schemaVersion'] as num?)?.toInt() ?? 1,
      source: RecallSourceX.fromJson(map['source'] as String?),
      createdAt: parse(map['createdAt'] as String?),
    );
  }
}
