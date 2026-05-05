import 'package:flutter_test/flutter_test.dart';
import 'package:itun/shared/models/content_models.dart';

void main() {
  group('CategoryModel', () {
    test('fromJson → toJson roundtrip', () {
      final json = {
        'id': 'cat_1',
        'titleOlChiki': 'ᱚᱞ ᱪᱤᱠᱤ',
        'titleLatin': 'Alphabet',
        'iconName': 'abc',
        'gradientPreset': 'skyBlue',
        'order': 0,
        'totalLessons': 6,
        'description': 'Learn letters',
        'isActive': true,
      };
      final model = CategoryModel.fromJson(json);
      expect(model.id, 'cat_1');
      expect(model.titleLatin, 'Alphabet');
      expect(model.order, 0);

      final output = model.toJson();
      expect(output['titleOlChiki'], 'ᱚᱞ ᱪᱤᱠᱤ');
    });

    test('backward compat: titleEn maps to titleLatin', () {
      final json = {
        'id': 'cat_2',
        'titleOlChiki': 'ᱮᱞᱠᱷᱟ',
        'titleLatin': 'Numbers',
        'iconName': 'pin',
        'gradientPreset': 'sunset',
        'order': 1,
      };
      final model = CategoryModel.fromJson(json);
      expect(model.titleEn, model.titleLatin);
    });
  });

  group('LetterModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'ᱚ',
        'charOlChiki': 'ᱚ',
        'transliterationLatin': 'La',
        'pronunciation': 'o',
        'order': 0,
        'isActive': true,
      };
      final model = LetterModel.fromJson(json);
      expect(model.charOlChiki, 'ᱚ');
      expect(model.transliterationLatin, 'La');
    });
  });

  group('NumberModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': '1',
        'numeral': '᱑',
        'value': 1,
        'nameOlChiki': 'ᱢᱤᱫ',
        'nameLatin': 'Mit',
      };
      final model = NumberModel.fromJson(json);
      expect(model.numeral, '᱑');
      expect(model.value, 1);
    });
  });

  group('QuizModel', () {
    test('fromJson → toJson roundtrip', () {
      final json = {
        'id': 'quiz_1',
        'categoryId': 'alphabets',
        'title': 'Test Quiz',
        'level': 'beginner',
        'order': 0,
        'isActive': true,
        'passingScore': 70,
        'questions': [
          {
            'promptOlChiki': 'ᱚ',
            'promptLatin': 'What is this?',
            'optionsOlChiki': ['a', 'i', 'u', 'o'],
            'optionsLatin': ['a', 'i', 'u', 'o'],
            'correctIndex': 0,
          },
        ],
      };
      final model = QuizModel.fromJson(json);
      expect(model.questions.length, 1);
      expect(model.questions.first.correctIndex, 0);

      final output = model.toJson();
      expect(output['title'], 'Test Quiz');
      expect((output['questions'] as List).length, 1);
    });
  });

  group('LessonModel', () {
    test('fromJson with blocks', () {
      final json = {
        'id': 'lesson_1',
        'categoryId': 'cat_1',
        'titleOlChiki': 'ᱯᱟᱹᱴ',
        'titleLatin': 'Lesson 1',
        'order': 0,
        'estimatedMinutes': 5,
        'blocks': [
          {'type': 'text', 'textOlChiki': 'ᱚ', 'textLatin': 'O'},
        ],
      };
      final model = LessonModel.fromJson(json);
      expect(model.blocks.length, 1);
      expect(model.blocks.first.type, 'text');
    });

    test('fromJson with empty blocks', () {
      final json = {
        'id': 'lesson_2',
        'categoryId': 'cat_1',
        'titleOlChiki': 'ᱯᱟᱹᱴ',
        'titleLatin': 'Lesson 2',
        'order': 0,
        'blocks': [],
      };
      final model = LessonModel.fromJson(json);
      expect(model.blocks, isEmpty);
    });
  });

  group('LessonBlock', () {
    test('text block parses correctly', () {
      final block = LessonBlock(type: 'text', textOlChiki: 'ᱚ', textLatin: 'A');
      expect(block.type, 'text');
      expect(block.textOlChiki, 'ᱚ');
    });

    test('quiz ref block', () {
      final block = LessonBlock(type: 'quiz', quizRefId: 'quiz_123');
      expect(block.type, 'quiz');
      expect(block.quizRefId, 'quiz_123');
    });
  });
}
