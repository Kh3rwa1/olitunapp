// Deterministic spaced-repetition scheduler (domain layer, no UI).
//
// Design: simple, reliable SM-2-lite. Tunable later from real user data.
// All methods are pure and take `now` explicitly so tests are deterministic.
// Units: intervals stored in days (fractional allowed); short re-study
// delays use minutes converted to days.
//
// Rules (product spec Phase 1):
// - New item -> introduce (due immediately, LEARNING on first presentation)
// - Correct recall -> increase interval (typing grows faster = stronger evidence)
// - Wrong recall -> shorten interval, bring back sooner
// - Repeated failure -> back to LEARNING, lapse++
// - Consistent success -> interval grows, REVIEW then MASTERED
// - MASTERED requires repeated successful retrieval over time, never once.

import 'review_item.dart';

class RecallInput {
  final bool correct;
  final ReviewExerciseType exerciseType;
  final int? responseTimeMs;
  final DateTime now;

  const RecallInput({
    required this.correct,
    required this.exerciseType,
    required this.now,
    this.responseTimeMs,
  });
}

class MemoryScheduler {
  static const double initialEase = 2.5;
  static const double minEase = 1.3;
  static const double maxEase = 2.8;

  /// Correct-recognition intervals for the first two recalls (days).
  static const double firstIntervalDays = 1;
  static const double secondIntervalDays = 3;

  /// Wrong-answer re-study delays.
  static const Duration learningRetryDelay = Duration(minutes: 10);
  static const Duration reviewRetryDelay = Duration(days: 1);

  /// Mastery bar: repeated retrieval over time, with real production proof.
  /// Typing success counts double toward [successfulRecalls] (see
  /// [recordRecall]), so a typing-heavy learner masters faster — by design.
  static const int successesForReview = 2;
  static const int successesForMastered = 6;
  static const double intervalForMasteredDays = 14;

  /// Introduce a never-seen item. Due immediately.
  static MemoryItemState introduce({
    required String itemId,
    required ReviewItemType itemType,
    required DateTime now,
  }) {
    return MemoryItemState(
      itemId: itemId,
      itemType: itemType,
      introducedAt: now,
      nextReviewAt: now,
    );
  }

  /// Record one retrieval attempt. Returns the rescheduled state.
  static MemoryItemState recordRecall(MemoryItemState item, RecallInput input) {
    final now = input.now;
    final isTyping = input.exerciseType.isProduction;

    if (input.correct) {
      return _recordCorrect(item, input, now, isTyping);
    }
    return _recordWrong(item, input, now);
  }

  static MemoryItemState _recordCorrect(
    MemoryItemState item,
    RecallInput input,
    DateTime now,
    bool isTyping,
  ) {
    // Typing is stronger evidence: counts double + grows ease faster.
    final successIncrement = isTyping ? 2 : 1;
    final successes = item.successfulRecalls + successIncrement;
    final typingSuccesses = item.typingSuccesses + (isTyping ? 1 : 0);

    // Ease: reward correct, slightly more for production. Slow answers
    // (>15s) earn less — hesitation is weak memory.
    var ease = item.ease + (isTyping ? 0.12 : 0.08);
    final slow = input.responseTimeMs != null && input.responseTimeMs! > 15000;
    if (slow) ease -= 0.05;
    ease = ease.clamp(minEase, maxEase);

    // Interval ladder.
    double interval;
    if (item.successfulRecalls == 0 && item.intervalDays <= 0) {
      interval = firstIntervalDays;
    } else if (successes <= 3 && item.intervalDays < secondIntervalDays) {
      interval = secondIntervalDays;
    } else {
      final base = item.intervalDays <= 0
          ? secondIntervalDays
          : item.intervalDays;
      interval = base * ease;
      // Typing stretches further (stronger trace).
      if (isTyping) interval *= 1.15;
      interval = interval.clamp(1, 180);
    }

    final mastery = _promote(item.masteryState, successes, interval);

    return item.copyWith(
      lastPresentedAt: now,
      lastReviewedAt: now,
      nextReviewAt: now.add(
        Duration(
          milliseconds: (interval * Duration.millisecondsPerDay).round(),
        ),
      ),
      intervalDays: interval,
      ease: ease,
      successfulRecalls: successes,
      masteryState: mastery,
      lastResponseTimeMs: input.responseTimeMs,
      lastExerciseType: input.exerciseType,
      typingSuccesses: typingSuccesses,
      // Stamp once, on the first-ever successful recall: D1/D7/D30 recall
      // windows are measured from this, never approximated.
      firstRecallAt: item.firstRecallAt ?? now,
    );
  }

  static MemoryItemState _recordWrong(
    MemoryItemState item,
    RecallInput input,
    DateTime now,
  ) {
    final failed = item.failedRecalls + 1;
    final ease = (item.ease - 0.2).clamp(minEase, maxEase);

    final wasLearning =
        item.masteryState == MasteryState.fresh ||
        item.masteryState == MasteryState.learning;
    // Learning items come back within the same day; review/mastered
    // items come back tomorrow with the interval reset.
    final delay = wasLearning ? learningRetryDelay : reviewRetryDelay;
    final interval = wasLearning ? item.intervalDays : 1.0;

    // Demotion is graduated, never punitive:
    // - a single lapse from MASTERED drops one level to REVIEW (still known,
    //   just needs a refresh) with lapse++.
    // - REVIEW lapses stay in REVIEW unless failure is repeated
    //   (3+ more fails than successes), which drops to LEARNING.
    // - FRESH/LEARNING wrong answers settle into LEARNING.
    final wasMastered = item.masteryState == MasteryState.mastered;
    final wasReview = item.masteryState == MasteryState.review;
    final lapsing = wasMastered || wasReview;
    final shouldDropToLearning =
        ((!wasMastered && !wasReview) ||
        (wasReview && failed - item.successfulRecalls >= 3));
    final mastery = wasMastered
        ? MasteryState.review
        : shouldDropToLearning
        ? MasteryState.learning
        : item.masteryState;

    return item.copyWith(
      lastPresentedAt: now,
      lastReviewedAt: now,
      nextReviewAt: now.add(delay),
      intervalDays: interval,
      ease: ease,
      failedRecalls: failed,
      lapseCount: lapsing ? item.lapseCount + 1 : item.lapseCount,
      masteryState: mastery,
      lastResponseTimeMs: input.responseTimeMs,
      lastExerciseType: input.exerciseType,
    );
  }

  static MasteryState _promote(
    MasteryState current,
    int successes,
    double interval,
  ) {
    if (current == MasteryState.mastered) return MasteryState.mastered;
    if (successes >= successesForMastered &&
        interval >= intervalForMasteredDays) {
      return MasteryState.mastered;
    }
    if (current == MasteryState.fresh || current == MasteryState.learning) {
      if (successes >= successesForReview) return MasteryState.review;
      return MasteryState.learning;
    }
    return current;
  }

  /// Queue selector: due items ordered by need.
  ///
  /// Priority: most overdue first, then most-failed, then hardest (lowest
  /// ease), then oldest introduction. Stable + deterministic for tests.
  /// Duplicate itemIds are collapsed (first occurrence wins).
  static List<MemoryItemState> selectDue(
    Iterable<MemoryItemState> items,
    DateTime now, {
    int limit = 20,
  }) {
    final seen = <String>{};
    final due = <MemoryItemState>[];
    for (final item in items) {
      if (item.itemId.isEmpty) continue;
      if (!seen.add(item.itemId)) continue;
      if (item.isDue(now)) due.add(item);
    }
    due.sort((a, b) {
      final overdueCmp = a.nextReviewAt.compareTo(b.nextReviewAt);
      if (overdueCmp != 0) return overdueCmp;
      final failCmp = b.failedRecalls.compareTo(a.failedRecalls);
      if (failCmp != 0) return failCmp;
      final easeCmp = a.ease.compareTo(b.ease);
      if (easeCmp != 0) return easeCmp;
      return a.introducedAt.compareTo(b.introducedAt);
    });
    if (due.length <= limit) return due;
    return due.sublist(0, limit);
  }

  /// Estimated session minutes for a queue (used by Today's Review card).
  /// ~30s per recognition card, ~60s per typing card; blend at 40s.
  static int estimateMinutes(int cardCount) {
    if (cardCount <= 0) return 0;
    return ((cardCount * 40) / 60).ceil().clamp(1, 120);
  }
}
