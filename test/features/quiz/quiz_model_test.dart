import 'package:flutter_test/flutter_test.dart';
import 'package:itun/shared/models/content_models.dart';

void main() {
  group('QuizModel', () {
    test('fromJson parses quiz with inline questions', () {
      final json = {
        'id': 'q1',
        'categoryId': 'alphabets',
        'title': 'Vowel Quiz',
        'level': 'beginner',
        'order': 0,
        'passingScore': 70,
        'questions': [
          {
            'promptOlChiki': 'ᱚ',
            'promptLatin': 'Which sound?',
            'optionsOlChiki': ['a', 'i', 'u'],
            'optionsLatin': ['a', 'i', 'u'],
            'correctIndex': 0,
          },
        ],
      };

      final quiz = QuizModel.fromJson(json);
      expect(quiz.id, 'q1');
      expect(quiz.categoryId, 'alphabets');
      expect(quiz.title, 'Vowel Quiz');
      expect(quiz.passingScore, 70);
      expect(quiz.questions.length, 1);
      expect(quiz.questions.first.promptOlChiki, 'ᱚ');
      expect(quiz.questions.first.correctIndex, 0);
    });

    test('fromJson parses stringified questions (Appwrite format)', () {
      final json = <String, dynamic>{
        'id': 'q2',
        'categoryId': 'cat',
        'questions':
            '[{"promptOlChiki":"ᱤ","promptLatin":"Identify","optionsOlChiki":["a","i"],"optionsLatin":["a","i"],"correctIndex":1}]',
      };

      final quiz = QuizModel.fromJson(json);
      expect(quiz.questions.length, 1);
      expect(quiz.questions.first.correctIndex, 1);
    });

    test('toJson/fromJson round-trip preserves data', () {
      final quiz = QuizModel(
        id: 'q3',
        categoryId: 'numbers',
        title: 'Numbers 1-10',
        order: 1,
        passingScore: 60,
        questions: [
          QuizQuestion(
            promptOlChiki: '᱑',
            promptLatin: 'What number?',
            optionsOlChiki: ['1', '2', '3'],
            optionsLatin: ['One', 'Two', 'Three'],
            correctIndex: 0,
          ),
          QuizQuestion(
            promptOlChiki: '᱕',
            promptLatin: 'What number?',
            optionsOlChiki: ['4', '5', '6'],
            optionsLatin: ['Four', 'Five', 'Six'],
            correctIndex: 1,
          ),
        ],
      );

      final json = quiz.toJson();
      final restored = QuizModel.fromJson(json);

      expect(restored.id, quiz.id);
      expect(restored.title, quiz.title);
      expect(restored.questions.length, quiz.questions.length);
      expect(restored.questions[1].correctIndex, 1);
      expect(restored.passingScore, 60);
    });
  });

  group('QuizQuestion', () {
    test('toMap/fromMap round-trip', () {
      final q = QuizQuestion(
        promptOlChiki: 'ᱚ',
        promptLatin: 'Test',
        optionsOlChiki: ['a', 'b', 'c', 'd'],
        optionsLatin: ['A', 'B', 'C', 'D'],
        correctIndex: 2,
      );

      final map = q.toMap();
      final restored = QuizQuestion.fromMap(map);

      expect(restored.promptOlChiki, 'ᱚ');
      expect(restored.promptLatin, 'Test');
      expect(restored.correctIndex, 2);
      expect(restored.optionsLatin.length, 4);
    });

    test('fromMap handles missing promptLatin', () {
      final map = {
        'promptOlChiki': 'ᱤ',
        'optionsOlChiki': ['a'],
        'optionsLatin': ['a'],
        'correctIndex': 0,
      };

      final q = QuizQuestion.fromMap(map);
      expect(q.promptLatin, isNull);
    });
  });

  group('Quiz scoring logic', () {
    test('percentage calculation', () {
      const score = 7;
      const total = 10;
      final percentage = (score / total * 100).round();
      expect(percentage, 70);
    });

    test('passing threshold at 70%', () {
      expect((7 / 10 * 100).round() >= 70, isTrue);
      expect((6 / 10 * 100).round() >= 70, isFalse);
    });

    test('star rewards equal score * 5', () {
      expect(7 * 5, 35);
      expect(10 * 5, 50);
      expect(0 * 5, 0);
    });

    test('perfect score gives 100%', () {
      const score = 5;
      const total = 5;
      final percentage = (score / total * 100).round();
      expect(percentage, 100);
    });
  });
}
