// Deterministic snapshot reconciliation for review states.
//
// HONEST SCOPE: this merges two scheduler *snapshots* for the same item.
// Snapshot merging alone CANNOT preserve all independent events from two
// devices (counters combined with max() are a lower bound, not a sum).
// The authority for exact recall counting is the operation log — see
// [ReviewRecallOperation] (review_recall_operation.dart): each recall is a
// stable idempotent operation applied exactly once server-side. This
// snapshot merge is the backward-compatible read path only.
//
// Determinism guarantee: merge(a, b) == merge(b, a) — argument order never
// affects the result. Ties on timestamps are broken by evidence totals and
// then by stable field ordering, never by which argument came first.
// (The previous implementation claimed commutativity/associativity while
// its timestamp-tie branches depended on argument order; that claim was
// false and has been removed. Associativity across three snapshots is NOT
// claimed — operation replay, not chained snapshot merges, converges
// multi-device histories.)

import 'dart:math';

import 'memory_scheduler.dart';
import 'review_item.dart';

class ReviewStateMergePolicy {
  const ReviewStateMergePolicy._();

  /// Deterministically merges two memory states for the SAME item.
  ///
  /// - Throws [ArgumentError] if itemIds differ OR if itemTypes differ
  ///   (two item types sharing one ID is a corpus integrity violation and
  ///   must be rejected, never silently merged).
  /// - Order-independent: merge(a, b) == merge(b, a) always.
  /// - Idempotent: merge(a, a) == a.
  /// - Evidence counters use max() as a monotonic lower bound. Concurrent
  ///   independent recalls from two devices sharing a base may be
  ///   undercounted by a snapshot merge; exact counting is owned by the
  ///   operation log ([ReviewRecallOperation]). Monotonicity (never losing
  ///   already-observed evidence) IS guaranteed.
  /// - Earliest `introducedAt` and earliest `firstRecallAt` preserved.
  /// - Display fields (`lastExerciseType`, `lastResponseTimeMs`,
  ///   `nextReviewAt`) resolve to the strictly-newer side, with
  ///   deterministic tie-breaks that do not depend on argument order.
  /// - Scheduler-failure transitions are deterministic: any observed
  ///   failure forces the learning state with the earliest safe due date.
  static MemoryItemState merge(MemoryItemState a, MemoryItemState b) {
    if (a.itemId != b.itemId) {
      throw ArgumentError(
        'Cannot merge states with different itemIds: "${a.itemId}" vs "${b.itemId}"',
      );
    }
    if (a.itemType != b.itemType) {
      throw ArgumentError(
        'Cannot merge states with different itemTypes for "${a.itemId}": '
        '"${a.itemType}" vs "${b.itemType}"',
      );
    }
    if (a == b) return a;

    final introducedAt = a.introducedAt.isBefore(b.introducedAt)
        ? a.introducedAt
        : b.introducedAt;

    final DateTime? firstRecallAt =
        (a.firstRecallAt != null && b.firstRecallAt != null)
        ? (a.firstRecallAt!.isBefore(b.firstRecallAt!)
              ? a.firstRecallAt
              : b.firstRecallAt)
        : (a.firstRecallAt ?? b.firstRecallAt);

    // Strict recency first; ties broken deterministically WITHOUT regard
    // to argument order (evidence totals, then stable field order).
    final newer = _newerSide(a, b);
    final MemoryItemState? newerState = newer > 0 ? a : (newer < 0 ? b : null);

    final lastReviewedAt =
        newerState?.lastReviewedAt ?? (a.lastReviewedAt ?? b.lastReviewedAt);
    final lastPresentedAt = _maxDateTime(a.lastPresentedAt, b.lastPresentedAt);

    final lastExerciseType =
        newerState?.lastExerciseType ??
        _tieBreakExerciseType(a.lastExerciseType, b.lastExerciseType);
    final lastResponseTimeMs =
        newerState?.lastResponseTimeMs ??
        _tieBreakResponseTime(a.lastResponseTimeMs, b.lastResponseTimeMs);

    // Monotonic lower bound (see scope note above).
    final successfulRecalls = max(a.successfulRecalls, b.successfulRecalls);
    final failedRecalls = max(a.failedRecalls, b.failedRecalls);
    final typingSuccesses = max(a.typingSuccesses, b.typingSuccesses);
    final lapseCount = max(a.lapseCount, b.lapseCount);

    final ease = min(
      a.ease,
      b.ease,
    ).clamp(MemoryScheduler.minEase, MemoryScheduler.maxEase);

    // Deterministic failure signal: ANY observed failure keeps the item in
    // learning with the earliest safe due date (order-independent — no
    // dependence on which side was "newer").
    final observedFailure =
        failedRecalls > 0 &&
        (a.masteryState == MasteryState.learning ||
            b.masteryState == MasteryState.learning ||
            _failureIsLatest(a, b));

    final double intervalDays;
    final DateTime nextReviewAt;
    if (failedRecalls > 0) {
      // Safety first: earliest due date wins whenever failures were observed.
      intervalDays = min(a.intervalDays, b.intervalDays);
      nextReviewAt = a.nextReviewAt.isBefore(b.nextReviewAt)
          ? a.nextReviewAt
          : b.nextReviewAt;
    } else {
      intervalDays = max(a.intervalDays, b.intervalDays);
      nextReviewAt =
          newerState?.nextReviewAt ??
          (a.nextReviewAt.isBefore(b.nextReviewAt)
              ? a.nextReviewAt
              : b.nextReviewAt);
    }

    MasteryState mastery;
    if (observedFailure) {
      mastery = MasteryState.learning;
    } else {
      if (successfulRecalls >= MemoryScheduler.successesForMastered &&
          intervalDays >= MemoryScheduler.intervalForMasteredDays &&
          successfulRecalls > failedRecalls) {
        mastery = MasteryState.mastered;
      } else if (successfulRecalls >= MemoryScheduler.successesForReview) {
        final maxMastery = a.masteryState.index >= b.masteryState.index
            ? a.masteryState
            : b.masteryState;
        mastery = maxMastery.index < MasteryState.review.index
            ? MasteryState.review
            : maxMastery;
      } else {
        // Preserve the highest non-failure state deterministically.
        mastery = a.masteryState.index >= b.masteryState.index
            ? a.masteryState
            : b.masteryState;
      }
    }

    return MemoryItemState(
      itemId: a.itemId,
      itemType: a.itemType,
      introducedAt: introducedAt,
      lastPresentedAt: lastPresentedAt,
      lastReviewedAt: lastReviewedAt,
      nextReviewAt: nextReviewAt,
      intervalDays: intervalDays,
      ease: ease,
      successfulRecalls: successfulRecalls,
      failedRecalls: failedRecalls,
      lapseCount: lapseCount,
      masteryState: mastery,
      lastResponseTimeMs: lastResponseTimeMs,
      lastExerciseType: lastExerciseType,
      typingSuccesses: typingSuccesses,
      firstRecallAt: firstRecallAt,
    );
  }

  /// Returns 1 if [a] is strictly newer, -1 if [b] is strictly newer,
  /// 0 on tie. Tie-breaks use total evidence then stable value ordering —
  /// never argument position.
  static int _newerSide(MemoryItemState a, MemoryItemState b) {
    final aLast = a.lastReviewedAt;
    final bLast = b.lastReviewedAt;
    if (aLast != null && bLast != null) {
      if (aLast.isAfter(bLast)) return 1;
      if (bLast.isAfter(aLast)) return -1;
    } else if (aLast != null) {
      return 1;
    } else if (bLast != null) {
      return -1;
    }
    // Timestamp tie (or both never reviewed): more total evidence wins.
    final aEvidence = a.successfulRecalls + a.failedRecalls;
    final bEvidence = b.successfulRecalls + b.failedRecalls;
    if (aEvidence != bEvidence) return aEvidence > bEvidence ? 1 : -1;
    // Still tied: stable ordering on nextReviewAt (earliest = safer).
    if (a.nextReviewAt.isBefore(b.nextReviewAt)) return 1;
    if (b.nextReviewAt.isBefore(a.nextReviewAt)) return -1;
    return 0;
  }

  static bool _failureIsLatest(MemoryItemState a, MemoryItemState b) {
    // A failure is "latest" only if the strictly-newer side shows MORE
    // failures than the other side. On any tie, no side claims recency.
    final side = _newerSide(a, b);
    if (side > 0) return a.failedRecalls > b.failedRecalls;
    if (side < 0) return b.failedRecalls > a.failedRecalls;
    return false;
  }

  static DateTime? _maxDateTime(DateTime? a, DateTime? b) {
    if (a != null && b != null) {
      return a.isAfter(b) ? a : b;
    }
    return a ?? b;
  }

  /// Deterministic, order-independent choice between exercise types.
  static ReviewExerciseType? _tieBreakExerciseType(
    ReviewExerciseType? a,
    ReviewExerciseType? b,
  ) {
    if (a == null) return b;
    if (b == null) return a;
    if (a == b) return a;
    // Stable canonical order (by enum index), not argument order.
    return a.index <= b.index ? a : b;
  }

  static int? _tieBreakResponseTime(int? a, int? b) {
    if (a == null) return b;
    if (b == null) return a;
    // Deterministic: prefer the smaller (faster) response.
    return a <= b ? a : b;
  }
}
