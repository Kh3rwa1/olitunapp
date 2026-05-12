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

  final alphabetsId = 'cat_alphabets_${DateTime.now().millisecondsSinceEpoch}';
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
        id: 'letter_${i}_${DateTime.now().microsecondsSinceEpoch}',
        charOlChiki: letters[i][0],
        transliterationLatin: letters[i][1],
        order: i,
      ),
    );
  }

  final lessonTitles = [
    'Basics of Ol Chiki',
    'Vowels I',
    'Consonants I',
    'Vowels II',
    'Consonants II',
  ];
  for (int i = 0; i < lessonTitles.length; i++) {
    await lessonsNotifier.addLesson(
      LessonModel(
        id: 'lesson_${i}_${DateTime.now().microsecondsSinceEpoch}',
        categoryId: alphabetsId,
        titleOlChiki: 'ᱯᱟᱹᱴ $i',
        titleLatin: lessonTitles[i],
        order: i,
        blocks: const [],
      ),
    );
  }

  // ── Numbers Category ──
  final numbersId = 'cat_numbers_${DateTime.now().millisecondsSinceEpoch}';
  await categoriesNotifier.addCategory(
    CategoryModel(
      id: numbersId,
      titleOlChiki: 'ᱮᱞᱠᱷᱟ',
      titleLatin: 'Numbers',
      iconName: 'numbers',
      gradientPreset: 'peach',
      order: 1,
      totalLessons: 3,
    ),
  );

  // Seed numbers via provider (triggers _loadNumbers)
  await ref.read(numbersProvider.notifier).seed();

  // ── Vocabulary / Words Category ──
  final vocabId = 'cat_vocab_${DateTime.now().millisecondsSinceEpoch}';
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

  // Seed words via provider
  await ref.read(wordsProvider.notifier).seed();

  // Create vocab lessons
  final vocabLessons = [
    ['Greetings & Basics', 'ᱡᱚᱦᱟᱨ ᱟᱨ ᱢᱩᱞ'],
    ['Family Words', 'ᱯᱟᱨᱤᱣᱟᱨ'],
    ['Nature Words', 'ᱯᱨᱚᱠᱨᱤᱛᱤ'],
    ['Body & Daily Life', 'ᱡᱤᱣᱤ ᱟᱨ ᱫᱤᱱᱚᱛ'],
  ];
  for (int i = 0; i < vocabLessons.length; i++) {
    await lessonsNotifier.addLesson(
      LessonModel(
        id: 'lesson_vocab_${i}_${DateTime.now().microsecondsSinceEpoch}',
        categoryId: vocabId,
        titleOlChiki: vocabLessons[i][1],
        titleLatin: vocabLessons[i][0],
        order: i,
        blocks: const [],
      ),
    );
  }

  // ── Sentences Category ──
  final sentencesCatId =
      'cat_sentences_${DateTime.now().millisecondsSinceEpoch}';
  await categoriesNotifier.addCategory(
    CategoryModel(
      id: sentencesCatId,
      titleOlChiki: 'ᱣᱟᱠᱭ',
      titleLatin: 'Sentences',
      iconName: 'sentences',
      gradientPreset: 'ocean',
      order: 3,
      totalLessons: 4,
    ),
  );

  // Seed sentences via provider
  await ref.read(sentencesProvider.notifier).seed();

  // Create sentence lessons
  final sentenceLessons = [
    ['Greetings & Goodbyes', 'ᱡᱚᱦᱟᱨ ᱟᱨ ᱵᱤᱫᱟᱭ'],
    ['Introducing Yourself', 'ᱟᱯᱱᱟᱨ ᱯᱟᱨᱤᱪᱚᱭ'],
    ['Asking Questions', 'ᱠᱩᱥᱤ ᱠᱟᱛᱷᱟ'],
    ['Daily Conversations', 'ᱫᱤᱱᱚᱛ ᱠᱟᱛᱷᱟ'],
  ];
  for (int i = 0; i < sentenceLessons.length; i++) {
    await lessonsNotifier.addLesson(
      LessonModel(
        id: 'lesson_sent_${i}_${DateTime.now().microsecondsSinceEpoch}',
        categoryId: sentencesCatId,
        titleOlChiki: sentenceLessons[i][1],
        titleLatin: sentenceLessons[i][0],
        order: i,
        blocks: const [],
      ),
    );
  }

  // ── Phrases / Greetings Category ──
  await categoriesNotifier.addCategory(
    CategoryModel(
      id: 'cat_phrases_${DateTime.now().millisecondsSinceEpoch}',
      titleOlChiki: 'ᱛᱮᱞᱟ ᱯᱟᱹᱨᱥᱤ',
      titleLatin: 'Greetings',
      iconName: 'words',
      gradientPreset: 'mint',
      order: 4,
      totalLessons: 4,
    ),
  );

  // ── Quiz ──
  final quizzesNotifier = ref.read(quizzesProvider.notifier);
  final quizId = 'quiz_basics_${DateTime.now().millisecondsSinceEpoch}';
  await quizzesNotifier.addQuiz(
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

  await lessonsNotifier.addLesson(
    LessonModel(
      id: 'lesson_quiz_demo_${DateTime.now().millisecondsSinceEpoch}',
      categoryId: alphabetsId,
      titleOlChiki: 'ᱠᱩᱤᱡᱽ',
      titleLatin: 'Quiz Demo',
      order: 99,
      estimatedMinutes: 2,
      blocks: const [
        LessonBlockModel(
          type: 'text',
          textLatin: 'Ready to test your knowledge?',
          textOlChiki: 'ᱵᱤᱰᱟᱹᱣ ᱨᱮᱱᱟᱜ ᱚᱠᱛᱚ!',
        ),
        LessonBlockModel(
          type: 'quiz',
          data: {'quizRefId': 'quiz_basics_...'},
        ), // Simplified for demo
      ],
    ),
  );

  // ── Rhymes ──
  final rhymesNotifier = ref.read(rhymesProvider.notifier);
  await rhymesNotifier.addRhyme(
    RhymeModel(
      id: 'rhyme_hati',
      titleOlChiki: 'ᱦᱟᱹᱛᱤ ᱞᱟᱹᱜᱤᱫ',
      titleLatin: 'Hati Lagit',
      contentOlChiki: 'ᱦᱟᱹᱛᱤ ᱞᱟᱹᱜᱤᱫ ᱦᱟᱹᱛᱤ...',
      contentLatin: 'Hati lagit hati...',
      category: 'Animal',
      subcategory: 'Wild Animals',
    ),
  );

  await rhymesNotifier.addRhyme(
    RhymeModel(
      id: 'rhyme_buru',
      titleOlChiki: 'ᱵᱩᱨᱩ ᱨᱮ',
      titleLatin: 'Buru Re',
      contentOlChiki: 'ᱵᱩᱨᱩ ᱨᱮ ᱵᱩᱨᱩ...',
      contentLatin: 'Buru re buru...',
      category: 'Nature',
      subcategory: 'Mountains & Forest',
    ),
  );
}
