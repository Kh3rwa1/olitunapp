// Scheduler unit tests: deterministic (explicit `now`), no Flutter, no I/O.
// Covers the full acceptance matrix: new / first correct / first wrong /
// repeated failure / repeated success / mastered / overdue / multi-due /
// duplicate prevention / typing weight / slow-answer penalty.

import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/review/domain/memory_scheduler.dart';
import 'package:itun/features/review/domain/review_item.dart';

void main() {
  final t0 = DateTime.utc(2026, 1, 1, 9);

  MemoryItemState freshItem([String id = 'w1']) => MemoryScheduler.introduce(
    itemId: id,
    itemType: ReviewItemType.word,
    now: t0,
  );

  RecallInput correct(
    DateTime now, {
    ReviewExerciseType type = ReviewExerciseType.recognition,
    int? responseMs,
  }) => RecallInput(
    correct: true,
    exerciseType: type,
    now: now,
    responseTimeMs: responseMs,
  );

  RecallInput wrong(
    DateTime now, {
    ReviewExerciseType type = ReviewExerciseType.recognition,
  }) => RecallInput(correct: false, exerciseType: type, now: now);

  group('introduce', () {
    test('new item is fresh, due immediately, with default ease', () {
      final item = freshItem();
      expect(item.masteryState, MasteryState.fresh);
      expect(item.isDue(t0), isTrue);
      expect(item.nextReviewAt, t0);
      expect(item.intervalDays, 0);
      expect(item.ease, MemoryScheduler.initialEase);
      expect(item.successfulRecalls, 0);
      expect(item.failedRecalls, 0);
    });
  });

  group('first recall', () {
    test('first correct recall schedules +1 day, stays learning', () {
      final next = MemoryScheduler.recordRecall(freshItem(), correct(t0));
      expect(next.successfulRecalls, 1);
      expect(next.intervalDays, MemoryScheduler.firstIntervalDays);
      expect(next.nextReviewAt, t0.add(const Duration(days: 1)));
      expect(next.masteryState, MasteryState.learning);
      expect(next.isDue(t0), isFalse);
      expect(next.lastExerciseType, ReviewExerciseType.recognition);
    });

    test('first incorrect recall shortens interval and returns in minutes', () {
      final next = MemoryScheduler.recordRecall(freshItem(), wrong(t0));
      expect(next.failedRecalls, 1);
      expect(next.successfulRecalls, 0);
      expect(next.ease, lessThan(MemoryScheduler.initialEase));
      expect(next.nextReviewAt, t0.add(MemoryScheduler.learningRetryDelay));
      expect(next.masteryState, MasteryState.learning);
      expect(next.isDue(t0.add(const Duration(minutes: 11))), isTrue);
    });
  });

  group('repeated failure', () {
    test('keeps bringing the item back sooner with falling ease', () {
      var item = freshItem();
      var now = t0;
      for (var i = 0; i < 6; i++) {
        item = MemoryScheduler.recordRecall(item, wrong(now));
        now = item.nextReviewAt;
      }
      expect(item.failedRecalls, 6);
      expect(item.masteryState, MasteryState.learning);
      expect(item.ease, MemoryScheduler.minEase);
      // Still due within about an hour total, never pushed far out.
      expect(
        item.nextReviewAt.difference(t0),
        lessThan(const Duration(hours: 2)),
      );
    });

    test('lapsed review item returns tomorrow with interval reset', () {
      var item = freshItem();
      // Two successes -> review.
      item = MemoryScheduler.recordRecall(item, correct(t0));
      item = MemoryScheduler.recordRecall(
        item,
        correct(t0.add(const Duration(days: 1))),
      );
      expect(item.masteryState, MasteryState.review);
      final failAt = item.nextReviewAt;
      final lapsed = MemoryScheduler.recordRecall(item, wrong(failAt));
      // A single lapse refreshes (stays REVIEW); only repeated failure
      // drops back to LEARNING.
      expect(lapsed.masteryState, MasteryState.review);
      expect(lapsed.lapseCount, 1);
      expect(lapsed.nextReviewAt, failAt.add(MemoryScheduler.reviewRetryDelay));
      expect(lapsed.intervalDays, 1.0);
    });

    test('repeatedly failed review item drops back to learning', () {
      var item = freshItem();
      item = MemoryScheduler.recordRecall(item, correct(t0));
      item = MemoryScheduler.recordRecall(
        item,
        correct(t0.add(const Duration(days: 1))),
      );
      expect(item.masteryState, MasteryState.review);
      var now = item.nextReviewAt;
      // 2 successes banked: needs 5 fails (5-2>=3) to drop to LEARNING.
      for (var i = 0; i < 5; i++) {
        item = MemoryScheduler.recordRecall(item, wrong(now));
        now = item.nextReviewAt;
      }
      expect(item.masteryState, MasteryState.learning);
      expect(item.lapseCount, greaterThanOrEqualTo(1));
    });
  });

  group('repeated success and mastery', () {
    test('second success promotes to review', () {
      var item = MemoryScheduler.recordRecall(freshItem(), correct(t0));
      item = MemoryScheduler.recordRecall(
        item,
        correct(t0.add(const Duration(days: 1))),
      );
      expect(item.masteryState, MasteryState.review);
      expect(item.successfulRecalls, 2);
    });

    test('mastery requires repeated retrieval over time, never once', () {
      var item = freshItem();
      var now = t0;
      // Even 5 rapid successes without interval growth must not master:
      // recordRecall always advances nextReviewAt, so simulate real passage.
      for (var i = 0; i < 5; i++) {
        item = MemoryScheduler.recordRecall(item, correct(now));
        expect(
          item.masteryState,
          isNot(MasteryState.mastered),
          reason: 'success ${i + 1} must not master yet',
        );
        now = item.nextReviewAt;
      }
      item = MemoryScheduler.recordRecall(item, correct(now));
      expect(item.masteryState, MasteryState.mastered);
      expect(item.successfulRecalls, greaterThanOrEqualTo(6));
      expect(
        item.intervalDays,
        greaterThanOrEqualTo(MemoryScheduler.intervalForMasteredDays),
      );
    });

    test('mastered item answered wrong demotes to review with lapse', () {
      var item = freshItem();
      var now = t0;
      for (var i = 0; i < 6; i++) {
        item = MemoryScheduler.recordRecall(item, correct(now));
        now = item.nextReviewAt;
      }
      expect(item.masteryState, MasteryState.mastered);
      final lapsed = MemoryScheduler.recordRecall(item, wrong(now));
      expect(lapsed.masteryState, MasteryState.review);
      expect(lapsed.lapseCount, 1);
      expect(lapsed.nextReviewAt, now.add(MemoryScheduler.reviewRetryDelay));
    });

    test('intervals grow monotonically on consistent success', () {
      var item = freshItem();
      var now = t0;
      var prev = 0.0;
      for (var i = 0; i < 4; i++) {
        item = MemoryScheduler.recordRecall(item, correct(now));
        expect(item.intervalDays, greaterThan(prev));
        prev = item.intervalDays;
        now = item.nextReviewAt;
      }
    });
  });

  group('typing is stronger evidence', () {
    test('typing correct counts double and stretches further', () {
      final viaTyping = MemoryScheduler.recordRecall(
        freshItem(),
        correct(t0, type: ReviewExerciseType.typing),
      );
      final viaTap = MemoryScheduler.recordRecall(freshItem(), correct(t0));
      expect(viaTyping.successfulRecalls, 2);
      expect(viaTap.successfulRecalls, 1);
      expect(viaTyping.typingSuccesses, 1);
      expect(viaTyping.ease, greaterThan(viaTap.ease));
    });

    test('slow correct answers gain less ease', () {
      final fast = MemoryScheduler.recordRecall(
        freshItem(),
        correct(t0, responseMs: 2000),
      );
      final slow = MemoryScheduler.recordRecall(
        freshItem(),
        correct(t0, responseMs: 30000),
      );
      expect(slow.ease, lessThan(fast.ease));
    });
  });

  group('selectDue', () {
    test('returns only due items, most overdue first', () {
      final studied = MemoryScheduler.recordRecall(freshItem('a'), correct(t0));
      final fresh = freshItem('b'); // due at t0
      final future = freshItem(
        'f',
      ).copyWith(nextReviewAt: t0.add(const Duration(days: 30)));
      final due = MemoryScheduler.selectDue([
        future,
        fresh,
        studied,
      ], t0.add(const Duration(days: 5)));
      expect(due.map((e) => e.itemId), ['b', 'a']);
    });

    test('nothing due returns empty (no fake urgency)', () {
      final item = MemoryScheduler.recordRecall(freshItem(), correct(t0));
      expect(MemoryScheduler.selectDue([item], t0), isEmpty);
    });

    test('ties break toward most-failed then hardest', () {
      final base = t0.subtract(const Duration(days: 1));
      final failed = freshItem(
        'failed',
      ).copyWith(nextReviewAt: base, failedRecalls: 3);
      final clean = freshItem('clean').copyWith(nextReviewAt: base);
      final due = MemoryScheduler.selectDue([clean, failed], t0);
      expect(due.first.itemId, 'failed');
    });

    test('duplicate itemIds collapse to first occurrence', () {
      final item = freshItem('dup');
      final due = MemoryScheduler.selectDue([item, item], t0);
      expect(due, hasLength(1));
    });

    test('limit caps session size', () {
      final items = List.generate(30, (i) => freshItem('w$i'));
      expect(MemoryScheduler.selectDue(items, t0), hasLength(20));
      expect(MemoryScheduler.selectDue(items, t0, limit: 5), hasLength(5));
    });
  });

  group('serialization', () {
    test('toMap/fromMap round-trips all scheduling fields', () {
      final item = MemoryScheduler.recordRecall(
        freshItem('w9'),
        correct(t0, type: ReviewExerciseType.typing, responseMs: 1234),
      );
      final restored = MemoryItemState.fromMap(item.toMap());
      expect(restored.itemId, item.itemId);
      expect(restored.itemType, item.itemType);
      expect(restored.nextReviewAt, item.nextReviewAt);
      expect(restored.intervalDays, item.intervalDays);
      expect(restored.ease, item.ease);
      expect(restored.successfulRecalls, item.successfulRecalls);
      expect(restored.masteryState, item.masteryState);
      expect(restored.lastResponseTimeMs, 1234);
      expect(restored.lastExerciseType, ReviewExerciseType.typing);
      expect(restored.typingSuccesses, 1);
    });

    test('corrupt/legacy maps degrade to fresh-tracking, never throw', () {
      final restored = MemoryItemState.fromMap({'itemId': 'x'});
      expect(restored.itemId, 'x');
      expect(restored.masteryState, MasteryState.fresh);
    });
  });

  group('estimateMinutes', () {
    test('scales honestly with queue size', () {
      expect(MemoryScheduler.estimateMinutes(0), 0);
      expect(MemoryScheduler.estimateMinutes(8), 6);
      expect(MemoryScheduler.estimateMinutes(1), 1);
    });
  });

  group('retention signal', () {
    test('isRetained only with net-positive review/mastered recall', () {
      expect(freshItem().isRetained, isFalse);
      final learning = MemoryScheduler.recordRecall(freshItem(), correct(t0));
      expect(learning.isRetained, isFalse);
      final review = MemoryScheduler.recordRecall(
        learning,
        correct(t0.add(const Duration(days: 1))),
      );
      expect(review.isRetained, isTrue);
    });
  });
}
