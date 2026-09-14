// End-to-end learning loop journey (automated form of the manual journey):
// new learner -> learn items -> quiz (with mistakes) -> leave -> return
// later -> Today's Review -> typing/listening/recognition -> reschedule
// -> MASTERED. Walks the REAL ReviewStore + scheduler + quiz hook chain.

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/analytics/analytics_service.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/home/presentation/providers/mission_providers.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';
import 'package:itun/features/profile/presentation/providers/profile_providers.dart';
import 'package:itun/features/quiz/presentation/providers/mistake_provider.dart';
import 'package:itun/features/quiz/presentation/providers/quiz_session_notifier.dart';
import 'package:itun/features/review/data/review_store.dart';
import 'package:itun/features/review/domain/memory_scheduler.dart';
import 'package:itun/features/review/domain/review_item.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAnalytics extends Mock implements LearningAnalyticsService {}

class _MockUserStats extends UserStatsNotifier {
  int starsAwarded = 0;

  @override
  AsyncValue<UserStatsEntity> build() => const AsyncValue.data(
    UserStatsEntity(
      practicedLetters: {},
      completedLessons: {},
      quizHistory: {},
      categoryMastery: {},
      totalLearningMinutes: 0,
      lastActiveDate: '',
      currentStreak: 0,
      totalStars: 0,
    ),
  );

  @override
  Future<void> saveQuizResult(covariant dynamic result) async {}

  @override
  Future<void> addStars(covariant dynamic count) async {
    starsAwarded += count as int;
  }
}

class _MockMistakes extends MistakeNotifier {
  @override
  List<MistakeItem> build() => [];

  @override
  Future<void> syncFromBackend() async {}

  @override
  Future<void> recordMistake({
    required String quizId,
    required int questionIndex,
    required QuizQuestion question,
    String? wrongAnswer,
  }) async {}
}

class _MockQuizTakenToday extends QuizTakenTodayNotifier {
  @override
  bool build() => false;

  @override
  Future<void> setCompleted(bool completed) async {}
}

/// Word question attributed to a corpus item (generator-set source ID).
QuizQuestion _wordQuestion(String wordId, {bool correct = true}) =>
    QuizQuestion(
      promptOlChiki: 'ᱫᱟᱜ',
      optionsLatin: correct ? const ['water', 'fire'] : const ['fire', 'water'],
      optionsOlChiki: correct
          ? const ['ᱫᱟᱜ', 'ᱥᱮᱸᱜᱮᱞ']
          : const ['ᱥᱮᱸᱜᱮᱞ', 'ᱫᱟᱜ'],
      correctIndex: 0, // ignore: avoid_redundant_argument_values
      sourceWordId: wordId,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late ProviderContainer container;
  late _MockUserStats stats;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    final analytics = _MockAnalytics();
    when(
      () => analytics.track(
        any(),
        source: any(named: 'source'),
        sourceId: any(named: 'sourceId'),
        metadata: any(named: 'metadata'),
        learnerLevel: any(named: 'learnerLevel'),
        scriptMode: any(named: 'scriptMode'),
      ),
    ).thenAnswer((_) async {});
    stats = _MockUserStats();
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        userStatsProvider.overrideWith(() => stats),
        learningAnalyticsServiceProvider.overrideWithValue(analytics),
        mistakeProvider.overrideWith(_MockMistakes.new),
        quizTakenTodayProvider.overrideWith(_MockQuizTakenToday.new),
      ],
    );
  });

  tearDown(() => container.dispose());

  Future<ReviewStore> store() async =>
      container.read(reviewStoreProvider.future);

  Future<void> settle() async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await container.read(reviewStoreProvider.future);
  }

  test(
    'full loop: learn -> quiz mistake -> return -> review -> mastered',
    () async {
      // --- Day 0: new learner completes a lesson introducing 5 items. ---
      var s = await store();
      final t0 = DateTime.now().toUtc();
      for (var i = 0; i < 5; i++) {
        s.ensureIntroduced(
          itemId: 'w$i',
          itemType: ReviewItemType.word,
          now: t0,
        );
      }
      expect(s.dueCount(t0), 5, reason: 'new items are due immediately');

      // --- Day 0: quiz — 4 correct, 1 wrong (the learner's mistake). ---
      final quiz = QuizModel(
        id: 'lesson_quiz',
        questions: List.generate(
          5,
          (i) => _wordQuestion('w$i', correct: i != 4),
        ),
      );
      final notifier = container.read(
        quizSessionNotifierProvider('lesson_quiz').notifier,
      );
      notifier.startQuiz(quiz, testRng: Random(7));
      for (var i = 0; i < 5; i++) {
        final q = notifier.displayedQuestion(quiz);
        // The learner's mistake is on w4 — keyed by the question's source ID,
        // not the loop index (question order is shuffled).
        final isMistake = q.sourceWordId == 'w4';
        if (isMistake) {
          // Any displayed option EXCEPT the correct one.
          final wrongIndex = q.correctIndex == 0 ? 1 : 0;
          notifier.selectAnswer(wrongIndex, q, quiz);
        } else {
          notifier.selectAnswer(q.correctIndex, q, quiz);
        }
        await notifier.nextQuestion(quiz);
      }
      await settle();

      s = await store();
      expect(
        s.get('w0')!.successfulRecalls,
        1,
        reason: 'correct quiz feeds memory',
      );
      expect(s.get('w4')!.failedRecalls, 1, reason: 'wrong quiz feeds memory');
      expect(s.get('w4')!.masteryState, MasteryState.learning);

      // Wrong item is due sooner than the correct ones.
      final dueNow = s.due(t0.add(const Duration(minutes: 11)));
      expect(dueNow.map((e) => e.itemId), contains('w4'));
      expect(dueNow.map((e) => e.itemId), isNot(contains('w0')));

      // --- Day 1: learner returns; all 5 items are due — w0-w3 hit their
      // 1-day interval, w4 (the mistake) was brought back sooner and is
      // still waiting. (+5 min buffer mirrors a real "next day" return.) ---
      final t1 = t0.add(const Duration(days: 1, minutes: 5));
      final reviewQueue = s.due(t1);
      expect(reviewQueue.map((e) => e.itemId).toSet(), {
        'w0',
        'w1',
        'w2',
        'w3',
        'w4',
      });
      // Most-overdue ordering: the mistake item (scheduled +10 min) first.
      expect(reviewQueue.first.itemId, 'w4');
      // ~6-9 minutes honest estimate, capped 20-card sessions.
      expect(
        MemoryScheduler.estimateMinutes(reviewQueue.length),
        inInclusiveRange(4, 9),
      );

      // --- Day 1: review — recognition correct, then typing correct. ---
      for (final item in reviewQueue.take(2)) {
        s.recordRecall(
          itemId: item.itemId,
          itemType: ReviewItemType.word,
          correct: true,
          exerciseType: ReviewExerciseType.recognition,
          now: t1,
        );
      }
      s.recordRecall(
        itemId: 'w2',
        itemType: ReviewItemType.word,
        correct: true,
        exerciseType: ReviewExerciseType.typing,
        now: t1,
      );
      // Typing counts double: w2 reaches REVIEW in one typing recall.
      expect(s.get('w2')!.masteryState, MasteryState.review);

      // --- Day 2: one more mistake on w4, but recovery works. ---
      final t2 = t1.add(const Duration(days: 1));
      s.recordRecall(
        itemId: 'w3',
        itemType: ReviewItemType.word,
        correct: false,
        exerciseType: ReviewExerciseType.recognition,
        now: t2,
      );
      final t2b = s.get('w3')!.nextReviewAt;
      s.recordRecall(
        itemId: 'w3',
        itemType: ReviewItemType.word,
        correct: true,
        exerciseType: ReviewExerciseType.typing,
        now: t2b,
      );
      expect(
        s.get('w3')!.successfulRecalls,
        greaterThan(s.get('w3')!.failedRecalls),
        reason: 'mistake -> later recovery',
      );

      // --- Days 2..N: consistent retrieval drives w2 to MASTERED, +10 stars. ---
      var now = s.get('w2')!.nextReviewAt;
      var masteredFired = false;
      for (var i = 0; i < 6 && !masteredFired; i++) {
        final result = s.recordRecall(
          itemId: 'w2',
          itemType: ReviewItemType.word,
          correct: true,
          exerciseType: ReviewExerciseType.typing,
          now: now,
        );
        if (result.becameMastered) masteredFired = true;
        now = result.state.nextReviewAt;
      }
      expect(
        masteredFired,
        isTrue,
        reason: 'repeated retrieval reaches MASTERED',
      );
      expect(s.get('w2')!.masteryState, MasteryState.mastered);
      expect(
        s.get('w2')!.intervalDays,
        greaterThanOrEqualTo(MemoryScheduler.intervalForMasteredDays),
      );

      // Retention headline reflects real learning.
      final snapshot = s.retainedCount();
      expect(snapshot, greaterThanOrEqualTo(1));
    },
  );
}
