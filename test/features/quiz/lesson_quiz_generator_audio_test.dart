import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/features/quiz/domain/lesson_quiz_generator.dart';

void main() {
  group('LessonQuizGenerator Audio & Distractor Tests', () {
    test(
      'propagates audioUrl from lesson blocks into generated quiz questions',
      () {
        const lesson = LessonEntity(
          id: 'lesson_family_1',
          titleLatin: 'Family Members',
          titleOlChiki: 'ᱜᱷᱟᱨᱚᱸᱡᱽ',
          categoryId: 'vocabulary',
          order: 1,
          blocks: [
            LessonBlockEntity(
              type: 'word',
              textOlChiki: 'ᱵᱟᱵᱟ',
              textLatin: 'Baba – Father',
              audioUrl: 'https://example.com/audio/baba.mp3',
            ),
            LessonBlockEntity(
              type: 'word',
              textOlChiki: 'ᱟᱭᱳ',
              textLatin: 'Ayo – Mother',
              audioUrl: 'https://example.com/audio/ayo.mp3',
            ),
          ],
        );

        final quiz = LessonQuizGenerator.generate(lesson);

        expect(quiz.questions, isNotEmpty);
        expect(
          quiz.questions.first.audioUrl,
          'https://example.com/audio/baba.mp3',
        );
        expect(quiz.questions.first.promptOlChiki, 'ᱵᱟᱵᱟ');
        expect(quiz.questions.first.optionsLatin, contains('Baba – Father'));
      },
    );
  });
}
