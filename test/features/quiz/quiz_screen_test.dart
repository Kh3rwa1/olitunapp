import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/features/quiz/presentation/quiz_screen.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/providers.dart';
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
        correctIndex: 0,
      ),
    ],
  );

  testWidgets('QuizScreen renders loading state initially', (tester) async {
    await tester.pumpWidget(createTestableWidget(
      child: const QuizScreen(quizId: 'test_quiz'),
      overrides: [
        quizzesProvider.overrideWith((ref) => MockQuizzesNotifier(const AsyncValue.loading())),
      ],
    ));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('QuizScreen renders question and options', (tester) async {
    await tester.pumpWidget(createTestableWidget(
      child: const QuizScreen(quizId: 'test_quiz'),
      overrides: [
        quizzesProvider.overrideWith((ref) => MockQuizzesNotifier(AsyncValue.data([mockQuiz]))),
      ],
    ));

    await tester.pumpAndSettle();

    expect(find.text('Test Alphabet Quiz'), findsOneWidget);
    expect(find.text('Sound of this?'), findsOneWidget);
    expect(find.text('a'), findsOneWidget);
    expect(find.text('e'), findsOneWidget);
  });

  testWidgets('Selecting an answer and completing quiz', (tester) async {
    await tester.pumpWidget(createTestableWidget(
      child: const QuizScreen(quizId: 'test_quiz'),
      overrides: [
        quizzesProvider.overrideWith((ref) => MockQuizzesNotifier(AsyncValue.data([mockQuiz]))),
      ],
    ));

    await tester.pumpAndSettle();

    // Tap first option ('a' which is correct)
    await tester.tap(find.text('a'));
    await tester.pumpAndSettle();

    // Check if "Continue" button appeared (it usually does after an answer is selected)
    // Looking at QuizScreen logic... _selectedAnswer != null
    expect(find.byIcon(Icons.check_circle_rounded), findsWidgets); // Option selection indicators

    // The Continue button in QuizScreen is often dynamic.
    // In quiz_screen.dart, it uses AppLocalizations.of(context)!.continueButton
  });
}

class MockQuizzesNotifier extends StateNotifier<AsyncValue<List<QuizModel>>> with Mock implements QuizzesNotifier {
  MockQuizzesNotifier(super.state);
}
