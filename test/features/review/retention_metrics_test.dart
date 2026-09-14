// Retention metrics: calculated layer over review states. Denominators are
// explicit; rates return null (never a fake 0%/100%) when nothing qualifies.

import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/review/domain/memory_scheduler.dart';
import 'package:itun/features/review/domain/retention_metrics.dart';
import 'package:itun/features/review/domain/review_item.dart';

void main() {
  final now = DateTime.utc(2026, 2, 1, 9);

  group('RetentionMetrics.compute', () {
    test('empty store yields all-zero counts and null rates', () {
      final snap = RetentionMetrics.compute(const [], now: now);
      expect(snap.introducedCount, 0);
      expect(snap.d1RecallRate, isNull);
      expect(snap.d7RecallRate, isNull);
      expect(snap.d30RecallRate, isNull);
      expect(snap.masteredLapseRate, isNull);
    });

    test('D1 recall counts first-success-within-24h, excludes later', () {
      // Introduced 3 days ago, recalled same day -> D1 hit.
      final quick =
          MemoryScheduler.introduce(
            itemId: 'quick',
            itemType: ReviewItemType.word,
            now: now.subtract(const Duration(days: 3)),
          ).copyWith(
            firstRecallAt: now.subtract(const Duration(days: 3, hours: -2)),
          );
      // Introduced 3 days ago, first recall 2 days later -> D1 miss.
      final slow = MemoryScheduler.introduce(
        itemId: 'slow',
        itemType: ReviewItemType.word,
        now: now.subtract(const Duration(days: 3)),
      ).copyWith(firstRecallAt: now.subtract(const Duration(days: 1)));
      // Introduced 2 hours ago: not yet D1-eligible (denominator excludes).
      final tooNew = MemoryScheduler.introduce(
        itemId: 'new',
        itemType: ReviewItemType.word,
        now: now.subtract(const Duration(hours: 2)),
      );

      final snap = RetentionMetrics.compute([quick, slow, tooNew], now: now);
      expect(snap.d1EligibleCount, 2);
      expect(snap.d1RecalledCount, 1);
      expect(snap.d1RecallRate, closeTo(0.5, 0.001));
    });

    test('D7/D30 windows widen denominators and hits', () {
      // Introduced 10 days ago, first recall at day 5: misses D1, hits D7.
      // NOT D30-eligible yet — the item hasn't existed for 30 days, so the
      // denominator correctly excludes it (no fabricated 0% cohort).
      final item = MemoryScheduler.introduce(
        itemId: 'w1',
        itemType: ReviewItemType.word,
        now: now.subtract(const Duration(days: 10)),
      ).copyWith(firstRecallAt: now.subtract(const Duration(days: 5)));
      final snap = RetentionMetrics.compute([item], now: now);
      expect(snap.d1EligibleCount, 1);
      expect(snap.d1RecalledCount, 0); // recall at day 5 misses D1
      expect(snap.d7RecalledCount, 1); // hits D7
      expect(snap.d30EligibleCount, 0);
      expect(snap.d30RecalledCount, 0);

      // A genuinely old item (introduced 35 days ago, first recall 15 days
      // after introduction): D1 miss, D7 miss, D30 hit — clean separation.
      final old = MemoryScheduler.introduce(
        itemId: 'w2',
        itemType: ReviewItemType.word,
        now: now.subtract(const Duration(days: 35)),
      ).copyWith(firstRecallAt: now.subtract(const Duration(days: 20)));
      final oldSnap = RetentionMetrics.compute([old], now: now);
      expect(oldSnap.d1RecalledCount, 0);
      expect(oldSnap.d7RecalledCount, 0);
      expect(oldSnap.d30RecalledCount, 1);
      expect(oldSnap.d30RecallRate, 1.0);
    });

    test('mastery/lapse/typing participation reflect real states', () {
      final learning = MemoryScheduler.introduce(
        itemId: 'l',
        itemType: ReviewItemType.word,
        now: now,
      ).copyWith(masteryState: MasteryState.learning);
      final review = MemoryScheduler.introduce(
        itemId: 'r',
        itemType: ReviewItemType.word,
        now: now,
      ).copyWith(masteryState: MasteryState.review);
      final lapsedMastered = MemoryScheduler.introduce(
        itemId: 'm',
        itemType: ReviewItemType.word,
        now: now,
      ).copyWith(masteryState: MasteryState.mastered, lapseCount: 2);
      final typist = MemoryScheduler.introduce(
        itemId: 't',
        itemType: ReviewItemType.word,
        now: now,
      ).copyWith(typingSuccesses: 3, masteryState: MasteryState.review);

      final snap = RetentionMetrics.compute([
        learning,
        review,
        lapsedMastered,
        typist,
      ], now: now);
      expect(snap.learningCount, 1);
      expect(snap.reviewCount, 2);
      expect(snap.masteredCount, 1);
      expect(snap.masteredLapsedCount, 1);
      expect(snap.masteredLapseRate, 1.0);
      expect(snap.typingParticipatingCount, 1);
    });

    test('firstRecallAt survives serialization round-trip', () {
      final item = MemoryScheduler.recordRecall(
        MemoryScheduler.introduce(
          itemId: 'w9',
          itemType: ReviewItemType.word,
          now: now,
        ),
        RecallInput(
          correct: true,
          exerciseType: ReviewExerciseType.recognition,
          now: now,
        ),
      );
      expect(item.firstRecallAt, isNotNull);
      final restored = MemoryItemState.fromMap(item.toMap());
      expect(restored.firstRecallAt, item.firstRecallAt);
    });
  });
}
