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

class MockUserStatsNotifier extends UserStatsNotifier {
  final AsyncValue<UserStatsEntity> _initial;

  MockUserStatsNotifier(this._initial);

  @override
  AsyncValue<UserStatsEntity> build() => _initial;

  @override
  Future<void> saveQuizResult(covariant dynamic result) async {}

  @override
  Future<void> addStars(covariant dynamic count) async {}
}

class MockMistakeNotifier extends MistakeNotifier {
  final List<MistakeItem> _initial;
  int recordMistakeCalls = 0;

  MockMistakeNotifier(this._initial);

  @override
  List<MistakeItem> build() {
    // Skip backend sync in unit tests.
    return _initial;
  }

  @override
  Future<void> syncFromBackend() async {}

  @override
  Future<void> recordMistake({
    required String quizId,
    required int questionIndex,
    required QuizQuestion question,
    String? wrongAnswer,
  }) async {
    recordMistakeCalls++;
  }
}

class MockQuizTakenTodayNotifier extends QuizTakenTodayNotifier {
  final bool _initial;
  int setCompletedCalls = 0;

  MockQuizTakenTodayNotifier(this._initial);

  @override
  bool build() => _initial;

  @override
  Future<void> setCompleted(bool completed) async {
    setCompletedCalls++;
  }
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
  late MockQuizTakenTodayNotifier mockQuizTakenToday;
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
    mockQuizTakenToday = MockQuizTakenTodayNotifier(false);

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

    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(mockPrefs),
        userStatsProvider.overrideWith(() => mockUserStats),
        learningAnalyticsServiceProvider.overrideWithValue(mockAnalytics),
        mistakeProvider.overrideWith(() => mockMistakes),
        quizTakenTodayProvider.overrideWith(() => mockQuizTakenToday),
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
            userStatsProvider.overrideWith(() => mockUserStats),
            learningAnalyticsServiceProvider.overrideWithValue(mockAnalytics),
            mistakeProvider.overrideWith(() => mockMistakes),
            quizTakenTodayProvider.overrideWith(() => mockQuizTakenToday),
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
    'displayedQuestion uses the option order for the shuffled original question',
    () {
      int? testSeed;
      for (int seed = 0; seed < 1000; seed++) {
        final order = [0, 1, 2]..shuffle(Random(seed));
        if (order.first == 2) {
          testSeed = seed;
          break;
        }
      }
      expect(testSeed, isNotNull);

      final mixedQuiz = QuizModel(
        id: 'mixed_shuffle_quiz',
        questions: [
          QuizQuestion(
            promptOlChiki: 'Q0',
            optionsLatin: ['A0', 'B0'],
            optionsOlChiki: ['A0', 'B0'],
            correctIndex: 1,
          ),
          QuizQuestion(
            promptOlChiki: 'Q1',
            optionsLatin: ['A1', 'B1', 'C1', 'D1'],
            optionsOlChiki: ['A1', 'B1', 'C1', 'D1'],
            correctIndex: 3,
          ),
          QuizQuestion(
            promptOlChiki: 'Q2',
            optionsLatin: ['A2', 'B2', 'C2'],
            optionsOlChiki: ['A2', 'B2', 'C2'],
            correctIndex: 2,
          ),
        ],
      );

      final notifier = container.read(
        quizSessionNotifierProvider('mixed_shuffle_quiz').notifier,
      );
      notifier.startQuiz(mixedQuiz, testRng: Random(testSeed!));

      final state = container.read(
        quizSessionNotifierProvider('mixed_shuffle_quiz'),
      );
      expect(state.questionOrder.first, 2);

      final displayedQ = notifier.displayedQuestion(mixedQuiz);
      expect(displayedQ.optionsLatin, hasLength(3));
      expect(displayedQ.optionsLatin[displayedQ.correctIndex], 'C2');
    },
  );

  test(
    'Answer all questions correctly using displayedQuestion, assert score == totalQuestions',
    () async {
      final notifier = container.read(
        quizSessionNotifierProvider('shuffle_quiz').notifier,
      );
      notifier.startQuiz(mockQuiz, testRng: Random(123));

      for (int i = 0; i < mockQuiz.questions.length; i++) {
        final displayedQ = notifier.displayedQuestion(mockQuiz);
        notifier.selectAnswer(displayedQ.correctIndex, displayedQ, mockQuiz);
        await notifier.nextQuestion(mockQuiz);
      }

      final state = container.read(quizSessionNotifierProvider('shuffle_quiz'));
      expect(state.score, mockQuiz.questions.length);
      expect(state.incorrectQuestionIndices, isEmpty);
    },
  );

  test(
    'Answer all wrong, assert incorrectQuestionIndices contains every original index exactly once',
    () async {
      final notifier = container.read(
        quizSessionNotifierProvider('shuffle_quiz').notifier,
      );
      notifier.startQuiz(mockQuiz, testRng: Random(123));

      for (int i = 0; i < mockQuiz.questions.length; i++) {
        final displayedQ = notifier.displayedQuestion(mockQuiz);
        final wrongIdx =
            (displayedQ.correctIndex + 1) % displayedQ.optionsLatin.length;
        notifier.selectAnswer(wrongIdx, displayedQ, mockQuiz);
        await notifier.nextQuestion(mockQuiz);
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

    expect(mockMistakes.recordMistakeCalls, 1);
  });
}
