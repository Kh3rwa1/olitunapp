import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/features/quiz/domain/listening_quiz_generator.dart';
import 'package:itun/shared/models/content_models.dart';

void main() {
  group('ListeningQuizGenerator', () {
    const lesson = LessonEntity(
      id: 'lesson_greetings',
      categoryId: 'cat_phrases',
      titleOlChiki: 'ᱡᱚᱦᱟᱨ',
      titleLatin: 'Greetings',
      blocks: [
        LessonBlockEntity(
          type: 'word',
          textOlChiki: 'ᱡᱚᱦᱟᱨ',
          textLatin: 'Hello',
          audioUrl: 'https://example.com/hello.mp3',
        ),
        LessonBlockEntity(
          type: 'word',
          textOlChiki: 'ᱥᱮᱢᱮᱫ',
          textLatin: 'Thank you',
          audioUrl: 'https://example.com/thanks.mp3',
        ),
        // No audio — must be excluded (spec §14 line 680).
        LessonBlockEntity(
          type: 'word',
          textOlChiki: 'ᱢᱚᱱᱰᱤ',
          textLatin: 'Water',
        ),
        // Audio but no text — also unusable.
        LessonBlockEntity(
          type: 'word',
          audioUrl: 'https://example.com/empty.mp3',
        ),
        // Quiz block — never a question source.
        LessonBlockEntity(
          type: 'quiz',
          textOlChiki: '',
          textLatin: '',
          data: {'quizId': 'dynamic_quiz_lesson_greetings'},
        ),
      ],
    );

    test('canGenerate is true when a block has audio and text', () {
      expect(ListeningQuizGenerator.canGenerate(lesson), isTrue);
    });

    test('canGenerate is false when no block has usable audio', () {
      const audioless = LessonEntity(
        id: 'lesson_no_audio',
        categoryId: 'cat_vocab',
        titleOlChiki: 'ᱯᱟᱲᱟ',
        titleLatin: 'Words',
      );
      expect(ListeningQuizGenerator.canGenerate(audioless), isFalse);
    });

    test('generate builds a listening quiz from audio-bearing blocks only', () {
      final quiz = ListeningQuizGenerator.generate(lesson);

      expect(quiz.id, 'listening_quiz_lesson_greetings');
      expect(quiz.title, 'Greetings Listening Quiz');
      expect(quiz.categoryId, 'cat_phrases');
      expect(quiz.questions, hasLength(2));

      for (final question in quiz.questions) {
        expect(question.type, 'listen_meaning');
        expect(question.audioUrl, isNotNull);
        expect(
          question.audioUrl,
          anyOf(
            'https://example.com/hello.mp3',
            'https://example.com/thanks.mp3',
          ),
        );
        expect(question.optionsLatin, hasLength(4));
        expect(question.optionsOlChiki, hasLength(4));
        expect(
          question.optionsLatin[question.correctIndex],
          question.audioUrl == 'https://example.com/hello.mp3'
              ? 'Hello'
              : 'Thank you',
        );
      }

      // The excluded blocks must not appear as prompts or correct answers.
      expect(
        quiz.questions.map((q) => q.optionsLatin[q.correctIndex]),
        isNot(contains('Water')),
      );
    });

    test('generate returns an empty quiz for a lesson without audio', () {
      const audioless = LessonEntity(
        id: 'lesson_no_audio',
        categoryId: 'cat_vocab',
        titleOlChiki: 'ᱯᱟᱲᱟ',
        titleLatin: 'Words',
      );
      final quiz = ListeningQuizGenerator.generate(audioless);
      expect(quiz.questions, isEmpty);
    });

    test('generated questions round-trip through QuizQuestion.toMap', () {
      final quiz = ListeningQuizGenerator.generate(lesson);
      for (final question in quiz.questions) {
        final restored = QuizQuestion.fromMap(question.toMap());
        expect(restored.type, 'listen_meaning');
        expect(restored.audioUrl, question.audioUrl);
        expect(restored.correctIndex, question.correctIndex);
      }
    });
  });
}
