import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/quiz/presentation/widgets/quiz_complete_mistakes_sheet.dart';
import 'package:itun/shared/models/content_models.dart';

QuizQuestion _question({required String prompt, required String answer}) =>
    QuizQuestion(
      promptOlChiki: 'ᱚ',
      promptLatin: prompt,
      optionsOlChiki: [answer, 'x', 'y', 'z'],
      optionsLatin: [answer, 'x', 'y', 'z'],
    );

void main() {
  late List<QuizQuestion> questions;

  setUp(() {
    questions = [
      _question(prompt: 'Sound of this?', answer: 'a'),
      _question(prompt: 'And this?', answer: 'ta'),
    ];
  });

  Future<void> openSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showQuizMistakesSheet(
                  context: context,
                  isDark: false,
                  incorrectQuestionIndices: const [1, 0],
                  questions: questions,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('lists every missed question with its correct answer', (
    tester,
  ) async {
    await openSheet(tester);

    expect(find.text('Review Mistakes'), findsOneWidget);
    expect(find.textContaining('build your mastery'), findsOneWidget);
    // Missed questions render in sheet order (1-based numbering).
    expect(find.text('1.'), findsOneWidget);
    expect(find.text('2.'), findsOneWidget);
    expect(find.text('And this?'), findsOneWidget);
    expect(find.text('Sound of this?'), findsOneWidget);
    expect(find.text('Correct:'), findsNWidgets(2));
    // The correct answer appears in both Ol Chiki and Latin renditions.
    expect(find.text('ta'), findsWidgets);
  });

  testWidgets('close button dismisses the sheet', (tester) async {
    await openSheet(tester);

    expect(find.text('Review Mistakes'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Review Mistakes'), findsNothing);
  });
}
