import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/quiz/domain/lesson_quiz_generator.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';

void main() {
  group('LessonQuizGenerator Coverage Tests', () {
    test('generate creates valid QuizModel from lesson with blocks', () {
      const lesson = LessonEntity(
        id: 'lesson_101',
        categoryId: 'cat_alphabet_basics',
        titleLatin: 'Basic Letters',
        titleOlChiki: 'ᱚᱞ ᱪᱤᱠᱤ',
        blocks: [
          LessonBlockEntity(
            type: 'letter',
            textOlChiki: 'ᱚ',
            textLatin: 'LA',
          ),
          LessonBlockEntity(
            type: 'letter',
            textOlChiki: 'ᱛ',
            textLatin: 'AT',
          ),
        ],
      );

      final quiz = LessonQuizGenerator.generate(lesson);
      expect(quiz.id, 'dynamic_quiz_lesson_101');
      expect(quiz.categoryId, 'cat_alphabet_basics');
      expect(quiz.questions, isNotEmpty);
      expect(quiz.questions.first.promptOlChiki, isNotNull);
    });

    test('generate fallback question when lesson has no text blocks', () {
      const lesson = LessonEntity(
        id: 'lesson_empty',
        categoryId: 'cat_numbers',
        titleLatin: 'Numbers Lesson',
        titleOlChiki: 'ᱮᱞ',
      );

      final quiz = LessonQuizGenerator.generate(lesson);
      expect(quiz.id, 'dynamic_quiz_lesson_empty');
      expect(quiz.questions.length, 1);
      expect(quiz.questions.first.promptOlChiki, 'ᱮᱞ');
    });
  });
}
