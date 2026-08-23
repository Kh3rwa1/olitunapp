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

  MockUserStatsNotifier(this._initial);

  @override
  AsyncValue<UserStatsEntity> build() => _initial;

  @override
  Future<void> saveQuizResult(QuizResultEntity result) async {
    if (throwOnSave) throw Exception('Appwrite offline error');
    savedResults.add(result);
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

        // Select answer for the single question
        final displayedQ = notifier.displayedQuestion(mockQuiz);
        notifier.selectAnswer(displayedQ.correctIndex, displayedQ, mockQuiz);

        // Complete the quiz
        await notifier.nextQuestion(mockQuiz);

        final state = container.read(
          quizSessionNotifierProvider('test_quiz_id'),
        );
        expect(state.isQuizComplete, isTrue);

        // Verify we saved result and added stars
        expect(mockUserStats.savedResults.length, 1);
        expect(mockUserStats.starsAdded, [(1 * 5) + 0]);
        expect(mockQuizTakenToday.setCompletedCalls, 1);
      },
    );

    test(
      'Completion handles exceptions thrown by userStatsProvider gracefully',
      () async {
        // Configure mockUserStats to throw an exception when saving quiz result
        mockUserStats.throwOnSave = true;

        final notifier = container.read(
          quizSessionNotifierProvider('test_quiz_id').notifier,
        );
        notifier.startQuiz(mockQuiz);

        final displayedQ = notifier.displayedQuestion(mockQuiz);
        notifier.selectAnswer(displayedQ.correctIndex, displayedQ, mockQuiz);

        // Trigger nextQuestion which completes the quiz and persists.
        // This should run without throwing because we wrapped it in a try-catch.
        await expectLater(notifier.nextQuestion(mockQuiz), completes);

        final state = container.read(
          quizSessionNotifierProvider('test_quiz_id'),
        );
        expect(state.isQuizComplete, isTrue);
      },
    );
  });
}
