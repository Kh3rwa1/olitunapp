import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/features/quiz/domain/lesson_quiz_generator.dart';
import 'package:itun/features/quiz/domain/listening_quiz_generator.dart';

void main() {
  group('LessonQuizGenerator Multilingual Tests', () {
    const complexLesson = LessonEntity(
      id: 'lesson_sentences_complex_advanced',
      titleLatin: 'Traditional Wisdom & Ecology',
      titleOlChiki: 'ᱥᱮᱫᱟᱭ ᱵᱩᱫᱷᱤ ᱟᱨ ᱥᱟᱶᱛᱟ',
      categoryId: 'sentences',
      order: 5,
      blocks: [
        LessonBlockEntity(
          type: 'sentence',
          textOlChiki:
              'ᱫᱟᱨᱮ ᱜᱮ ᱡᱤᱣᱤ ᱠᱟᱱᱟ, ᱚᱱᱟᱛᱮ ᱫᱟᱨᱮ ᱨᱩᱠᱷᱤᱭᱟᱹ ᱫᱚ ᱟᱵᱚᱣᱟᱜ ᱫᱷᱚᱨᱚᱢ ᱠᱟᱱᱟ᱾',
          textLatin:
              'Dare ge jiwi kana, onate dare rukhiya do abowag dhorom kana.',
          audioUrl: 'https://example.com/audio/dare.mp3',
          data: {
            'meaning':
                'Trees are life, therefore protecting trees is our sacred duty.',
            'meaning_en':
                'Trees are life, therefore protecting trees is our sacred duty.',
            'meaning_hi':
                'वृक्ष ही जीवन हैं इसलिए वृक्षों की रक्षा करना हमारा पवित्र कर्तव्य है।',
            'meaning_bn': 'গাছ জীবন, তাই গাছ রক্ষা করা আমাদের পবিত্র দায়িত্ব।',
            'meaning_or':
                'ବୃକ୍ଷଗୁଡ଼ିକ ଜୀବନ, ତେଣୁ ଗଛର ସୁରକ୍ଷା ଆମର ପବିତ୍ର କର୍ତ୍ତବ୍ୟ |',
          },
        ),
        LessonBlockEntity(
          type: 'sentence',
          textOlChiki: 'ᱜᱚᱡ ᱦᱚᱲ ᱫᱚ ᱵᱟᱹᱠᱩ ᱨᱚᱲᱟ, ᱚᱱᱟᱛᱮ ᱦᱚᱞᱟ ᱠᱟᱛᱷᱟ ᱫᱚ ᱦᱤᱲᱤᱧ ᱢᱮ᱾',
          textLatin: 'Goj hor do baku rora, onate hola katha do hirinj me.',
          audioUrl: 'https://example.com/audio/goj.mp3',
          data: {
            'meaning':
                "Dead people do not speak, so forget about yesterday's matters.",
            'meaning_en':
                "Dead people do not speak, so forget about yesterday's matters.",
            'meaning_hi': 'मरे हुए लोग बोलते नहीं, इसलिए भूल जाओ कल की बातें।',
            'meaning_bn':
                'মৃত মানুষ কথা বলে না, তাই গতকালের বিষয়গুলি ভুলে যান।',
            'meaning_or':
                'ମୃତ ଲୋକମାନେ କଥାବାର୍ତ୍ତା କରନ୍ତି ନାହିଁ, ତେଣୁ ଗତକାଲିର ବିଷୟ ଭୁଲିଯାଅ |',
          },
        ),
      ],
    );

    test('generates Hindi quiz when teachingLanguage is hi', () {
      final quiz = LessonQuizGenerator.generate(
        complexLesson,
        teachingLanguage: 'hi',
      );

      expect(quiz.questions, hasLength(2));

      // Question 0
      final q0 = quiz.questions[0];
      expect(q0.promptLatin, 'Choose the correct Hindi meaning:');
      expect(
        q0.optionsLatin[q0.correctIndex],
        'वृक्ष ही जीवन हैं इसलिए वृक्षों की रक्षा करना हमारा पवित्र कर्तव्य है।',
      );
      expect(q0.audioUrl, 'https://example.com/audio/dare.mp3');

      // Question 1 (matches user screenshot)
      final q1 = quiz.questions[1];
      expect(q1.promptLatin, 'Choose the correct Hindi meaning:');
      expect(
        q1.optionsLatin[q1.correctIndex],
        'मरे हुए लोग बोलते नहीं, इसलिए भूल जाओ कल की बातें।',
      );
      expect(q1.audioUrl, 'https://example.com/audio/goj.mp3');

      // Distractors must be non-empty and in Hindi (not containing 'Et')
      for (final opt in q1.optionsLatin) {
        expect(opt, isNotEmpty);
        expect(opt.contains('Et'), isFalse);
      }
    });

    test('generates Bengali quiz when teachingLanguage is bn', () {
      final quiz = LessonQuizGenerator.generate(
        complexLesson,
        teachingLanguage: 'bn',
      );

      expect(quiz.questions, hasLength(2));
      final q1 = quiz.questions[1];
      expect(q1.promptLatin, 'Choose the correct Bengali meaning:');
      expect(
        q1.optionsLatin[q1.correctIndex],
        'মৃত মানুষ কথা বলে না, তাই গতকালের বিষয়গুলি ভুলে যান।',
      );
    });

    test('generates Odia quiz when teachingLanguage is or', () {
      final quiz = LessonQuizGenerator.generate(
        complexLesson,
        teachingLanguage: 'or',
      );

      expect(quiz.questions, hasLength(2));
      final q1 = quiz.questions[1];
      expect(q1.promptLatin, 'Choose the correct Odia meaning:');
      expect(
        q1.optionsLatin[q1.correctIndex],
        'ମୃତ ଲୋକମାନେ କଥାବାର୍ତ୍ତା କରନ୍ତି ନାହିଁ, ତେଣୁ ଗତକାଲିର ବିଷୟ ଭୁଲିଯାଅ |',
      );
    });

    test('generates English quiz when teachingLanguage is en (default)', () {
      final quiz = LessonQuizGenerator.generate(complexLesson);

      expect(quiz.questions, hasLength(2));
      final q1 = quiz.questions[1];
      expect(q1.promptLatin, 'Choose the correct English meaning:');
      expect(
        q1.optionsLatin[q1.correctIndex],
        "Dead people do not speak, so forget about yesterday's matters.",
      );
    });

    test('ListeningQuizGenerator respects teachingLanguage', () {
      final listeningQuiz = ListeningQuizGenerator.generate(
        complexLesson,
        teachingLanguage: 'hi',
      );

      expect(listeningQuiz.questions, hasLength(2));
      final q1 = listeningQuiz.questions[1];
      expect(q1.promptLatin, 'ऑडियो सुनें और सही अर्थ चुनें:');
      expect(
        q1.optionsLatin[q1.correctIndex],
        'मरे हुए लोग बोलते नहीं, इसलिए भूल जाओ कल की बातें।',
      );
    });

    test('Number category localized prompts', () {
      const numberLesson = LessonEntity(
        id: 'lesson_num_1',
        titleLatin: 'Numbers 1 to 5',
        titleOlChiki: 'ᱮᱞ ᱑ ᱠᱷᱚᱱ ᱕',
        categoryId: 'numbers',
        blocks: [
          LessonBlockEntity(type: 'number', textOlChiki: '᱑', textLatin: '1'),
        ],
      );

      final quizHi = LessonQuizGenerator.generate(
        numberLesson,
        teachingLanguage: 'hi',
      );
      expect(quizHi.questions.first.promptLatin, 'यह संख्या पहचानें:');

      final quizEn = LessonQuizGenerator.generate(numberLesson);
      expect(quizEn.questions.first.promptLatin, 'Identify this number:');
    });

    test(
      'Alphabet category transliterates to target teaching language script',
      () {
        const alphabetLesson = LessonEntity(
          id: 'lesson_alpha_1',
          titleLatin: 'Vowels',
          titleOlChiki: 'ᱨᱟᱦᱟ ᱟᱲᱟᱝ',
          categoryId: 'alphabet',
          blocks: [
            LessonBlockEntity(type: 'letter', textOlChiki: 'ᱚ', textLatin: 'a'),
          ],
        );

        final quizHi = LessonQuizGenerator.generate(
          alphabetLesson,
          teachingLanguage: 'hi',
        );
        expect(
          quizHi.questions.first.promptLatin,
          'इस अक्षर की ध्वनि पहचानें:',
        );
        expect(quizHi.questions.first.optionsLatin, contains('अ'));

        final quizBn = LessonQuizGenerator.generate(
          alphabetLesson,
          teachingLanguage: 'bn',
        );
        expect(
          quizBn.questions.first.promptLatin,
          'এই বর্ণের উচ্চারণ চিহ্নিত করুন:',
        );
        expect(quizBn.questions.first.optionsLatin, contains('অ'));
      },
    );
  });
}
