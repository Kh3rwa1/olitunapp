import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/analytics/analytics_service.dart';
import 'package:itun/core/api/appwrite_functions_service.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/auth/presentation/providers/auth_providers.dart';
import 'package:itun/features/home/presentation/providers/mission_providers.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';
import 'package:itun/features/profile/presentation/providers/profile_providers.dart';
import 'package:itun/features/quiz/presentation/providers/mistake_provider.dart';
import 'package:itun/features/quiz/presentation/providers/quiz_session_notifier.dart';
import 'package:itun/features/review/data/review_store.dart';
import 'package:itun/features/review/domain/review_corpus_identity.dart';
import 'package:itun/features/review/domain/review_item.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/local_settings_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAnalytics extends Mock implements LearningAnalyticsService {}

class _MockFunctions extends Mock implements AppwriteFunctionsService {}

class _MockLessonCompletedToday extends LessonCompletedTodayNotifier {
  @override
  bool build() => false;
}

class _MockQuizTakenToday extends QuizTakenTodayNotifier {
  @override
  bool build() => false;
}

class _MockUserStats extends UserStatsNotifier {
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
  Future<void> addStars(covariant dynamic count) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockAnalytics mockAnalytics;
  late _MockFunctions mockFunctions;

  setUp(() async {
    mockAnalytics = _MockAnalytics();
    mockFunctions = _MockFunctions();

    when(
      () => mockAnalytics.track(
        any(),
        source: any(named: 'source'),
        sourceId: any(named: 'sourceId'),
        metadata: any(named: 'metadata'),
      ),
    ).thenAnswer((_) async {});
  });

  QuizModel createSampleQuiz({required String wordId}) {
    return QuizModel(
      id: 'quiz_unit_1',
      categoryId: 'unit_1',
      title: 'Vocabulary Quiz',
      questions: [
        QuizQuestion(
          promptOlChiki: 'ᱚᱞ',
          promptLatin: 'ol',
          optionsLatin: ['write', 'read', 'speak', 'sing'],
          optionsOlChiki: ['ᱚᱞ', 'ᱯᱟᱲᱦᱟᱣ', 'ᱨᱚᱲ', 'ᱥᱮᱨᱮᱧ'],
          sourceWordId: wordId,
        ),
      ],
    );
  }

  Future<ProviderContainer> createContainer({
    Map<String, Object> initialPrefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(initialPrefs);
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        learningAnalyticsServiceProvider.overrideWithValue(mockAnalytics),
        appwriteFunctionsServiceProvider.overrideWithValue(mockFunctions),
        userStatsProvider.overrideWith(_MockUserStats.new),
        soundEnabledProvider.overrideWith((ref) => false),
        reduceVisualEffectsProvider.overrideWithValue(true),
        lessonCompletedTodayProvider.overrideWith(
          _MockLessonCompletedToday.new,
        ),
        quizTakenTodayProvider.overrideWith(_MockQuizTakenToday.new),
        isAuthenticatedProvider.overrideWith((ref) => true),
        corpusIdentityMapProvider.overrideWith(
          (ref) async => ReviewCorpusIdentityMap.empty(),
        ),
      ],
    );
    addTearDown(container.dispose);
    // Warm up reviewStoreProvider
    await container.read(reviewStoreProvider.future);
    return container;
  }

  group('Memory + Mistake Unification: Single Source of Truth', () {
    test(
      '1. Quiz wrong answer updates BOTH ReviewState and legacy mistake state',
      () async {
        final container = await createContainer();
        const wordId = 'word_ol_123';
        final quiz = createSampleQuiz(wordId: wordId);

        final quizNotifier = container.read(
          quizSessionNotifierProvider(quiz.id).notifier,
        );
        quizNotifier.startQuiz(quiz);

        // Select wrong answer (index 1 is 'read', correct is 0 'write')
        quizNotifier.selectAnswer(1, quiz.questions.first, quiz);
        await pumpEventQueue();

        // Check legacy mistake state
        final mistakes = container.read(mistakeProvider);
        expect(mistakes.length, 1);
        expect(mistakes.first.question.sourceWordId, wordId);

        // Check canonical ReviewStore state
        final reviewStore = container.read(reviewStoreProvider).value!;
        final itemState = reviewStore.get(wordId);
        expect(itemState, isNotNull);
        expect(itemState!.failedRecalls, 1);
        expect(itemState.successfulRecalls, 0);
        expect(
          itemState.intervalDays,
          0.0,
        ); // Fresh item failing stays in learning (10 min retry)
      },
    );

    test(
      '2. Mistake review updates ReviewState (correct answer extends interval, wrong answers lapse)',
      () async {
        final container = await createContainer();
        const wordId = 'word_ol_123';
        final quiz = createSampleQuiz(wordId: wordId);

        // Seed mistake and initial review state
        await container
            .read(reviewStoreProvider.notifier)
            .recordRecall(
              itemId: wordId,
              itemType: ReviewItemType.word,
              correct: false,
              exerciseType: ReviewExerciseType.recognition,
            );
        await container
            .read(mistakeProvider.notifier)
            .recordMistake(
              quizId: quiz.id,
              questionIndex: 0,
              question: quiz.questions.first,
              wrongAnswer: 'read',
            );

        final memItem = resolveQuizMemoryItem(quiz.questions.first);
        expect(memItem, isNotNull);
        expect(memItem!.itemId, wordId);

        // Review the mistake with a CORRECT recall
        await container
            .read(reviewStoreProvider.notifier)
            .recordRecall(
              itemId: memItem.itemId,
              itemType: memItem.itemType,
              correct: true,
              exerciseType: ReviewExerciseType.recognition,
            );
        await container
            .read(mistakeProvider.notifier)
            .masterMistake(quizId: quiz.id, questionIndex: 0);

        // Verify ReviewStore was updated
        final reviewStore = container.read(reviewStoreProvider).value!;
        final updatedState = reviewStore.get(wordId)!;
        expect(updatedState.successfulRecalls, 1);
        expect(updatedState.failedRecalls, 1);
        expect(updatedState.intervalDays, greaterThanOrEqualTo(1));

        // Verify mistake was cleared from active mistakes
        final mistakesAfter = container.read(mistakeProvider);
        expect(mistakesAfter.isEmpty, isTrue);
      },
    );

    test(
      '3. Today’s Review reconciles legacy mistake state upon item recovery',
      () async {
        final container = await createContainer();
        const wordId = 'word_ol_123';
        final quiz = createSampleQuiz(wordId: wordId);

        // Seed a mistake
        await container
            .read(mistakeProvider.notifier)
            .recordMistake(
              quizId: quiz.id,
              questionIndex: 0,
              question: quiz.questions.first,
              wrongAnswer: 'read',
            );
        expect(container.read(mistakeProvider).length, 1);

        // Today's Review performs a successful recall for wordId
        await container
            .read(reviewStoreProvider.notifier)
            .recordRecall(
              itemId: wordId,
              itemType: ReviewItemType.word,
              correct: true,
              exerciseType: ReviewExerciseType.typing,
            );
        // Reconcile
        await container
            .read(mistakeProvider.notifier)
            .reconcileRecoveredItem(wordId);

        // The mistake should now be cleared
        expect(container.read(mistakeProvider).isEmpty, isTrue);
      },
    );

    test(
      '4. Mastered item cannot remain falsely unresolved or be resurrected by backend sync',
      () async {
        const wordId = 'word_mastered_456';
        final quiz = createSampleQuiz(wordId: wordId);

        // Pre-seed mastered item in local storage
        final masteredItem = MemoryItemState(
          itemId: wordId,
          itemType: ReviewItemType.word,
          introducedAt: DateTime.now().subtract(const Duration(days: 30)),
          nextReviewAt: DateTime.now().add(const Duration(days: 28)),
          intervalDays: 28,
          masteryState: MasteryState.mastered,
          successfulRecalls: 6,
        );

        final initialPrefs = {
          ReviewStore.storageKey: jsonEncode({
            'schemaVersion': 2,
            'items': {wordId: masteredItem.toMap()},
          }),
        };

        final container = await createContainer(initialPrefs: initialPrefs);
        final reviewStore = container.read(reviewStoreProvider).value!;
        expect(reviewStore.get(wordId)!.isMastered, isTrue);

        // Mock backend returning an old/stale mistake for this now-mastered word
        when(() => mockFunctions.execute('getUserMistakes')).thenAnswer((
          _,
        ) async {
          return FunctionExecutionResult(
            status: 'completed',
            statusCode: 200,
            responseBody: jsonEncode({
              'ok': true,
              'mistakes': [
                {
                  'quizId': quiz.id,
                  'questionId': '${quiz.id}_0',
                  'questionIndex': 0,
                  'questionSnapshot': quiz.questions.first.toMap(),
                  'addedAt': DateTime.now()
                      .subtract(const Duration(days: 10))
                      .toIso8601String(),
                },
              ],
            }),
          );
        });

        // Trigger cloud sync
        await container.read(mistakeProvider.notifier).syncFromBackend();

        // The stale mistake MUST NOT be resurrected because the item is already mastered!
        final mistakes = container.read(mistakeProvider);
        expect(mistakes.isEmpty, isTrue);
      },
    );

    test(
      '5. Duplicate mistake records do not create duplicate learning states in ReviewStore',
      () async {
        final container = await createContainer();
        const wordId = 'word_ol_123';
        final quiz = createSampleQuiz(wordId: wordId);

        final quizNotifier = container.read(
          quizSessionNotifierProvider(quiz.id).notifier,
        );
        quizNotifier.startQuiz(quiz);

        // Attempt 1: Wrong
        quizNotifier.selectAnswer(1, quiz.questions.first, quiz);
        await pumpEventQueue();

        // Attempt 2: Same question answered wrong again
        quizNotifier.selectAnswer(2, quiz.questions.first, quiz);
        await pumpEventQueue();

        final reviewStore = container.read(reviewStoreProvider).value!;
        // Only 1 entry for wordId in the store (no duplicates)
        final matching = reviewStore
            .all()
            .where((k) => k.itemId == wordId)
            .toList();
        expect(matching.length, 1);
      },
    );

    test(
      '6. All learning surfaces converge on the same canonical item state',
      () async {
        final container = await createContainer();
        const wordId = 'word_ol_123';
        final quiz = createSampleQuiz(wordId: wordId);

        // Step A: Failed in quiz
        final quizNotifier = container.read(
          quizSessionNotifierProvider(quiz.id).notifier,
        );
        quizNotifier.startQuiz(quiz);
        quizNotifier.selectAnswer(2, quiz.questions.first, quiz);
        await pumpEventQueue();

        expect(container.read(mistakeProvider).length, 1);
        final reviewStoreBefore = container.read(reviewStoreProvider).value!;
        expect(reviewStoreBefore.get(wordId)!.failedRecalls, 1);

        // Step B: Mastered in Today's Review
        final reviewNotifier = container.read(reviewStoreProvider.notifier);
        for (var i = 0; i < 6; i++) {
          await reviewNotifier.recordRecall(
            itemId: wordId,
            itemType: ReviewItemType.word,
            correct: true,
            exerciseType: ReviewExerciseType.typing,
          );
        }
        final reviewStoreAfter = container.read(reviewStoreProvider).value!;
        final currentState = reviewStoreAfter.get(wordId)!;
        expect(currentState.isMastered, isTrue);

        // MistakeNotifier reconciles against the canonical ReviewStore
        await container
            .read(mistakeProvider.notifier)
            .reconcileWithReviewStore(reviewStoreAfter);

        expect(container.read(mistakeProvider).isEmpty, isTrue);
      },
    );
  });
}
