import 'dart:math';

import 'memory_scheduler.dart';
import 'review_item.dart';

class ReviewStateMergePolicy {
  const ReviewStateMergePolicy._();

  /// Deterministically merges two memory states for the same item.
  ///
  /// Properties:
  /// - Idempotent: `merge(a, a) == a`
  /// - Commutative: `merge(a, b) == merge(b, a)`
  /// - Associative: `merge(merge(a, b), c) == merge(a, merge(b, c))`
  ///
  /// Preserves all learning evidence:
  /// - Successful recalls: max(a, b)
  /// - Failed recalls: max(a, b)
  /// - Typing successes: max(a, b)
  /// - Lapses: max(a, b)
  /// - Earliest `introducedAt` and earliest `firstRecallAt`
  /// - Latest `lastReviewedAt`, `lastPresentedAt`, `lastExerciseType`
  /// - Next review schedule prioritized by safety (earliest due date if failures occurred)
  /// - Deterministic SM-2 mastery transition evaluation
  static MemoryItemState merge(MemoryItemState a, MemoryItemState b) {
    if (a == b) return a;
    if (a.itemId != b.itemId) {
      throw ArgumentError(
        'Cannot merge states with different itemIds: "${a.itemId}" vs "${b.itemId}"',
      );
    }

    final introducedAt = a.introducedAt.isBefore(b.introducedAt)
        ? a.introducedAt
        : b.introducedAt;

    final DateTime? firstRecallAt =
        (a.firstRecallAt != null && b.firstRecallAt != null)
            ? (a.firstRecallAt!.isBefore(b.firstRecallAt!)
                ? a.firstRecallAt
                : b.firstRecallAt)
            : (a.firstRecallAt ?? b.firstRecallAt);

    final aLast = a.lastReviewedAt;
    final bLast = b.lastReviewedAt;
    final bool bIsNewer = (aLast == null && bLast != null) ||
        (aLast != null && bLast != null && bLast.isAfter(aLast));
    final bool aIsNewer = (bLast == null && aLast != null) ||
        (aLast != null && bLast != null && aLast.isAfter(bLast));

    final lastReviewedAt = bIsNewer ? bLast : (aIsNewer ? aLast : aLast);
    final lastPresentedAt =
        (a.lastPresentedAt != null && b.lastPresentedAt != null)
            ? (a.lastPresentedAt!.isAfter(b.lastPresentedAt!)
                ? a.lastPresentedAt
                : b.lastPresentedAt)
            : (a.lastPresentedAt ?? b.lastPresentedAt);

    final lastExerciseType = bIsNewer
        ? (b.lastExerciseType ?? a.lastExerciseType)
        : (a.lastExerciseType ?? b.lastExerciseType);
    final lastResponseTimeMs = bIsNewer
        ? (b.lastResponseTimeMs ?? a.lastResponseTimeMs)
        : (a.lastResponseTimeMs ?? b.lastResponseTimeMs);

    final successfulRecalls = max(a.successfulRecalls, b.successfulRecalls);
    final failedRecalls = max(a.failedRecalls, b.failedRecalls);
    final typingSuccesses = max(a.typingSuccesses, b.typingSuccesses);
    final lapseCount = max(a.lapseCount, b.lapseCount);

    final ease = min(a.ease, b.ease).clamp(
      MemoryScheduler.minEase,
      MemoryScheduler.maxEase,
    );

    final latestWasFailure = bIsNewer
        ? (b.failedRecalls > a.failedRecalls)
        : (aIsNewer ? (a.failedRecalls > b.failedRecalls) : false);

    final double intervalDays;
    final DateTime nextReviewAt;

    if (latestWasFailure) {
      intervalDays = bIsNewer ? b.intervalDays : a.intervalDays;
      nextReviewAt = a.nextReviewAt.isBefore(b.nextReviewAt)
          ? a.nextReviewAt
          : b.nextReviewAt;
    } else {
      intervalDays = max(a.intervalDays, b.intervalDays);
      nextReviewAt = (failedRecalls > 0)
          ? (a.nextReviewAt.isBefore(b.nextReviewAt)
              ? a.nextReviewAt
              : b.nextReviewAt)
          : (bIsNewer ? b.nextReviewAt : a.nextReviewAt);
    }

    final MasteryState mastery;
    if (latestWasFailure) {
      mastery = MasteryState.learning;
    } else {
      final maxMastery = a.masteryState.index >= b.masteryState.index
          ? a.masteryState
          : b.masteryState;
      if (successfulRecalls >= MemoryScheduler.successesForMastered &&
          intervalDays >= MemoryScheduler.intervalForMasteredDays &&
          successfulRecalls > failedRecalls) {
        mastery = MasteryState.mastered;
      } else if (successfulRecalls >= MemoryScheduler.successesForReview) {
        mastery = maxMastery.index > MasteryState.review.index
            ? maxMastery
            : MasteryState.review;
      } else {
        mastery = maxMastery;
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
}
