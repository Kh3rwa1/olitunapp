import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/lessons/data/models/lesson_model.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/features/quiz/domain/lesson_quiz_generator.dart';
import 'package:itun/shared/models/content/quiz_model.dart';

/// Content-validation gate for bundled sentence lessons: runs the real
/// [LessonQuizGenerator] over every lesson in
/// assets/seed/sentence_lessons.json.
///
/// Pins the honest fail-closed contract:
/// * "Modern Conversational Exchanges III" generates real Hindi sentence
///   questions from `data.meaning_hi`;
/// * no lesson in any teaching language produces a lesson-title question;
/// * every generated multiple-choice question is well-formed;
/// * the known thin-content lessons are exactly the four grammar lessons
///   documented in docs/audits/sentence_quiz_generation_audit.md.
Future<List<LessonEntity>> _loadSeedLessons() async {
  final raw =
      jsonDecode(
            await rootBundle.loadString('assets/seed/sentence_lessons.json'),
          )
          as List<dynamic>;
  return raw
      .cast<Map<String, dynamic>>()
      .map(LessonModel.fromJson)
      .map((m) => m.toEntity())
      .toList();
}

void _expectWellFormed(List<QuizQuestion> questions) {
  final prompts = <String>{};
  for (final q in questions) {
    expect(q.optionsLatin, hasLength(4));
    expect(q.optionsLatin.toSet(), hasLength(4));
    expect(q.optionsLatin.every((o) => o.trim().isNotEmpty), isTrue);
    expect(q.correctIndex, inInclusiveRange(0, 3));
    expect(q.promptLatin ?? '', isNot(contains('title for this lesson')));
    expect(prompts.add(q.promptOlChiki), isTrue, reason: 'duplicate prompt');
  }
}

void main() {
  test('conversational III generates real Hindi sentence questions', () async {
    final lessons = await _loadSeedLessons();
    final lesson = lessons.firstWhere(
      (l) => l.id == 'lesson_sentences_conversational_3',
    );

    final result = LessonQuizGenerator.generateResult(
      lesson,
      teachingLanguage: 'hi',
    );

    expect(result.isSuccess, isTrue);
    expect(result.quiz.questions.length, greaterThanOrEqualTo(5));
    for (final q in result.quiz.questions) {
      expect(q.promptLatin, 'Choose the correct Hindi meaning:');
    }
    expect(
      result.quiz.questions.map((q) => q.optionsLatin[q.correctIndex]).toSet(),
      contains('क्या आप आज देश की यात्रा पर जा रहे हैं?'),
    );
    _expectWellFormed(result.quiz.questions);
  });

  test(
    'no seed lesson yields a title-fallback question in any language',
    () async {
      final lessons = await _loadSeedLessons();
      expect(lessons, hasLength(23));
      for (final lesson in lessons) {
        for (final lang in ['en', 'hi', 'bn', 'or']) {
          final quiz = LessonQuizGenerator.generate(
            lesson,
            teachingLanguage: lang,
          );
          for (final q in quiz.questions) {
            expect(
              q.promptLatin ?? '',
              isNot(contains('title for this lesson')),
              reason: '${lesson.id} [$lang]',
            );
          }
          _expectWellFormed(quiz.questions);
        }
      }
    },
  );

  test('exactly the four thin grammar lessons generate fewer than five '
      'Hindi questions', () async {
    final lessons = await _loadSeedLessons();
    final thin = <String>[];
    for (final lesson in lessons) {
      final quiz = LessonQuizGenerator.generate(lesson, teachingLanguage: 'hi');
      if (quiz.questions.length < 5) thin.add(lesson.id);
    }
    expect(
      thin,
      unorderedEquals([
        'lesson_grammar_verb_tenses',
        'lesson_grammar_possessives',
        'lesson_grammar_plurals_numbers',
        'lesson_grammar_conjunctions',
      ]),
    );
  });
}
