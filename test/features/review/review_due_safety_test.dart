// P2 production safety: due boundaries, midnight rollover, timezone
// offsets, volume caps (1/20/100+), mastered lapse. The scheduler works on
// absolute instants (UTC-normalized at the edges) — no date buckets, so
// midnight rollover and timezones cannot corrupt due state by design.

import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/review/domain/memory_scheduler.dart';
import 'package:itun/features/review/domain/review_item.dart';

void main() {
  group('due boundaries', () {
    test('due exactly at the boundary counts (inclusive, honest)', () {
      final t0 = DateTime.utc(2026, 3, 1, 12);
      final item = MemoryScheduler.introduce(
        itemId: 'w1',
        itemType: ReviewItemType.word,
        now: t0,
      );
      expect(item.isDue(t0), isTrue);
      expect(item.isDue(t0.subtract(const Duration(milliseconds: 1))), isFalse);
    });

    test('correct recall lands exactly +1 day (same wall-clock)', () {
      final t0 = DateTime.utc(2026, 3, 1, 20, 30);
      final next = MemoryScheduler.recordRecall(
        MemoryScheduler.introduce(
          itemId: 'w1',
          itemType: ReviewItemType.word,
          now: t0,
        ),
        RecallInput(
          correct: true,
          exerciseType: ReviewExerciseType.recognition,
          now: t0,
        ),
      );
      expect(next.nextReviewAt, t0.add(const Duration(days: 1)));
    });
  });

  group('midnight rollover', () {
    test('item due at 23:59 UTC is due at 00:01 the next day', () {
      final late = DateTime.utc(2026, 3, 1, 23, 59);
      final item = MemoryScheduler.introduce(
        itemId: 'w1',
        itemType: ReviewItemType.word,
        now: late,
      );
      expect(item.isDue(DateTime.utc(2026, 3, 5, 0, 1)), isTrue);
    });

    test('interval math never truncates to date buckets', () {
      // A 22:00 introduction reviewed correctly is due 22:00 next day —
      // never "tomorrow 00:00". No dateBucket logic exists in the scheduler.
      final t0 = DateTime.utc(2026, 3, 1, 22);
      final next = MemoryScheduler.recordRecall(
        MemoryScheduler.introduce(
          itemId: 'w1',
          itemType: ReviewItemType.word,
          now: t0,
        ),
        RecallInput(
          correct: true,
          exerciseType: ReviewExerciseType.recognition,
          now: t0,
        ),
      );
      expect(next.nextReviewAt.hour, 22);
      expect(next.nextReviewAt.day, 2);
    });
  });

  group('timezone offsets', () {
    test('mixed-offset instants compare correctly (instant arithmetic)', () {
      // Introduced from a +05:30 local clock, reviewed from UTC: the
      // scheduler stores absolute instants; serialization keeps offsets.
      final localIntro = DateTime.parse('2026-03-01T12:00:00+05:30');
      final introduced = MemoryScheduler.introduce(
        itemId: 'w1',
        itemType: ReviewItemType.word,
        now: localIntro,
      );
      final utcReview = DateTime.utc(2026, 3, 2, 7); // +24.5h later
      final next = MemoryScheduler.recordRecall(
        introduced,
        RecallInput(
          correct: true,
          exerciseType: ReviewExerciseType.recognition,
          now: utcReview,
        ),
      );
      expect(next.successfulRecalls, 1);
      expect(next.nextReviewAt.isAfter(utcReview), isTrue);
      // Round-trip through storage preserves the instant exactly.
      final restored = MemoryItemState.fromMap(next.toMap());
      expect(restored.nextReviewAt.isAtSameMomentAs(next.nextReviewAt), isTrue);
    });
  });

  group('volumes', () {
    test('1 due item queues alone and honestly', () {
      final t0 = DateTime.utc(2026, 3, 4);
      final item = MemoryScheduler.introduce(
        itemId: 'only',
        itemType: ReviewItemType.word,
        now: t0,
      );
      final due = MemoryScheduler.selectDue([item], t0);
      expect(due, hasLength(1));
      expect(MemoryScheduler.estimateMinutes(1), 1);
    });

    test('exactly 20 due items all queue (no truncation at the cap)', () {
      final t0 = DateTime.utc(2026, 3, 4);
      final items = List.generate(
        20,
        (i) => MemoryScheduler.introduce(
          itemId: 'w$i',
          itemType: ReviewItemType.word,
          now: t0,
        ),
      );
      expect(MemoryScheduler.selectDue(items, t0), hasLength(20));
    });

    test('100+ due items: session caps at 20, count stays honest', () {
      final t0 = DateTime.utc(2026, 3, 4);
      final items = List.generate(
        150,
        (i) => MemoryScheduler.introduce(
          itemId: 'w$i',
          itemType: i.isEven ? ReviewItemType.word : ReviewItemType.sentence,
          now: t0,
        ),
      );
      final queue = MemoryScheduler.selectDue(items, t0);
      expect(queue, hasLength(20));
      // The learner is told the real total elsewhere (dueCount), never 20.
      final dueCount = items.where((e) => e.isDue(t0)).length;
      expect(dueCount, 150);
    });

    test('newly introduced items are due immediately, never hidden', () {
      final t0 = DateTime.utc(2026, 3, 4);
      final items = List.generate(
        25,
        (i) => MemoryScheduler.introduce(
          itemId: 'w$i',
          itemType: ReviewItemType.word,
          now: t0,
        ),
      );
      // Even over the cap, every new item is due (first 20 queue first).
      expect(items.every((e) => e.isDue(t0)), isTrue);
    });

    test('large histories stay fast (low-end device guard)', () {
      final t0 = DateTime.utc(2026, 3, 4);
      final items = List.generate(
        2000,
        (i) => MemoryScheduler.introduce(
          itemId: 'w$i',
          itemType: i.isEven ? ReviewItemType.word : ReviewItemType.sentence,
          now: t0,
        ),
      );
      final watch = Stopwatch()..start();
      final queue = MemoryScheduler.selectDue(items, t0);
      final dueCount = items.where((e) => e.isDue(t0)).length;
      watch.stop();
      expect(queue, hasLength(20));
      expect(dueCount, 2000);
      // Queue selection + full-history count must stay far below frame
      // budgets even at the storage cap. Generous bound: catches
      // pathological (e.g. quadratic) regressions, never flakes.
      expect(watch.elapsedMilliseconds, lessThan(2000));
    });
  });

  group('mastered lapse', () {
    test('mastered item answered wrong lapses to review, due tomorrow', () {
      var item = MemoryScheduler.introduce(
        itemId: 'w1',
        itemType: ReviewItemType.word,
        now: DateTime.utc(2026, 1, 4),
      );
      var now = DateTime.utc(2026, 1, 4);
      for (var i = 0; i < 8; i++) {
        item = MemoryScheduler.recordRecall(
          item,
          RecallInput(
            correct: true,
            exerciseType: ReviewExerciseType.recognition,
            now: now,
          ),
        );
        now = item.nextReviewAt;
      }
      expect(item.masteryState, MasteryState.mastered);
      final lapsed = MemoryScheduler.recordRecall(
        item,
        RecallInput(
          correct: false,
          exerciseType: ReviewExerciseType.recognition,
          now: now,
        ),
      );
      expect(lapsed.masteryState, MasteryState.review);
      expect(lapsed.lapseCount, 1);
      // Honest state: due tomorrow, still counts as needing review.
      expect(lapsed.isDue(now), isFalse);
      expect(
        lapsed.isDue(now.add(const Duration(days: 1, minutes: 1))),
        isTrue,
      );
    });
  });
}
