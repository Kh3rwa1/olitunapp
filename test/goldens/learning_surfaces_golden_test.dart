import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/lessons/presentation/practice/stroke_order_view.dart';
import 'package:itun/features/quiz/presentation/widgets/quiz_option_tile.dart';
import 'package:itun/features/quiz/presentation/widgets/quiz_question_card.dart';
import 'package:itun/shared/models/content_models.dart';

void main() {
  Widget surface(Widget child, {Size size = const Size(420, 720)}) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        body: Center(
          child: SizedBox(width: size.width, height: size.height, child: child),
        ),
      ),
    );
  }

  QuizQuestion question() => QuizQuestion(
    promptOlChiki: 'ᱚ',
    promptLatin: 'Which sound does this letter make?',
    optionsOlChiki: const ['ᱚ', 'ᱤ', 'ᱩ', 'ᱮ'],
    optionsLatin: const ['a', 'i', 'u', 'e'],
  );

  testWidgets('quiz question card golden', (tester) async {
    await tester.pumpWidget(
      surface(
        Padding(
          padding: const EdgeInsets.all(24),
          child: QuizQuestionCard(question: question()),
        ),
        size: const Size(420, 260),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('quiz_question_card.png'),
    );
  });

  testWidgets('answered quiz option golden', (tester) async {
    await tester.pumpWidget(
      surface(
        Padding(
          padding: const EdgeInsets.all(24),
          child: QuizOptionTile(
            index: 0,
            currentQuestion: 0,
            question: question(),
            isSelected: true,
            isAnswered: true,
            onTap: () {},
          ),
        ),
        size: const Size(420, 160),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('quiz_option_answered.png'),
    );
  });

  testWidgets('stroke order view golden', (tester) async {
    await tester.pumpWidget(surface(const StrokeOrderView(letterChar: 'ᱚ')));
    await tester.pump(const Duration(milliseconds: 1200));

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('stroke_order_view.png'),
    );
  });
}
