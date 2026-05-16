import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/features/quiz/presentation/quiz_screen.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/providers.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';
import 'package:mocktail/mocktail.dart';
import '../../test_utils.dart';

void main() {
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
          quizzesProvider.overrideWith(
            (ref) => MockQuizzesNotifier(const AsyncValue.loading()),
          ),
          userStatsProvider.overrideWith(
            (ref) => MockUserStatsNotifier(const AsyncValue.data(mockStats)),
          ),
        ],
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('QuizScreen renders question and options', (tester) async {
    await tester.pumpWidget(
      createTestableWidget(
        child: const QuizScreen(quizId: 'test_quiz'),
        overrides: [
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
    expect(find.text('Sound of this?'), findsOneWidget);
    expect(find.text('a'), findsOneWidget);
    expect(find.text('e'), findsOneWidget);
  });

  testWidgets('Selecting an answer and completing quiz', (tester) async {
    await tester.pumpWidget(
      createTestableWidget(
        child: const QuizScreen(quizId: 'test_quiz'),
        overrides: [
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
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    // Wait for the auto-advance delay (1.2 seconds)
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    // Now it should be on the completion screen
    expect(find.text('100%'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
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
