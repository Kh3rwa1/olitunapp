import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/quiz/presentation/providers/quiz_session_notifier.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/providers.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';
import 'package:itun/features/profile/presentation/providers/profile_providers.dart';
import 'package:itun/features/quiz/presentation/providers/mistake_provider.dart';
import 'package:itun/features/home/presentation/providers/mission_providers.dart';
import 'package:itun/core/analytics/analytics_service.dart';
import 'package:mocktail/mocktail.dart';

class MockLearningAnalyticsService extends Mock
    implements LearningAnalyticsService {}

class MockUserStatsNotifier extends UserStatsNotifier {
  final AsyncValue<UserStatsEntity> _initial;
  final List<QuizResultEntity> savedResults = [];
  final List<int> starsAdded = [];
  bool throwOnSave = false;
  Completer<void>? saveGate;

  MockUserStatsNotifier(this._initial);

  @override
  AsyncValue<UserStatsEntity> build() => _initial;

  @override
  Future<void> saveQuizResult(QuizResultEntity result) async {
    if (throwOnSave) throw Exception('Appwrite offline error');
    savedResults.add(result);
    final gate = saveGate;
    if (gate != null) await gate.future;
  }

  @override
  Future<void> addStars(int count) async {
    starsAdded.add(count);
  }
}

class MockMistakeNotifier extends MistakeNotifier {
  final List<MistakeItem> _initial;

  MockMistakeNotifier(this._initial);

  @override
  List<MistakeItem> build() => _initial;

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
    id: 'test_quiz_id',
    categoryId: 'alphabets',
    title: 'Test Quiz',
    questions: [
      QuizQuestion(
        promptOlChiki: 'Q0',
        optionsLatin: ['A0', 'B0', 'C0'],
        optionsOlChiki: ['A0', 'B0', 'C0'],
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
    container.listen(
      quizSessionNotifierProvider('test_quiz_id'),
      (_, _) {},
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('Quiz Completion & Persistence Tests', () {
    test(
      'Completion of last question saves quiz result, adds stars, and completes daily mission',
      () async {
        final notifier = container.read(
          quizSessionNotifierProvider('test_quiz_id').notifier,
        );
        notifier.startQuiz(mockQuiz);
        final displayedQ = notifier.displayedQuestion(mockQuiz);
        notifier.selectAnswer(displayedQ.correctIndex, displayedQ, mockQuiz);
        await notifier.nextQuestion(mockQuiz);
        final state = container.read(
          quizSessionNotifierProvider('test_quiz_id'),
        );
        expect(state.isQuizComplete, isTrue);
        expect(mockUserStats.savedResults.length, 1);
        expect(mockUserStats.starsAdded, [5]);
        expect(mockQuizTakenToday.setCompletedCalls, 1);
      },
    );

    test(
      'Completion handles exceptions thrown by userStatsProvider gracefully',
      () async {
        mockUserStats.throwOnSave = true;
        final notifier = container.read(
          quizSessionNotifierProvider('test_quiz_id').notifier,
        );
        notifier.startQuiz(mockQuiz);
        final displayedQ = notifier.displayedQuestion(mockQuiz);
        notifier.selectAnswer(displayedQ.correctIndex, displayedQ, mockQuiz);
        await expectLater(notifier.nextQuestion(mockQuiz), completes);
        final state = container.read(
          quizSessionNotifierProvider('test_quiz_id'),
        );
        expect(state.isQuizComplete, isTrue);
        expect(mockUserStats.starsAdded, isEmpty);
      },
    );

    test('concurrent and repeated completion pays once', () async {
      final notifier = container.read(
        quizSessionNotifierProvider('test_quiz_id').notifier,
      );
      notifier.startQuiz(mockQuiz);
      final question = notifier.displayedQuestion(mockQuiz);
      notifier.selectAnswer(question.correctIndex, question, mockQuiz);
      final gate = Completer<void>();
      mockUserStats.saveGate = gate;
      final first = notifier.nextQuestion(mockQuiz);
      await notifier.nextQuestion(mockQuiz);
      expect(mockUserStats.savedResults.length, 1);
      expect(mockUserStats.starsAdded, isEmpty);
      gate.complete();
      await first;
      await notifier.nextQuestion(mockQuiz);
      expect(mockUserStats.savedResults.length, 1);
      expect(mockUserStats.starsAdded, [5]);
      expect(mockQuizTakenToday.setCompletedCalls, 1);
    });

    test('an unanswered question cannot be completed', () async {
      final notifier = container.read(
        quizSessionNotifierProvider('test_quiz_id').notifier,
      );
      notifier.startQuiz(mockQuiz);
      await notifier.nextQuestion(mockQuiz);
      expect(mockUserStats.savedResults, isEmpty);
      expect(mockUserStats.starsAdded, isEmpty);
      expect(
        container.read(quizSessionNotifierProvider('test_quiz_id')).isQuizComplete,
        isFalse,
      );
    });

    test('reset during save does not change the earned reward', () async {
      final notifier = container.read(
        quizSessionNotifierProvider('test_quiz_id').notifier,
      );
      notifier.startQuiz(mockQuiz);
      final question = notifier.displayedQuestion(mockQuiz);
      notifier.selectAnswer(question.correctIndex, question, mockQuiz);
      final gate = Completer<void>();
      mockUserStats.saveGate = gate;
      final completion = notifier.nextQuestion(mockQuiz);
      notifier.reset();
      gate.complete();
      await completion;
      expect(mockUserStats.starsAdded, [5]);
      expect(
        container.read(quizSessionNotifierProvider('test_quiz_id')).hasStarted,
        isFalse,
      );
    });

    test('running out of hearts records progress but pays no stars', () async {
      final quiz = QuizModel(
        id: mockQuiz.id,
        categoryId: mockQuiz.categoryId,
        title: mockQuiz.title,
        questions: List.generate(4, (_) => mockQuiz.questions.single),
      );
      final notifier = container.read(
        quizSessionNotifierProvider('test_quiz_id').notifier,
      );
      notifier.startQuiz(quiz);
      for (var index = 0; index < 4; index++) {
        final question = notifier.displayedQuestion(quiz);
        final answer = index == 0
            ? question.correctIndex
            : (question.correctIndex + 1) % question.optionsLatin.length;
        notifier.selectAnswer(answer, question, quiz);
        if (index < 3) await notifier.nextQuestion(quiz);
      }
      await Future<void>.delayed(Duration.zero);
      await notifier.nextQuestion(quiz);
      expect(mockUserStats.savedResults.length, 1);
      expect(mockUserStats.savedResults.single.failedNoHearts, isTrue);
      expect(mockUserStats.savedResults.single.score, 1);
      expect(mockUserStats.starsAdded, isEmpty);
      expect(mockQuizTakenToday.setCompletedCalls, 0);
    });
  });
}
