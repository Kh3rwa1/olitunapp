import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/quiz/domain/mistake_question_localizer.dart';
import 'package:itun/features/quiz/presentation/providers/mistake_item.dart';
import 'package:itun/shared/models/content_models.dart';

void main() {
  group('MistakeQuestionLocalizer', () {
    final wordWater = WordModel(
      id: 'w_water',
      wordOlChiki: 'ᱫᱟᱜ',
      wordLatin: 'Dak',
      meaning: 'Water',
    );
    final wordFood = WordModel(
      id: 'w_food',
      wordOlChiki: 'ᱫᱟᱠᱟ',
      wordLatin: 'Daka',
      meaning: 'Food',
    );
    final wordHouse = WordModel(
      id: 'w_house',
      wordOlChiki: 'ᱚᱲᱟᱜ',
      wordLatin: 'Orak',
      meaning: 'House',
    );
    final wordTree = WordModel(
      id: 'w_tree',
      wordOlChiki: 'ᱫᱟᱨᱮ',
      wordLatin: 'Dare',
      meaning: 'Tree',
    );

    final mockWords = [wordWater, wordFood, wordHouse, wordTree];

    test('re-localizes a Hindi vocabulary question snapshot into Bengali', () {
      final hindiQuestion = QuizQuestion(
        promptOlChiki: 'ᱫᱟᱜ',
        promptLatin: 'इस शब्द का सही अर्थ चुनें:',
        optionsOlChiki: ['ᱫᱟᱜ', 'ᱫᱟᱠᱟ', 'ᱚᱲᱟᱜ', 'ᱫᱟᱨᱮ'],
        optionsLatin: ['पानी', 'खाना', 'घर', 'पेड़'],
        sourceWordId: 'w_water',
      );

      final localized = localizeMistakeQuestion(
        hindiQuestion,
        teachingLanguage: 'bn',
        words: mockWords,
        quizId: 'quiz_dynamic_vocab_basics',
      );

      expect(localized.promptLatin, equals('এই শব্দটির সঠিক অর্থ বেছে নিন:'));
      expect(localized.optionsLatin, equals(['জল', 'খাবার', 'বাড়ি', 'গাছ']));
      expect(localized.correctIndex, equals(0));
      expect(localized.sourceWordId, equals('w_water'));
      expect(localized.explanation, equals('জল'));
    });

    test('re-localizes LessonQuizGenerator-style prompt from Hindi to Bengali', () {
      final hindiQuestion = QuizQuestion(
        promptOlChiki: 'ᱫᱟᱜ',
        promptLatin: 'Choose the correct Hindi meaning:',
        optionsOlChiki: ['ᱫᱟᱜ', 'ᱫᱟᱠᱟ', 'ᱚᱲᱟᱜ', 'ᱫᱟᱨᱮ'],
        optionsLatin: ['पानी', 'खाना', 'घर', 'पेड़'],
        sourceWordId: 'w_water',
      );

      final localized = localizeMistakeQuestion(
        hindiQuestion,
        teachingLanguage: 'bn',
        words: mockWords,
        quizId: 'dynamic_quiz_lesson_1',
      );

      expect(
        localized.promptLatin,
        equals('Choose the correct Bengali meaning:'),
      );
      expect(localized.optionsLatin, equals(['জল', 'খাবার', 'বাড়ি', 'গাছ']));
      expect(localized.correctIndex, equals(0));
    });

    test('re-localizes number question snapshot from Hindi to Bengali', () {
      final hindiNumberQ = QuizQuestion(
        promptOlChiki: '᱕',
        promptLatin: 'यह संख्या पहचानें:',
        optionsOlChiki: ['᱓', '᱔', '᱕', '᱖'],
        optionsLatin: ['तीन (३)', 'चार (४)', 'पाँच (५)', 'छह (६)'],
        correctIndex: 2,
        isNonMemory: true,
      );

      final localized = localizeMistakeQuestion(
        hindiNumberQ,
        teachingLanguage: 'bn',
        quizId: 'quiz_numbers_arithmetic',
      );

      expect(localized.promptLatin, equals('এই সংখ্যাটি চিহ্নিত করুন:'));
      expect(
        localized.optionsLatin,
        equals(['তিন (৩)', 'চার (৪)', 'পাঁচ (৫)', 'ছয় (৬)']),
      );
      expect(localized.correctIndex, equals(2));
    });

    test('re-localizes letter question snapshot from Hindi to Bengali', () {
      final hindiLetterQ = QuizQuestion(
        promptOlChiki: 'ᱚ',
        promptLatin: 'इस अक्षर की ध्वनि पहचानें:',
        optionsOlChiki: ['ᱚ', 'ᱛ', 'ᱜ', 'ᱝ'],
        optionsLatin: ['अ', 'त', 'ग', 'ङ'],
        isNonMemory: true,
      );

      final localized = localizeMistakeQuestion(
        hindiLetterQ,
        teachingLanguage: 'bn',
        quizId: 'quiz_alphabets_basics',
      );

      expect(localized.promptLatin, equals('এই বর্ণের উচ্চারণ চিহ্নিত করুন:'));
      expect(localized.optionsLatin, equals(['অ', 'ত', 'গ', 'ং']));
      expect(localized.correctIndex, equals(0));
    });

    test('falls back to dictionary reverse-lookup when word corpus is empty', () {
      final orphanHindiQ = QuizQuestion(
        promptOlChiki: 'ᱫᱟᱜ',
        promptLatin: 'इस शब्द का सही अर्थ चुनें:',
        optionsLatin: ['पानी', 'खाना', 'घर', 'पेड़'],
      );

      final localized = localizeMistakeQuestion(
        orphanHindiQ,
        teachingLanguage: 'bn',
      );

      expect(localized.promptLatin, equals('এই শব্দটির সঠিক অর্থ বেছে নিন:'));
      expect(localized.optionsLatin, equals(['জল', 'খাবার', 'বাড়ি', 'গাছ']));
      expect(localized.correctIndex, equals(0));
    });

    test('re-localizes into Odia, Hindi, and English without regressions', () {
      final bengaliQ = QuizQuestion(
        promptOlChiki: 'ᱫᱟᱜ',
        promptLatin: 'এই শব্দটির সঠিক অর্থ বেছে নিন:',
        optionsOlChiki: ['ᱫᱟᱜ', 'ᱫᱟᱠᱟ', 'ᱚᱲᱟᱜ', 'ᱫᱟᱨᱮ'],
        optionsLatin: ['জল', 'খাবার', 'বাড়ি', 'গাছ'],
        sourceWordId: 'w_water',
      );

      final odia = localizeMistakeQuestion(
        bengaliQ,
        teachingLanguage: 'or',
        words: mockWords,
      );
      expect(odia.promptLatin, equals('ଏହି ଶବ୍ଦର ସଠିକ୍ ଅର୍ଥ ବାଛନ୍ତୁ:'));
      expect(odia.optionsLatin, equals(['ପାଣି', 'ଖାଦ୍ୟ', 'ଘର', 'ଗଛ']));
      expect(odia.correctIndex, equals(0));

      final hindi = localizeMistakeQuestion(
        bengaliQ,
        teachingLanguage: 'hi',
        words: mockWords,
      );
      expect(hindi.promptLatin, equals('इस शब्द का सही अर्थ चुनें:'));
      expect(hindi.optionsLatin, equals(['पानी', 'खाना', 'घर', 'पेड़']));
      expect(hindi.correctIndex, equals(0));

      final english = localizeMistakeQuestion(
        bengaliQ,
        teachingLanguage: 'en',
        words: mockWords,
      );
      expect(
        english.promptLatin,
        equals('Choose the correct English meaning for this word.'),
      );
      expect(english.optionsLatin, equals(['Water', 'Food', 'House', 'Tree']));
      expect(english.correctIndex, equals(0));
    });

    test('localizeMistakeItem wraps item with localized question', () {
      final mistake = MistakeItem(
        quizId: 'quiz_dynamic_vocab_basics',
        questionIndex: 0,
        question: QuizQuestion(
          promptOlChiki: 'ᱫᱟᱜ',
          promptLatin: 'इस शब्द का सही अर्थ चुनें:',
          optionsOlChiki: ['ᱫᱟᱜ', 'ᱫᱟᱠᱟ'],
          optionsLatin: ['पानी', 'खाना'],
          sourceWordId: 'w_water',
        ),
        addedAt: '2026-05-01T10:00:00Z',
      );

      final localizedItem = localizeMistakeItem(
        mistake,
        teachingLanguage: 'bn',
        words: mockWords,
      );

      expect(localizedItem.quizId, equals('quiz_dynamic_vocab_basics'));
      expect(localizedItem.questionIndex, equals(0));
      expect(
        localizedItem.question.promptLatin,
        equals('এই শব্দটির সঠিক অর্থ বেছে নিন:'),
      );
      expect(localizedItem.question.optionsLatin, equals(['জল', 'খাবার']));
    });
  });
}
