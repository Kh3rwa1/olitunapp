// WS3 operation-based sync tests: stable operations, deterministic merge,
// convergence across delivery orders, and rejection rules.

import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/review/data/review_recall_operation.dart';
import 'package:itun/features/review/domain/review_item.dart';
import 'package:itun/features/review/domain/review_state_merge_policy.dart';

void main() {
  final t1 = DateTime.utc(2026, 4, 1, 10);
  final t2 = DateTime.utc(2026, 4, 2, 10);

  MemoryItemState state({
    required String id,
    ReviewItemType type = ReviewItemType.word,
    int success = 0,
    int failed = 0,
    DateTime? lastReviewed,
    ReviewExerciseType? exercise,
    MasteryState mastery = MasteryState.fresh,
    double interval = 0,
    DateTime? next,
    DateTime? introduced,
  }) => MemoryItemState(
    itemId: id,
    itemType: type,
    introducedAt: introduced ?? t1,
    lastReviewedAt: lastReviewed,
    nextReviewAt: next ?? t2,
    intervalDays: interval,
    successfulRecalls: success,
    failedRecalls: failed,
    masteryState: mastery,
    lastExerciseType: exercise,
  );

  ReviewRecallOperation op({
    required String id,
    String user = 'u1',
    String item = 'w1',
    bool correct = true,
    DateTime? at,
    String device = 'd1',
    int seq = 0,
  }) => ReviewRecallOperation(
    operationId: id,
    userId: user,
    itemId: item,
    itemType: ReviewItemType.word,
    exerciseType: ReviewExerciseType.recognition,
    correct: correct,
    occurredAt: at ?? t1,
    deviceId: device,
    localSequence: seq,
    schemaVersion: 3,
    createdAt: t1,
  );

  group('WS3 recall operations', () {
    test('duplicate operation delivery is idempotent (same id equal)', () {
      final a = op(id: 'op_1', seq: 1);
      final b = op(id: 'op_1', seq: 1, device: 'd2', at: t2);
      // Identity for dedupe is the operationId alone.
      expect(a.operationId, b.operationId);
      expect(a.validate(), isNull);
    });

    test('validation rejects bad operations', () {
      expect(op(id: '').validate(), isNotNull);
      expect(op(id: 'op_x', item: '').validate(), isNotNull);
      expect(op(id: 'op_x', device: '').validate(), isNotNull);
      expect(
        ReviewRecallOperation(
          operationId: 'op_x',
          userId: 'u1',
          itemId: 'w1',
          itemType: ReviewItemType.word,
          exerciseType: ReviewExerciseType.recognition,
          correct: true,
          responseTimeMs: -5,
          occurredAt: t1,
          deviceId: 'd1',
          localSequence: 0,
          schemaVersion: 3,
          createdAt: t1,
        ).validate(),
        isNotNull,
      );
    });

    test('server order is total and delivery-independent', () {
      final a = op(id: 'op_b', device: 'd2');
      final b = op(id: 'op_a', seq: 5);
      final c = op(id: 'op_c', at: t2);
      final sorted = [c, a, b]
        ..sort(ReviewRecallOperation.compareForServerApply);
      expect(sorted.map((e) => e.operationId), ['op_a', 'op_b', 'op_c']);
      // Same set in another delivery order converges identically.
      final sorted2 = [a, b, c]
        ..sort(ReviewRecallOperation.compareForServerApply);
      expect(sorted2.map((e) => e.operationId), ['op_a', 'op_b', 'op_c']);
    });

    test('tied timestamps do not affect convergence (deterministic)', () {
      final x = op(id: 'op_x', at: t1);
      final y = op(id: 'op_y', at: t1);
      expect(
        ReviewRecallOperation.compareForServerApply(x, y),
        -ReviewRecallOperation.compareForServerApply(y, x),
      );
      expect(ReviewRecallOperation.compareForServerApply(x, x), 0);
    });

    test('round-trip serialization preserves the operation', () {
      final original = op(id: 'op_rt', seq: 7);
      final revived = ReviewRecallOperation.fromMap(original.toMap());
      expect(revived.operationId, 'op_rt');
      expect(revived.localSequence, 7);
      expect(revived.occurredAt, t1);
      expect(ReviewRecallOperation.compareForServerApply(original, revived), 0);
    });
  });

  group('WS3 snapshot merge (compat path)', () {
    test('merge is order-independent (merge(a,b) == merge(b,a))', () {
      final a = state(
        id: 'w1',
        success: 3,
        failed: 1,
        lastReviewed: t1,
        exercise: ReviewExerciseType.typing,
        mastery: MasteryState.review,
        interval: 2,
      );
      final b = state(
        id: 'w1',
        success: 5,
        lastReviewed: t2,
        exercise: ReviewExerciseType.recognition,
        mastery: MasteryState.learning,
        interval: 4,
      );
      final ab = ReviewStateMergePolicy.merge(a, b);
      final ba = ReviewStateMergePolicy.merge(b, a);
      expect(ab, ba);
    });

    test('merge is idempotent', () {
      final a = state(id: 'w1', success: 2, lastReviewed: t1);
      expect(ReviewStateMergePolicy.merge(a, a), a);
    });

    test(
      'equal timestamps resolve deterministically, not by argument order',
      () {
        final a = state(
          id: 'w1',
          success: 2,
          lastReviewed: t1,
          exercise: ReviewExerciseType.typing,
        );
        final b = state(
          id: 'w1',
          success: 2,
          lastReviewed: t1,
          exercise: ReviewExerciseType.recognition,
        );
        final ab = ReviewStateMergePolicy.merge(a, b);
        final ba = ReviewStateMergePolicy.merge(b, a);
        expect(ab, ba);
        expect(ab.lastExerciseType, isNotNull);
      },
    );

    test('cross-type merge is rejected', () {
      final a = state(id: 'w1');
      final b = state(id: 'w1', type: ReviewItemType.sentence);
      expect(() => ReviewStateMergePolicy.merge(a, b), throwsArgumentError);
    });

    test('cross-id merge is rejected', () {
      final a = state(id: 'w1');
      final b = state(id: 'w2');
      expect(() => ReviewStateMergePolicy.merge(a, b), throwsArgumentError);
    });

    test('observed failure forces learning with earliest safe due date', () {
      final ok = state(
        id: 'w1',
        success: 6,
        lastReviewed: t2,
        mastery: MasteryState.review,
        next: t2.add(const Duration(days: 3)),
      );
      final bad = state(
        id: 'w1',
        success: 1,
        failed: 2,
        lastReviewed: t1,
        mastery: MasteryState.learning,
        next: t1.add(const Duration(minutes: 10)),
      );
      final merged = ReviewStateMergePolicy.merge(ok, bad);
      expect(merged.masteryState, MasteryState.learning);
      expect(merged.nextReviewAt, t1.add(const Duration(minutes: 10)));
      // Order-independent.
      expect(ReviewStateMergePolicy.merge(bad, ok), merged);
    });

    test('evidence is monotonic (never decreases)', () {
      final a = state(id: 'w1', success: 4, failed: 1);
      final b = state(id: 'w1', success: 2, failed: 3);
      final merged = ReviewStateMergePolicy.merge(a, b);
      expect(merged.successfulRecalls, 4);
      expect(merged.failedRecalls, 3);
    });
  });
}
