// ReviewStore tests: offline-first persistence, duplicate prevention,
// sync-conflict-safe merge (last-writer-wins per item is acceptable v1;
// ensureIntroduced never clobbers scheduling data).

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/review/data/review_store.dart';
import 'package:itun/features/review/domain/review_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final t0 = DateTime.utc(2026, 1, 1, 9);

  Future<ReviewStore> freshStore() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return ReviewStore.load(prefs);
  }

  group('ReviewStore', () {
    test('loads empty when nothing persisted (offline-first)', () async {
      final store = await freshStore();
      expect(store.all(), isEmpty);
      expect(store.dueCount(t0), 0);
      expect(store.retainedCount(), 0);
    });

    test(
      'ensureIntroduced is duplicate-safe (never resets progress)',
      () async {
        final store = await freshStore();
        final first = store.ensureIntroduced(
          itemId: 'w1',
          itemType: ReviewItemType.word,
          now: t0,
        );
        final progressed = store.recordRecall(
          itemId: 'w1',
          itemType: ReviewItemType.word,
          correct: true,
          exerciseType: ReviewExerciseType.recognition,
          now: t0,
        );
        final again = store.ensureIntroduced(
          itemId: 'w1',
          itemType: ReviewItemType.word,
          now: t0.add(const Duration(days: 30)),
        );
        expect(again.successfulRecalls, progressed.state.successfulRecalls);
        expect(again.nextReviewAt, progressed.state.nextReviewAt);
        expect(first.introducedAt, again.introducedAt);
      },
    );

    test('wrong answers cause earlier review than correct ones', () async {
      final store = await freshStore();
      final ok = store.recordRecall(
        itemId: 'good',
        itemType: ReviewItemType.word,
        correct: true,
        exerciseType: ReviewExerciseType.recognition,
        now: t0,
      );
      final bad = store.recordRecall(
        itemId: 'bad',
        itemType: ReviewItemType.word,
        correct: false,
        exerciseType: ReviewExerciseType.recognition,
        now: t0,
      );
      expect(bad.state.nextReviewAt.isBefore(ok.state.nextReviewAt), isTrue);
      // The failed item is due again within the hour; the passed one is not
      // due for a day.
      expect(
        store.due(t0.add(const Duration(hours: 1))).map((e) => e.itemId),
        contains('bad'),
      );
      expect(
        store.due(t0.add(const Duration(hours: 1))).map((e) => e.itemId),
        isNot(contains('good')),
      );
    });

    test('typing results affect mastery faster than taps', () async {
      final store = await freshStore();
      final typed = store.recordRecall(
        itemId: 'w-type',
        itemType: ReviewItemType.word,
        correct: true,
        exerciseType: ReviewExerciseType.typing,
        now: t0,
      );
      final tapped = store.recordRecall(
        itemId: 'w-tap',
        itemType: ReviewItemType.word,
        correct: true,
        exerciseType: ReviewExerciseType.recognition,
        now: t0,
      );
      expect(
        typed.state.successfulRecalls,
        greaterThan(tapped.state.successfulRecalls),
      );
    });

    test('persists across loads (offline reload)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final first = await ReviewStore.load(prefs);
      first.recordRecall(
        itemId: 'w1',
        itemType: ReviewItemType.word,
        correct: true,
        exerciseType: ReviewExerciseType.typing,
        now: t0,
      );
      final second = await ReviewStore.load(prefs);
      expect(second.get('w1')?.successfulRecalls, 2);
      expect(second.get('w1')?.typingSuccesses, 1);
    });

    test('corrupt storage degrades to empty, never throws', () async {
      SharedPreferences.setMockInitialValues({
        'review_states_v1': 'not-json{{{',
      });
      final prefs = await SharedPreferences.getInstance();
      final store = await ReviewStore.load(prefs);
      expect(store.all(), isEmpty);
    });

    test('corrupt entries are skipped, good ones survive', () async {
      SharedPreferences.setMockInitialValues({
        'review_states_v1': jsonEncode({
          'good': {
            'itemId': 'good',
            'itemType': 'word',
            'introducedAt': t0.toIso8601String(),
            'nextReviewAt': t0.toIso8601String(),
          },
          'bad': 'garbage',
        }),
      });
      final prefs = await SharedPreferences.getInstance();
      final store = await ReviewStore.load(prefs);
      expect(store.get('good')?.itemId, 'good');
      expect(store.all(), hasLength(1));
    });

    test('retainedCount/countsByState reflect real learning', () async {
      final store = await freshStore();
      store.ensureIntroduced(
        itemId: 'new',
        itemType: ReviewItemType.word,
        now: t0,
      );
      var now = t0;
      for (var i = 0; i < 2; i++) {
        store.recordRecall(
          itemId: 'kept',
          itemType: ReviewItemType.word,
          correct: true,
          exerciseType: ReviewExerciseType.recognition,
          now: now,
        );
        now = store.get('kept')!.nextReviewAt;
      }
      expect(store.retainedCount(), 1);
      final counts = store.countsByState();
      expect(counts[MasteryState.fresh], 1);
      expect(counts[MasteryState.review], 1);
    });

    test('becameMastered fires exactly once', () async {
      final store = await freshStore();
      var now = t0;
      var firings = 0;
      for (var i = 0; i < 8; i++) {
        final result = store.recordRecall(
          itemId: 'w1',
          itemType: ReviewItemType.word,
          correct: true,
          exerciseType: ReviewExerciseType.recognition,
          now: now,
        );
        if (result.becameMastered) firings++;
        now = result.state.nextReviewAt;
      }
      expect(firings, 1);
    });

    test('clear wipes local state', () async {
      final store = await freshStore();
      store.ensureIntroduced(
        itemId: 'w1',
        itemType: ReviewItemType.word,
        now: t0,
      );
      await store.clear();
      expect(store.all(), isEmpty);
    });
  });
}
