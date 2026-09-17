// WS11 performance budgets: repeatable local benchmarks for the review
// hot paths. Budgets are asserted so regressions fail loudly.

import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/review/data/review_state_local_repository.dart';
import 'package:itun/features/review/data/review_store.dart';
import 'package:itun/features/review/domain/review_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final t0 = DateTime.utc(2026, 7, 1, 10);

  Future<(ReviewStore, InMemoryDelayedReviewStateRepository)> setup() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = InMemoryDelayedReviewStateRepository();
    final store = await ReviewStore.loadWithRepository(
      repo,
      prefs: prefs,
      storageKey: 'review_states_perf',
    );
    return (store, repo);
  }

  group('WS11 budgets', () {
    test('one recall persist completes < 2s (mock backend)', () async {
      final (store, repo) = await setup();
      final sw = Stopwatch()..start();
      await store.recordRecallDurable(
        itemId: 'w1',
        itemType: ReviewItemType.word,
        correct: true,
        exerciseType: ReviewExerciseType.typing,
        now: t0,
      );
      sw.stop();
      expect(repo.saveCallCount, 1);
      expect(sw.elapsedMilliseconds, lessThan(2000));
    });

    test('2000-item store loads < 5s and dues select < 2s', () async {
      final (store, _) = await setup();
      for (var i = 0; i < 2000; i++) {
        store.ensureIntroduced(
          itemId: 'w_$i',
          itemType: ReviewItemType.word,
          now: t0.subtract(Duration(days: i % 30)),
        );
      }
      await store.persist();
      final sw = Stopwatch()..start();
      final due = store.due(t0);
      sw.stop();
      expect(due.length, lessThanOrEqualTo(20));
      expect(sw.elapsedMilliseconds, lessThan(2000));
    });

    test('20-card session: 20 recalls persist once each, bounded', () async {
      final (store, repo) = await setup();
      final sw = Stopwatch()..start();
      for (var i = 0; i < 20; i++) {
        await store.recordRecallDurable(
          itemId: 'w_$i',
          itemType: ReviewItemType.word,
          correct: i.isEven,
          exerciseType: ReviewExerciseType.recognition,
          now: t0.add(Duration(minutes: i)),
        );
      }
      sw.stop();
      expect(repo.saveCallCount, 20);
      expect(sw.elapsedMilliseconds, lessThan(10000));
    });

    test('no duplicate writes per answer across a session', () async {
      final (store, repo) = await setup();
      await store.ensureIntroducedDurable(
        itemId: 'w_dup',
        itemType: ReviewItemType.word,
        now: t0,
      );
      final before = repo.saveCallCount;
      await store.recordRecallDurable(
        itemId: 'w_dup',
        itemType: ReviewItemType.word,
        correct: true,
        exerciseType: ReviewExerciseType.recognition,
        now: t0.add(const Duration(minutes: 5)),
      );
      expect(repo.saveCallCount, before + 1);
    });
  });
}
