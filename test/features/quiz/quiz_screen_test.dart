import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/quiz/presentation/quiz_screen.dart';
import 'package:itun/features/quiz/presentation/widgets/quiz_option_tile.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/providers.dart';
import 'package:itun/shared/widgets/state_widgets.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';
import 'package:itun/features/quiz/presentation/providers/mistake_provider.dart';
import 'package:itun/core/analytics/analytics_service.dart';
import 'package:mocktail/mocktail.dart';
import '../../test_utils.dart';

void main() {
  late SharedPreferences mockPrefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockPrefs = await SharedPreferences.getInstance();
  });

  final mockQuiz = QuizModel(
    id: 'test_quiz',
    categoryId: 'alphabets',
    title: 'Test Alphabet Quiz',
    questions: [
      QuizQuestion(
        promptOlChiki: 'ᱚ',
        promptLatin: 'Sound of this?',
        optionsOlChiki: ['a', 'e', 'i', 'o'],
        optionsLatin: ['a', 'e', 'i', 'o'],
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

  testWidgets('QuizScreen renders loading state initially', (tester) async {
    await tester.pumpWidget(
      createTestableWidget(
        child: const QuizScreen(quizId: 'test_quiz'),
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockPrefs),
          quizzesProvider.overrideWith(
            () => MockQuizzesNotifier(const AsyncValue.loading()),
          ),
          userStatsProvider.overrideWith(
            () => MockUserStatsNotifier(const AsyncValue.data(mockStats)),
          ),
          mistakeProvider.overrideWith(() => MockMistakeNotifier([])),
          learningAnalyticsServiceProvider.overrideWithValue(
            MockLearningAnalyticsService(),
          ),
        ],
      ),
    );

    expect(find.byType(AppLoadingState), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('QuizScreen renders question and options', (tester) async {
    await tester.pumpWidget(
      createTestableWidget(
        child: const QuizScreen(quizId: 'test_quiz'),
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockPrefs),
          quizzesProvider.overrideWith(
            () => MockQuizzesNotifier(AsyncValue.data([mockQuiz])),
          ),
          userStatsProvider.overrideWith(
            () => MockUserStatsNotifier(const AsyncValue.data(mockStats)),
          ),
          mistakeProvider.overrideWith(() => MockMistakeNotifier([])),
          learningAnalyticsServiceProvider.overrideWithValue(
            MockLearningAnalyticsService(),
          ),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Test Alphabet Quiz'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('0'), findsNothing);
    expect(find.text('x1'), findsNothing);
    expect(find.text('Sound of this?'), findsOneWidget);
    expect(find.text('a'), findsOneWidget);
    expect(find.text('e'), findsOneWidget);
  });

  testWidgets('Selecting an answer and completing quiz', (tester) async {
    // Set standard mobile screen dimensions
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      createTestableWidget(
        child: const QuizScreen(quizId: 'test_quiz'),
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockPrefs),
          quizzesProvider.overrideWith(
            () => MockQuizzesNotifier(AsyncValue.data([mockQuiz])),
          ),
          userStatsProvider.overrideWith(
            () => MockUserStatsNotifier(const AsyncValue.data(mockStats)),
          ),
          mistakeProvider.overrideWith(() => MockMistakeNotifier([])),
          learningAnalyticsServiceProvider.overrideWithValue(
            MockLearningAnalyticsService(),
          ),
        ],
      ),
    );

    await tester.pumpAndSettle();

    // Tap first option ('a' which is correct)
    await tester.tap(find.text('a'));

    // Check if correct indicator appears
    await tester.pump();
    expect(
      find.descendant(
        of: find.byType(QuizOptionTile),
        matching: find.byIcon(Icons.check_circle_rounded),
      ),
      findsOneWidget,
    );
    expect(find.text('1'), findsWidgets);

    // Let the feedback panel finish animating into view
    await tester.pumpAndSettle();

    // Tap the 'Continue' button on the feedback panel to advance
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Now it should be on the completion screen
    expect(find.text('100%'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
  });

  testWidgets('shows mistake review after failed quiz', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      createTestableWidget(
        child: const QuizScreen(quizId: 'test_quiz'),
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockPrefs),
          quizzesProvider.overrideWith(
            () => MockQuizzesNotifier(AsyncValue.data([mockQuiz])),
          ),
          userStatsProvider.overrideWith(
            () => MockUserStatsNotifier(const AsyncValue.data(mockStats)),
          ),
          mistakeProvider.overrideWith(() => MockMistakeNotifier([])),
          learningAnalyticsServiceProvider.overrideWithValue(
            MockLearningAnalyticsService(),
          ),
        ],
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('e'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('0%'), findsOneWidget);
    expect(find.text('MISTAKE REVIEW'), findsOneWidget);
    expect(find.text('1 word needs practice'), findsOneWidget);
    expect(find.text('Review Mistakes'), findsOneWidget);
  });
}

class MockQuizzesNotifier extends QuizzesNotifier {
  final AsyncValue<List<QuizModel>> _initial;

  MockQuizzesNotifier(this._initial);

  @override
  AsyncValue<List<QuizModel>> build() => _initial;
}

class MockUserStatsNotifier extends UserStatsNotifier {
  final AsyncValue<UserStatsEntity> _initial;

  MockUserStatsNotifier(this._initial);

  @override
  AsyncValue<UserStatsEntity> build() => _initial;

  @override
  Future<void> saveQuizResult(QuizResultEntity result) async {}
  @override
  Future<void> addStars(int count) async {}
}

class MockMistakeNotifier extends MistakeNotifier {
  final List<MistakeItem> _initial;

  MockMistakeNotifier(this._initial);

  @override
  List<MistakeItem> build() => _initial;

  @override
  Future<void> recordMistake({
    required String quizId,
    required int questionIndex,
    required QuizQuestion question,
    String? wrongAnswer,
  }) async {}

  @override
  Future<void> masterMistake({
    required String quizId,
    required int questionIndex,
  }) async {}

  @override
  Future<void> syncFromBackend() async {}
}

class MockLearningAnalyticsService extends Mock
    implements LearningAnalyticsService {
  @override
  Future<void> track(
    String eventName, {
    String? source,
    String? sourceId,
    Map<String, dynamic> metadata = const {},
    String? learnerLevel,
    String? scriptMode,
  }) async {}
}
