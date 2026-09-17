// Explicit guest to account review-state migration policy.
//
// When an unauthenticated guest learns items and then signs in, their accumulated
// memory progress must be safely merged into the authenticated account without
// losing learning evidence (recalls, typing successes, lapses, intervals), while
// guaranteeing zero cross-account leakage on logout and account switching.

import 'dart:math';

import '../domain/memory_scheduler.dart';
import '../domain/review_item.dart';
import 'review_store.dart';

class ReviewStateMigrationResult {
  final int guestItemsCount;
  final int adoptedCount;
  final int mergedCount;

  const ReviewStateMigrationResult({
    required this.guestItemsCount,
    required this.adoptedCount,
    required this.mergedCount,
  });

  int get migratedCount => adoptedCount + mergedCount;
  bool get hasChanges => adoptedCount > 0 || mergedCount > 0;
}

class ReviewStateMigrator {
  const ReviewStateMigrator._();

  /// Migrates guest SRS items into an authenticated user's store.
  ///
  /// Merge Policy:
  /// 1. Guest-only items: adopted into the account store as-is.
  /// 2. Account-only items: left completely untouched.
  /// 3. Overlapping items:
  ///    - Recalls and typing evidence are combined monotonically (no lost learning).
  ///    - Lapses and failures are combined (no forgotten difficulty).
  ///    - Earliest `introducedAt` and earliest `firstRecallAt` are preserved.
  ///    - Latest `lastReviewedAt`, `lastPresentedAt`, `lastExerciseType` are preserved.
  ///    - Mastery is re-evaluated deterministically against SM-2 rules.
  /// 4. Post-migration: `guestStore` is cleared and `accountStore` is durably persisted,
  ///    guaranteeing zero leakage to future guest sessions or subsequent account logins.
  static Future<ReviewStateMigrationResult> migrateGuestToAccount({
    required ReviewStore guestStore,
    required ReviewStore accountStore,
    DateTime? now,
  }) async {
    final guestItems = guestStore.all();
    if (guestItems.isEmpty) {
      return const ReviewStateMigrationResult(
        guestItemsCount: 0,
        adoptedCount: 0,
        mergedCount: 0,
      );
    }

    var adopted = 0;
    var merged = 0;

    for (final guestItem in guestItems) {
      if (guestItem.itemId.isEmpty) continue;

      final accountItem = accountStore.get(guestItem.itemId);
      if (accountItem == null) {
        accountStore.adoptRemote(guestItem);
        adopted++;
      } else {
        final reconciled = _mergeGuestAndAccountItem(guestItem, accountItem);
        accountStore.adoptRemote(reconciled);
        merged++;
      }
    }

    // Durably persist the target account store
    await accountStore.persist();

    // Cleanly wipe the guest store to prevent leakage into other accounts on logout
    await guestStore.clear();

    return ReviewStateMigrationResult(
      guestItemsCount: guestItems.length,
      adoptedCount: adopted,
      mergedCount: merged,
    );
  }

  static MemoryItemState _mergeGuestAndAccountItem(
    MemoryItemState guest,
    MemoryItemState account,
  ) {
    // Introduction: earliest introduction instant
    final introducedAt = guest.introducedAt.isBefore(account.introducedAt)
        ? guest.introducedAt
        : account.introducedAt;

    // Earliest first successful recall
    final DateTime? firstRecallAt =
        (guest.firstRecallAt != null && account.firstRecallAt != null)
            ? (guest.firstRecallAt!.isBefore(account.firstRecallAt!)
                ? guest.firstRecallAt
                : account.firstRecallAt)
            : (guest.firstRecallAt ?? account.firstRecallAt);

    // Latest review timestamps
    final gLast = guest.lastReviewedAt;
    final aLast = account.lastReviewedAt;
    final bool guestIsNewer = (aLast == null && gLast != null) ||
        (gLast != null && aLast != null && gLast.isAfter(aLast));

    final lastReviewedAt = guestIsNewer ? gLast : (aLast ?? gLast);
    final lastPresentedAt =
        (guest.lastPresentedAt != null && account.lastPresentedAt != null)
            ? (guest.lastPresentedAt!.isAfter(account.lastPresentedAt!)
                ? guest.lastPresentedAt
                : account.lastPresentedAt)
            : (guest.lastPresentedAt ?? account.lastPresentedAt);

    final lastExerciseType = guestIsNewer
        ? (guest.lastExerciseType ?? account.lastExerciseType)
        : (account.lastExerciseType ?? guest.lastExerciseType);
    final lastResponseTimeMs = guestIsNewer
        ? (guest.lastResponseTimeMs ?? account.lastResponseTimeMs)
        : (account.lastResponseTimeMs ?? guest.lastResponseTimeMs);

    // Combine recall evidence so no practice is lost
    final successfulRecalls =
        account.successfulRecalls + guest.successfulRecalls;
    final failedRecalls = account.failedRecalls + guest.failedRecalls;
    final typingSuccesses = account.typingSuccesses + guest.typingSuccesses;
    final lapseCount = account.lapseCount + guest.lapseCount;

    // Ease reflects latest study difficulty clamped to SM-2 bounds
    final ease = (guestIsNewer ? guest.ease : account.ease).clamp(
      MemoryScheduler.minEase,
      MemoryScheduler.maxEase,
    );

    // Interval and next review
    final intervalDays = max(account.intervalDays, guest.intervalDays);
    DateTime nextReviewAt = guestIsNewer ? guest.nextReviewAt : account.nextReviewAt;
    // If either side had a failure requiring quick re-study, take the earlier due instant
    if (guest.failedRecalls > 0 || account.failedRecalls > 0) {
      if (guest.nextReviewAt.isBefore(account.nextReviewAt)) {
        nextReviewAt = guest.nextReviewAt;
      } else {
        nextReviewAt = account.nextReviewAt;
      }
    }

    // Deterministic mastery state promotion based on combined evidence
    MasteryState mastery;
    if (successfulRecalls >= MemoryScheduler.successesForMastered &&
        intervalDays >= MemoryScheduler.intervalForMasteredDays &&
        successfulRecalls > failedRecalls) {
      mastery = MasteryState.mastered;
    } else if (successfulRecalls >= MemoryScheduler.successesForReview) {
      mastery = MasteryState.review;
    } else if (successfulRecalls > 0 || failedRecalls > 0) {
      mastery = MasteryState.learning;
    } else {
      mastery = MasteryState.fresh;
    }

    return MemoryItemState(
      itemId: account.itemId,
      itemType: account.itemType,
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
