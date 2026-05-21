import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/lessons/presentation/practice/stroke_order_view.dart';
import 'package:itun/features/quiz/presentation/widgets/quiz_option_tile.dart';
import 'package:itun/features/quiz/presentation/widgets/quiz_question_card.dart';
import 'package:itun/shared/models/content_models.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(body: SizedBox(width: 420, height: 720, child: child)),
  );

  QuizQuestion question() => QuizQuestion(
    promptOlChiki: 'ᱚ',
    promptLatin: 'Which sound does this letter make?',
    optionsOlChiki: const ['ᱚ', 'ᱤ', 'ᱩ', 'ᱮ'],
    optionsLatin: const ['a', 'i', 'u', 'e'],
  );

  testWidgets('quiz question announces Ol Chiki prompt and question text', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(wrap(QuizQuestionCard(question: question())));
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(
          find.bySemanticsLabel(
            'Quiz question, Ol Chiki prompt ᱚ, Question text Which sound does this letter make?',
          ),
        ),
        matchesSemantics(
          label:
              'Quiz question, Ol Chiki prompt ᱚ, Question text Which sound does this letter make?',
        ),
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('quiz option exposes button, selected, and correctness state', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        wrap(
          QuizOptionTile(
            index: 0,
            currentQuestion: 0,
            question: question(),
            isSelected: true,
            isAnswered: true,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(
          find.bySemanticsLabel('Answer A, a, selected, correct'),
        ),
        matchesSemantics(
          label: 'Answer A, a, selected, correct',
          isButton: true,
          isSelected: true,
          hasEnabledState: true,
          hasSelectedState: true,
        ),
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('stroke order board has an image label for screen readers', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(wrap(const StrokeOrderView(letterChar: 'ᱚ')));
      await tester.pump(const Duration(milliseconds: 1000));

      expect(
        tester.getSemantics(
          find.bySemanticsLabel(
            'Stroke order animation for Ol Chiki character ᱚ',
          ),
        ),
        matchesSemantics(
          label: 'Stroke order animation for Ol Chiki character ᱚ',
          isImage: true,
        ),
      );
    } finally {
      semantics.dispose();
    }
  });
}
