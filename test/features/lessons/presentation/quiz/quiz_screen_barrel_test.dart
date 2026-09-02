import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// Exercised through the lessons quiz compatibility barrel on purpose: the
// barrel must keep re-exporting the real QuizScreen implementation.
import 'package:itun/features/lessons/presentation/quiz/quiz_screen.dart';

void main() {
  group('lessons quiz_screen barrel re-export', () {
    test('exports a constructible QuizScreen widget type', () {
      const screen = QuizScreen();

      expect(screen, isA<QuizScreen>());
      expect(screen.quizId, isNull);
    });

    test('forwards the optional quizId through the constructor', () {
      const screen = QuizScreen(quizId: 'quiz-42');

      expect(screen.quizId, 'quiz-42');
    });

    test('QuizScreen is a ConsumerStatefulWidget', () {
      const screen = QuizScreen(quizId: 'quiz-7');

      expect(screen, isA<ConsumerStatefulWidget>());
      expect(screen.key, isNull);
    });
  });
}
