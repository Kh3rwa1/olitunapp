// Repository abstraction for review state persistence.
//
// The memory engine (MemoryScheduler) stays the domain authority; this
// interface keeps local cache <-> cloud persistence as implementation
// details. Implementations: Appwrite (production) / fakes (tests).

import 'review_item.dart';

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
}
