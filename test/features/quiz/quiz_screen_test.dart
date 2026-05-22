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
            (ref) => MockQuizzesNotifier(const AsyncValue.loading()),
          ),
          userStatsProvider.overrideWith(
            (ref) => MockUserStatsNotifier(const AsyncValue.data(mockStats)),
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
            (ref) => MockQuizzesNotifier(AsyncValue.data([mockQuiz])),
          ),
          userStatsProvider.overrideWith(
            (ref) => MockUserStatsNotifier(const AsyncValue.data(mockStats)),
          ),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Test Alphabet Quiz'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('x1'), findsOneWidget);
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
            (ref) => MockQuizzesNotifier(AsyncValue.data([mockQuiz])),
          ),
          userStatsProvider.overrideWith(
            (ref) => MockUserStatsNotifier(const AsyncValue.data(mockStats)),
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
            (ref) => MockQuizzesNotifier(AsyncValue.data([mockQuiz])),
          ),
          userStatsProvider.overrideWith(
            (ref) => MockUserStatsNotifier(const AsyncValue.data(mockStats)),
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

class MockQuizzesNotifier extends StateNotifier<AsyncValue<List<QuizModel>>>
    with Mock
    implements QuizzesNotifier {
  MockQuizzesNotifier(super.state);
}

class MockUserStatsNotifier extends StateNotifier<AsyncValue<UserStatsEntity>>
    with Mock
    implements UserStatsNotifier {
  MockUserStatsNotifier(super.state);

  @override
  Future<void> saveQuizResult(QuizResultEntity result) async {}
  @override
  Future<void> addStars(int count) async {}
}
