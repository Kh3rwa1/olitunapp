import 'package:flutter_test/flutter_test.dart';
import 'package:itun/shared/models/content_models.dart';

void main() {
  group('CategoryModel', () {
    test('fromJson/toJson roundtrip', () {
      final original = CategoryModel(
        id: 'alphabets',
        titleOlChiki: 'ᱚᱞ ᱪᱤᱠᱤ',
        titleLatin: 'Alphabets',
        iconName: 'alphabet',
      );

      final json = original.toJson();
      final restored = CategoryModel.fromJson(json);

      expect(restored.id, 'alphabets');
      expect(restored.titleOlChiki, 'ᱚᱞ ᱪᱤᱠᱤ');
      expect(restored.titleLatin, 'Alphabets');
      expect(restored.iconName, 'alphabet');
      expect(restored.order, 0);
      expect(restored.isActive, isTrue);
    });

    test('fromJson handles missing fields gracefully', () {
      final model = CategoryModel.fromJson({'id': 'x'});
      expect(model.titleOlChiki, '');
      expect(model.titleLatin, '');
      expect(model.gradientPreset, 'skyBlue');
      expect(model.isActive, isTrue);
    });

    test('copyWith preserves unchanged fields', () {
      final original = CategoryModel(
        id: 'c1',
        titleOlChiki: 'ᱚ',
        titleLatin: 'Alpha',
        order: 3,
      );
      final copy = original.copyWith(titleLatin: 'Updated');
      expect(copy.titleLatin, 'Updated');
      expect(copy.id, 'c1');
      expect(copy.order, 3);
    });
  });

  group('LetterModel', () {
    test('fromJson/toJson roundtrip', () {
      final original = LetterModel(
        id: 'l1',
        charOlChiki: 'ᱚ',
        transliterationLatin: 'a',
        exampleWordOlChiki: 'ᱚᱛ',
        exampleWordLatin: 'at',
      );

      final json = original.toJson();
      final restored = LetterModel.fromJson(json);

      expect(restored.charOlChiki, 'ᱚ');
      expect(restored.transliterationLatin, 'a');
      expect(restored.character, 'ᱚ'); // backwards-compat getter
      expect(restored.romanization, 'a'); // backwards-compat getter
    });

    test('fromJson handles legacy field names', () {
      final model = LetterModel.fromJson({
        'character': 'ᱚ',
        'romanization': 'a',
      });
      expect(model.charOlChiki, 'ᱚ');
      expect(model.transliterationLatin, 'a');
    });
  });

  group('NumberModel', () {
    test('fromJson/toJson roundtrip', () {
      final original = NumberModel(
        id: 'n1',
        numeral: '᱑',
        value: 1,
        nameOlChiki: 'ᱢᱤᱛ',
        nameLatin: 'mit',
      );

      final json = original.toJson();
      final restored = NumberModel.fromJson(json);

      expect(restored.numeral, '᱑');
      expect(restored.value, 1);
      expect(restored.nameLatin, 'mit');
    });
  });

  group('WordModel', () {
    test('fromJson/toJson roundtrip', () {
      final original = WordModel(
        id: 'w1',
        wordOlChiki: 'ᱡᱚᱦᱟᱨ',
        wordLatin: 'johar',
        meaning: 'hello',
        category: 'greetings',
      );

      final json = original.toJson();
      final restored = WordModel.fromJson(json);

      expect(restored.wordOlChiki, 'ᱡᱚᱦᱟᱨ');
      expect(restored.meaning, 'hello');
      expect(restored.category, 'greetings');
    });
  });

  group('SentenceModel', () {
    test('fromJson/toJson roundtrip', () {
      final original = SentenceModel(
        id: 's1',
        sentenceOlChiki: 'ᱡᱚᱦᱟᱨ ᱢᱤ',
        sentenceLatin: 'johar mi',
        meaning: 'hello friend',
      );

      final json = original.toJson();
      final restored = SentenceModel.fromJson(json);

      expect(restored.sentenceOlChiki, 'ᱡᱚᱦᱟᱨ ᱢᱤ');
      expect(restored.meaning, 'hello friend');
    });
  });

  group('LessonBlock', () {
    test('fromMap handles flat structure', () {
      final block = LessonBlock.fromMap({
        'type': 'text',
        'textOlChiki': 'ᱚ',
        'textLatin': 'a',
      });
      expect(block.type, 'text');
      expect(block.textOlChiki, 'ᱚ');
      expect(block.textLatin, 'a');
    });

    test('fromMap handles nested contentJson', () {
      final block = LessonBlock.fromMap({
        'type': 'text',
        'contentJson': {
          'textOlChiki': 'ᱚ',
          'textLatin': 'a',
        },
      });
      expect(block.textOlChiki, 'ᱚ');
    });

    test('fromMap handles double-nested contentJson', () {
      final block = LessonBlock.fromMap({
        'type': 'text',
        'contentJson': {
          'type': 'text',
          'contentJson': {
            'textOlChiki': 'ᱚ',
            'textLatin': 'a',
          },
        },
      });
      expect(block.textOlChiki, 'ᱚ');
    });

    test('toMap/fromMap roundtrip', () {
      final original = LessonBlock(
        type: 'image',
        imageUrl: 'https://example.com/img.png',
      );

      final map = original.toMap();
      final restored = LessonBlock.fromMap(map);

      expect(restored.type, 'image');
      expect(restored.imageUrl, 'https://example.com/img.png');
      expect(restored.audioUrl, isNull);
    });
  });

  group('QuizModel', () {
    test('fromJson/toJson roundtrip', () {
      final original = QuizModel(
        id: 'q1',
        categoryId: 'alphabets',
        title: 'Test Quiz',
        passingScore: 80,
        questions: [
          QuizQuestion(
            promptOlChiki: 'ᱚ',
            promptLatin: 'What sound?',
            optionsOlChiki: ['a', 'i', 'u', 'o'],
            optionsLatin: ['a', 'i', 'u', 'o'],
            correctIndex: 0,
          ),
        ],
      );

      final json = original.toJson();
      final restored = QuizModel.fromJson(json);

      expect(restored.id, 'q1');
      expect(restored.title, 'Test Quiz');
      expect(restored.passingScore, 80);
      expect(restored.questions.length, 1);
      expect(restored.questions.first.correctIndex, 0);
    });

    test('copyWith updates selected fields', () {
      final original = QuizModel(
        id: 'q1',
        title: 'Before',
      );
      final copy = original.copyWith(title: 'After', passingScore: 85);
      expect(copy.title, 'After');
      expect(copy.passingScore, 85);
      expect(copy.id, 'q1');
    });

    test('QuizQuestion fromMap handles missing fields', () {
      final q = QuizQuestion.fromMap({});
      expect(q.promptOlChiki, '');
      expect(q.optionsLatin, isEmpty);
      expect(q.correctIndex, 0);
    });
  });
}
