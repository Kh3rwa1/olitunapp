// Retention metrics — CALCULATED layer.
//
// Three distinct layers, never conflated:
//  1. EVENT COLLECTION — LearningAnalyticsEvents.review_*/item_*/typing_*
//     rows in the `learning_analytics_events` table (source of truth for
//     cohort observation; exported/admin analytics).
//  2. CALCULATED METRICS — this file. Pure functions over the local
//     review states. Deterministic, testable, no I/O, no clock inside.
//  3. OBSERVED COHORT RESULTS — D1/D7/D30 percentages computed from real
//     user event rows (SQL over layer 1) or surfaced from layer 2 per
//     device. Nothing here fabricates a number: every metric is a count
//     or ratio over actual item states, with explicit denominators.
//
// Definitions (honest windows, measured from `firstRecallAt`):
//  - D1 recall: items whose first successful recall happened within 24h
//    of introduction, over the denominator of items introduced ≥24h ago.
//  - D7 recall: same with a 7-day window (denominator: introduced ≥7d ago).
//  - D30 recall: same with a 30-day window.
//  - Mastered-lapsed: MASTERED items whose lapseCount > 0.
//  - Typing participation: items with ≥1 typing success (production reach).

import 'review_item.dart';

class RetentionSnapshot {
  final int introducedCount;
  final int d1EligibleCount;
  final int d1RecalledCount;
  final int d7EligibleCount;
  final int d7RecalledCount;
  final int d30EligibleCount;
  final int d30RecalledCount;
  final int learningCount;
  final int reviewCount;
  final int masteredCount;
  final int masteredLapsedCount;
  final int typingParticipatingCount;

  const RetentionSnapshot({
    required this.introducedCount,
    required this.d1EligibleCount,
    required this.d1RecalledCount,
    required this.d7EligibleCount,
    required this.d7RecalledCount,
    required this.d30EligibleCount,
    required this.d30RecalledCount,
    required this.learningCount,
    required this.reviewCount,
    required this.masteredCount,
    required this.masteredLapsedCount,
    required this.typingParticipatingCount,
  });

  /// Ratios return null when the denominator is 0 — never a fake 0%/100%.
  double? get d1RecallRate =>
      d1EligibleCount == 0 ? null : d1RecalledCount / d1EligibleCount;
  double? get d7RecallRate =>
      d7EligibleCount == 0 ? null : d7RecalledCount / d7EligibleCount;
  double? get d30RecallRate =>
      d30EligibleCount == 0 ? null : d30RecalledCount / d30EligibleCount;
  double? get masteredLapseRate =>
      masteredCount == 0 ? null : masteredLapsedCount / masteredCount;
}

class RetentionMetrics {
  const RetentionMetrics._();

  static RetentionSnapshot compute(
    List<MemoryItemState> items, {
    required DateTime now,
  }) {
    final d1Cutoff = now.subtract(const Duration(hours: 24));
    final d7Cutoff = now.subtract(const Duration(days: 7));
    final d30Cutoff = now.subtract(const Duration(days: 30));

    var d1Eligible = 0, d1Recalled = 0;
    var d7Eligible = 0, d7Recalled = 0;
    var d30Eligible = 0, d30Recalled = 0;
    var learning = 0, review = 0, mastered = 0, masteredLapsed = 0;
    var typingParticipating = 0;

    for (final item in items) {
      if (item.itemId.isEmpty) continue;
      switch (item.masteryState) {
        case MasteryState.fresh:
          break;
        case MasteryState.learning:
          learning++;
        case MasteryState.review:
          review++;
        case MasteryState.mastered:
          mastered++;
          if (item.lapseCount > 0) masteredLapsed++;
      }
      if (item.typingSuccesses > 0) typingParticipating++;

      final firstRecall = item.firstRecallAt;
      if (firstRecall == null) continue;
      final lag = firstRecall.difference(item.introducedAt);
      if (!item.introducedAt.isAfter(d1Cutoff)) {
        d1Eligible++;
        if (lag <= const Duration(hours: 24)) d1Recalled++;
      }
      if (!item.introducedAt.isAfter(d7Cutoff)) {
        d7Eligible++;
        if (lag <= const Duration(days: 7)) d7Recalled++;
      }
      if (!item.introducedAt.isAfter(d30Cutoff)) {
        d30Eligible++;
        if (lag <= const Duration(days: 30)) d30Recalled++;
      }
    }

    return RetentionSnapshot(
      introducedCount: items.where((i) => i.itemId.isNotEmpty).length,
      d1EligibleCount: d1Eligible,
      d1RecalledCount: d1Recalled,
      d7EligibleCount: d7Eligible,
      d7RecalledCount: d7Recalled,
      d30EligibleCount: d30Eligible,
      d30RecalledCount: d30Recalled,
      learningCount: learning,
      reviewCount: review,
      masteredCount: mastered,
      masteredLapsedCount: masteredLapsed,
      typingParticipatingCount: typingParticipating,
    );
  }
}
