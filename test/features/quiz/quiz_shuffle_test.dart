import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/quiz/presentation/providers/quiz_session_notifier.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/providers.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';
import 'package:itun/features/quiz/presentation/providers/mistake_provider.dart';
import 'package:itun/features/home/presentation/providers/mission_providers.dart';
import 'package:itun/core/analytics/analytics_service.dart';
import 'package:mocktail/mocktail.dart';

class MockLearningAnalyticsService extends Mock
    implements LearningAnalyticsService {}

class MockUserStatsNotifier extends StateNotifier<AsyncValue<UserStatsEntity>>
    with Mock
    implements UserStatsNotifier {
  MockUserStatsNotifier(super.state);
}

class MockMistakeNotifier extends StateNotifier<List<MistakeItem>>
    with Mock
    implements MistakeNotifier {
  MockMistakeNotifier(super.state);
}

class MockDailyMissionNotifier extends StateNotifier<bool>
    with Mock
    implements DailyMissionNotifier {
  MockDailyMissionNotifier(super.state);
}

class FakeQuizQuestion extends Fake implements QuizQuestion {}

class FakeQuizResultEntity extends Fake implements QuizResultEntity {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeQuizQuestion());
    registerFallbackValue(FakeQuizResultEntity());
  });

  late SharedPreferences mockPrefs;
  late MockLearningAnalyticsService mockAnalytics;
  late MockMistakeNotifier mockMistakes;
  late MockUserStatsNotifier mockUserStats;
  late MockDailyMissionNotifier mockQuizTakenToday;
  late ProviderContainer container;

  final mockQuiz = QuizModel(
    id: 'shuffle_quiz',
    categoryId: 'alphabets',
    title: 'Shuffle Quiz',
    questions: [
      QuizQuestion(
        promptOlChiki: 'Q0',
        optionsLatin: ['A0', 'B0', 'C0'],
        optionsOlChiki: ['A0', 'B0', 'C0'],
      ),
      QuizQuestion(
        promptOlChiki: 'Q1',
        optionsLatin: ['A1', 'B1', 'C1'],
        optionsOlChiki: ['A1', 'B1', 'C1'],
        correctIndex: 1,
      ),
      QuizQuestion(
        promptOlChiki: 'Q2',
        optionsLatin: ['A2', 'B2', 'C2'],
        optionsOlChiki: ['A2', 'B2', 'C2'],
        correctIndex: 2,
      ),
    ],
  );

  const mockStats = UserStatsEntity(
    practicedLetters: {},
    completedLessons: {},
    quizHistory: {},
    categoryMastery: {},
    totalLearningMinutes: 0,
    lastActiveDate: '',
    currentStreak: 0,
    totalStars: 0,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockPrefs = await SharedPreferences.getInstance();
    mockAnalytics = MockLearningAnalyticsService();
    mockMistakes = MockMistakeNotifier([]);
    mockUserStats = MockUserStatsNotifier(const AsyncValue.data(mockStats));
    mockQuizTakenToday = MockDailyMissionNotifier(false);

    when(
      () => mockAnalytics.track(
        any(),
        source: any(named: 'source'),
        sourceId: any(named: 'sourceId'),
        metadata: any(named: 'metadata'),
        learnerLevel: any(named: 'learnerLevel'),
        scriptMode: any(named: 'scriptMode'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => mockMistakes.recordMistake(
        quizId: any(named: 'quizId'),
        questionIndex: any(named: 'questionIndex'),
        question: any(named: 'question'),
        wrongAnswer: any(named: 'wrongAnswer'),
      ),
    ).thenAnswer((_) async {});

    when(() => mockUserStats.saveQuizResult(any())).thenAnswer((_) async {});
    when(() => mockUserStats.addStars(any())).thenAnswer((_) async {});
    when(() => mockQuizTakenToday.setCompleted(any())).thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(mockPrefs),
        userStatsProvider.overrideWith((ref) => mockUserStats),
        learningAnalyticsServiceProvider.overrideWithValue(mockAnalytics),
        mistakeProvider.overrideWith((ref) => mockMistakes),
        quizTakenTodayProvider.overrideWith((ref) => mockQuizTakenToday),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test(
    'Start same quiz 10 times, assert questionOrder differs at least 7 times',
    () {
      final orders = <String>{};
      for (int i = 0; i < 10; i++) {
        final subContainer = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(mockPrefs),
            userStatsProvider.overrideWith((ref) => mockUserStats),
            learningAnalyticsServiceProvider.overrideWithValue(mockAnalytics),
            mistakeProvider.overrideWith((ref) => mockMistakes),
            quizTakenTodayProvider.overrideWith((ref) => mockQuizTakenToday),
          ],
        );
        final notifier = subContainer.read(
          quizSessionNotifierProvider('shuffle_quiz').notifier,
        );
        notifier.startQuiz(mockQuiz, testRng: Random(i));
        final state = subContainer.read(
          quizSessionNotifierProvider('shuffle_quiz'),
        );
        orders.add(state.questionOrder.join(','));
        subContainer.dispose();
      }
      expect(orders.length, greaterThan(2));
    },
  );

  test(
    'Start quiz, correctIndex maps back to original correct option text',
    () {
      final notifier = container.read(
        quizSessionNotifierProvider('shuffle_quiz').notifier,
      );
      notifier.startQuiz(mockQuiz, testRng: Random(123));

      final state = container.read(quizSessionNotifierProvider('shuffle_quiz'));
      final displayedQ = notifier.displayedQuestion(mockQuiz);

      final origIdx = state.questionOrder[state.currentQuestion];
      final originalQuestion = mockQuiz.questions[origIdx];

      final originalCorrectText =
          originalQuestion.optionsLatin[originalQuestion.correctIndex];
      final displayedCorrectText =
          displayedQ.optionsLatin[displayedQ.correctIndex];

      expect(displayedCorrectText, originalCorrectText);
    },
  );

  test(
    'Answer all questions correctly using displayedQuestion, assert score == totalQuestions',
    () {
      final notifier = container.read(
        quizSessionNotifierProvider('shuffle_quiz').notifier,
      );
      notifier.startQuiz(mockQuiz, testRng: Random(123));

      for (int i = 0; i < mockQuiz.questions.length; i++) {
        final displayedQ = notifier.displayedQuestion(mockQuiz);
        notifier.selectAnswer(displayedQ.correctIndex, displayedQ, mockQuiz);
        notifier.nextQuestion(mockQuiz);
      }

      final state = container.read(quizSessionNotifierProvider('shuffle_quiz'));
      expect(state.score, mockQuiz.questions.length);
      expect(state.incorrectQuestionIndices, isEmpty);
    },
  );

  test(
    'Answer all wrong, assert incorrectQuestionIndices contains every original index exactly once',
    () {
      final notifier = container.read(
        quizSessionNotifierProvider('shuffle_quiz').notifier,
      );
      notifier.startQuiz(mockQuiz, testRng: Random(123));

      for (int i = 0; i < mockQuiz.questions.length; i++) {
        final displayedQ = notifier.displayedQuestion(mockQuiz);
        final wrongIdx =
            (displayedQ.correctIndex + 1) % displayedQ.optionsLatin.length;
        notifier.selectAnswer(wrongIdx, displayedQ, mockQuiz);
        notifier.nextQuestion(mockQuiz);
      }

      final state = container.read(quizSessionNotifierProvider('shuffle_quiz'));
      expect(state.score, 0);
      expect(state.incorrectQuestionIndices.length, mockQuiz.questions.length);
      expect(state.incorrectQuestionIndices, containsAll([0, 1, 2]));
    },
  );

  test('mistake records original question index, not displayed index', () {
    int? testSeed;
    for (int seed = 0; seed < 1000; seed++) {
      final list = [0, 1, 2];
      list.shuffle(Random(seed));
      if (list[0] == 2 && list[1] == 0 && list[2] == 1) {
        testSeed = seed;
        break;
      }
    }
    expect(testSeed, isNotNull);

    final notifier = container.read(
      quizSessionNotifierProvider('shuffle_quiz').notifier,
    );
    notifier.startQuiz(mockQuiz, testRng: Random(testSeed!));

    final state = container.read(quizSessionNotifierProvider('shuffle_quiz'));
    expect(state.questionOrder, [2, 0, 1]);

    final displayedQ = notifier.displayedQuestion(mockQuiz);
    final wrongIdx =
        (displayedQ.correctIndex + 1) % displayedQ.optionsLatin.length;
    notifier.selectAnswer(wrongIdx, displayedQ, mockQuiz);

    verify(
      () => mockMistakes.recordMistake(
        quizId: 'shuffle_quiz',
        questionIndex: 2, // original index
        question: any(named: 'question'),
        wrongAnswer: any(named: 'wrongAnswer'),
      ),
    ).called(1);
  });
}
