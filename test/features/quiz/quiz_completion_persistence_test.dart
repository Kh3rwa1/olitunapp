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
        notifier.nextQuestion(mockQuiz);

        final state = container.read(
          quizSessionNotifierProvider('test_quiz_id'),
        );
        expect(state.isQuizComplete, isTrue);

        // Verify we saved result and added stars
        verify(() => mockUserStats.saveQuizResult(any())).called(1);
        verify(() => mockUserStats.addStars((1 * 5) + 0)).called(1);
        verify(() => mockQuizTakenToday.setCompleted(true)).called(1);
      },
    );

    test(
      'Completion handles exceptions thrown by userStatsProvider gracefully',
      () {
        // Configure mockUserStats to throw an exception when saving quiz result
        when(
          () => mockUserStats.saveQuizResult(any()),
        ).thenThrow(Exception('Appwrite offline error'));

        final notifier = container.read(
          quizSessionNotifierProvider('test_quiz_id').notifier,
        );
        notifier.startQuiz(mockQuiz);

        final displayedQ = notifier.displayedQuestion(mockQuiz);
        notifier.selectAnswer(displayedQ.correctIndex, displayedQ, mockQuiz);

        // Trigger nextQuestion which completes the quiz and persists.
        // This should run without throwing because we wrapped it in a try-catch.
        expect(() => notifier.nextQuestion(mockQuiz), returnsNormally);

        final state = container.read(
          quizSessionNotifierProvider('test_quiz_id'),
        );
        expect(state.isQuizComplete, isTrue);
      },
    );
  });
}
