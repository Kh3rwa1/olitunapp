import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/quiz/presentation/widgets/quiz_list_cards.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/providers.dart';

QuizModel _quiz({String level = 'beginner'}) => QuizModel(
  id: 'quiz-1',
  categoryId: 'alphabets',
  title: 'Alphabet Basics',
  level: level,
  questions: [
    QuizQuestion(
      promptOlChiki: 'ᱚ',
      promptLatin: 'Sound of this?',
      optionsOlChiki: ['a', 'e', 'i', 'o'],
      optionsLatin: ['a', 'e', 'i', 'o'],
    ),
    QuizQuestion(
      promptOlChiki: 'ᱛ',
      promptLatin: 'And this?',
      optionsOlChiki: ['ta', 'ka', 'pa', 'na'],
      optionsLatin: ['ta', 'ka', 'pa', 'na'],
    ),
  ],
);

Widget _wrap(Widget child, {bool reduceEffects = true}) => ProviderScope(
  overrides: [reduceVisualEffectsProvider.overrideWithValue(reduceEffects)],
  child: MaterialApp(home: Scaffold(body: child)),
);

void main() {
  testWidgets('HeroQuizCard renders title, level emoji and question count', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(HeroQuizCard(quiz: _quiz(), isDark: false)));
    await tester.pumpAndSettle();

    expect(find.text('Alphabet Basics'), findsOneWidget);
    expect(find.text('2 questions • beginner'), findsOneWidget);
    expect(find.text('⭐'), findsOneWidget);
    expect(find.text('START QUIZ'), findsOneWidget);
  });

  testWidgets('HeroQuizCard maps level to stacked stars', (tester) async {
    await tester.pumpWidget(
      _wrap(HeroQuizCard(quiz: _quiz(level: 'advanced'), isDark: true)),
    );
    await tester.pumpAndSettle();

    expect(find.text('⭐⭐⭐'), findsOneWidget);
    expect(find.text('2 questions • advanced'), findsOneWidget);
  });

  testWidgets('BentoQuizCard renders title, meta and level for its index', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        SizedBox(
          height: 200,
          width: 200,
          child: BentoQuizCard(quiz: _quiz(), index: 1, isDark: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alphabet Basics'), findsOneWidget);
    expect(find.text('2 questions'), findsOneWidget);
    expect(find.text('⭐'), findsOneWidget);
    expect(find.byIcon(Icons.numbers_rounded), findsOneWidget);
  });

  testWidgets(
    'BentoQuizCard falls back to a numbered title for unnamed quizzes',
    (tester) async {
      final untitled = QuizModel(id: 'quiz-2', categoryId: 'alphabets');
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            height: 200,
            width: 200,
            child: BentoQuizCard(quiz: untitled, index: 2, isDark: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quiz 4'), findsOneWidget);
      expect(find.text('0 questions'), findsOneWidget);
      expect(find.byIcon(Icons.spellcheck_rounded), findsOneWidget);
    },
  );
}
