import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/categories/data/models/category_model.dart';
import '../../features/lessons/data/models/lesson_model.dart';
import '../../features/rhymes/domain/rhyme_model.dart';
import '../models/content_models.dart' hide CategoryModel, LessonModel;
import 'providers.dart';

Future<void> seedAppContent(WidgetRef ref) async {
  final categoriesNotifier = ref.read(categoryNotifierProvider.notifier);
  final lettersNotifier = ref.read(lettersProvider.notifier);
  final lessonsNotifier = ref.read(lessonNotifierProvider.notifier);
  final numbersNotifier = ref.read(numbersProvider.notifier);
  final wordsNotifier = ref.read(wordsProvider.notifier);
  final sentencesNotifier = ref.read(sentencesProvider.notifier);

  // ── Alphabets Category ──
  const alphabetsId = 'cat_alphabets';
  await categoriesNotifier.addCategory(
    CategoryModel(
      id: alphabetsId,
      titleOlChiki: 'ᱚᱞ ᱪᱤᱠᱤ',
      titleLatin: 'Alphabets',
      iconName: 'alphabet',
      totalLessons: 5,
    ),
  );

  final letters = [
    ['ᱚ', 'a'],
    ['ᱛ', 'at'],
    ['ᱜ', 'ag'],
    ['ᱝ', 'ang'],
    ['ᱞ', 'al'],
  ];
  for (int i = 0; i < letters.length; i++) {
    lettersNotifier.addLetter(
      LetterModel(
        id: 'letter_${letters[i][1]}',
        charOlChiki: letters[i][0],
        transliterationLatin: letters[i][1],
        order: i,
      ),
    );
  }

  final lessonTitles = [
    ['Basics of Ol Chiki', 'ᱚᱞ ᱪᱤᱠᱤ ᱢᱩᱞ'],
    ['Vowels I', 'ᱨᱟᱦᱟ ᱟᱲᱟᱝ I'],
    ['Consonants I', 'ᱠᱮᱪᱮᱫ ᱟᱲᱟᱝ I'],
  ];
  for (int i = 0; i < lessonTitles.length; i++) {
    await lessonsNotifier.addLesson(
      LessonModel(
        id: 'lesson_alphabet_$i',
        categoryId: alphabetsId,
        titleOlChiki: lessonTitles[i][1],
        titleLatin: lessonTitles[i][0],
        order: i,
        blocks: [
          LessonBlockModel(
            type: 'text',
            textOlChiki: letters[i][0],
            textLatin: 'Learn the letter ${letters[i][1]}',
          ),
        ],
      ),
    );
  }

  // ── Numbers Category ──
  const numbersId = 'cat_numbers';
  await categoriesNotifier.addCategory(
    CategoryModel(
      id: numbersId,
      titleOlChiki: 'ᱮᱞᱠᱷᱟ',
      titleLatin: 'Numbers',
      iconName: 'numbers',
      gradientPreset: 'peach',
      order: 1,
      totalLessons: 1,
    ),
  );

  // Seed numbers (0-9)
  await numbersNotifier.seed();

  await lessonsNotifier.addLesson(
    LessonModel(
      id: 'lesson_numbers_0_9',
      categoryId: numbersId,
      titleOlChiki: '᱐-᱙ ᱮᱞᱠᱷᱟ',
      titleLatin: 'Numbers 0-9',
      blocks: List.generate(
        10,
        (i) => LessonBlockModel(
          type: 'text',
          textOlChiki: 'n$i', // Scoping by ID or string?
          textLatin: 'Number $i',
        ),
      ).toList(),
    ),
  );

  // ── Vocabulary Category ──
  const vocabId = 'cat_vocab';
  await categoriesNotifier.addCategory(
    CategoryModel(
      id: vocabId,
      titleOlChiki: 'ᱨᱚᱲ',
      titleLatin: 'Vocabulary',
      iconName: 'words',
      gradientPreset: 'mint',
      order: 2,
      totalLessons: 4,
    ),
  );

  await wordsNotifier.seed();

  final vocabLessons = [
    ['Greetings', 'ᱡᱚᱦᱟᱨ', ['ᱡᱚᱦᱟᱨ', 'ᱥᱟᱹᱜᱩᱱ ᱥᱮᱛᱟ', 'ᱥᱟᱹᱜᱩᱱ ᱢᱟᱦᱟ']],
    ['Family', 'ᱯᱟᱨᱤᱣᱟᱨ', ['ᱵᱟᱵᱟ', 'ᱟᱭᱳ', 'ᱫᱟᱫᱟ', 'ᱫᱟᱹᱭ']],
  ];
  for (int i = 0; i < vocabLessons.length; i++) {
    await lessonsNotifier.addLesson(
      LessonModel(
        id: 'lesson_vocab_$i',
        categoryId: vocabId,
        titleOlChiki: vocabLessons[i][1] as String,
        titleLatin: vocabLessons[i][0] as String,
        order: i,
        blocks: (vocabLessons[i][2] as List<String>)
            .map((word) => LessonBlockModel(
                  type: 'text',
                  textOlChiki: word,
                  textLatin: 'Learning $word',
                ))
            .toList(),
      ),
    );
  }

  // ── Sentences Category ──
  const sentencesCatId = 'cat_sentences';
  await categoriesNotifier.addCategory(
    CategoryModel(
      id: sentencesCatId,
      titleOlChiki: 'ᱣᱟᱠᱭ',
      titleLatin: 'Sentences',
      iconName: 'sentences',
      gradientPreset: 'ocean',
      order: 3,
      totalLessons: 1,
    ),
  );

  await sentencesNotifier.seed();

  await lessonsNotifier.addLesson(
    LessonModel(
      id: 'lesson_sentences_basics',
      categoryId: sentencesCatId,
      titleOlChiki: 'ᱢᱩᱞ ᱣᱟᱠᱭ',
      titleLatin: 'Basic Sentences',
      blocks: [
        const LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱟᱢᱟᱜ ᱧᱩᱛᱩᱢ ᱪᱮᱫ?',
          textLatin: 'What is your name?',
        ),
        const LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱤᱧᱟᱜ ᱧᱩᱛᱩᱢ ᱫᱚ ᱥᱟᱱᱛᱷᱟᱞ',
          textLatin: 'My name is Santhal',
        ),
      ],
    ),
  );

  // ── Quiz ──
  const quizId = 'quiz_basics_1';
  await ref.read(quizzesProvider.notifier).addQuiz(
    QuizModel(
      id: quizId,
      categoryId: alphabetsId,
      title: 'Basics Quiz',
      questions: [
        QuizQuestion(
          promptOlChiki: 'Which letter is "La"?',
          optionsOlChiki: ['ᱚ', 'ᱛ', 'ᱜ', 'ᱞ'],
          optionsLatin: ['a', 'at', 'ag', 'al'],
          correctIndex: 3,
        ),
      ],
    ),
  );
}
