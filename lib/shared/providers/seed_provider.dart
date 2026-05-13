import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/categories/data/models/category_model.dart';
import '../../features/categories/domain/entities/category_entity.dart';
import '../../features/lessons/data/models/lesson_model.dart';
import '../models/content_models.dart' hide CategoryModel, LessonModel;
import 'providers.dart';

Future<void> seedAppContent(WidgetRef ref) async {
  final categoriesNotifier = ref.read(categoryNotifierProvider.notifier);
  final lettersNotifier = ref.read(lettersProvider.notifier);
  final lessonsNotifier = ref.read(lessonNotifierProvider.notifier);
  final numbersNotifier = ref.read(numbersProvider.notifier);
  final wordsNotifier = ref.read(wordsProvider.notifier);
  final sentencesNotifier = ref.read(sentencesProvider.notifier);

  // Load existing categories so we can skip duplicates
  await categoriesNotifier.loadCategories();
  final existing = ref.read(categoryNotifierProvider).value ?? [];
  final existingIds = existing.map((c) => c.id).toSet();
  final existingTitles =
      existing.map((c) => c.titleLatin.trim().toLowerCase()).toSet();

  Future<String> addCategoryIfNew(CategoryModel cat) async {
    final normTitle = cat.titleLatin.trim().toLowerCase();
    
    final existingCat = existing.cast<CategoryEntity?>().firstWhere(
      (c) => c?.id == cat.id || c?.titleLatin.trim().toLowerCase() == normTitle,
      orElse: () => null,
    );
    
    if (existingCat != null) {
      return existingCat.id; // Return existing ID
    }

    await categoriesNotifier.addCategory(cat);
    existingIds.add(cat.id);
    existingTitles.add(normTitle);
    return cat.id; // Return new ID
  }

  // ── Alphabets Category ──
  final actualAlphabetsId = await addCategoryIfNew(
    const CategoryModel(
      id: 'cat_alphabets',
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

  // ── Alphabet Lessons (rich blocks for each) ──
  final alphabetLessons = [
    {
      'id': 'lesson_alphabet_0',
      'titleLatin': 'Basics of Ol Chiki',
      'titleOlChiki': 'ᱚᱞ ᱪᱤᱠᱤ ᱢᱩᱞ',
      'blocks': [
        const LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱚᱞ ᱪᱤᱠᱤ',
          textLatin: 'Ol Chiki is the writing system for the Santali language',
        ),
        const LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱚ',
          textLatin: 'Letter "a" – the first letter of Ol Chiki',
        ),
        const LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱛ',
          textLatin: 'Letter "at" – used in words like ᱛᱟᱞᱟ (below)',
        ),
        const LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱚᱛ',
          textLatin: 'Practice: Combine ᱚ + ᱛ to form "at"',
        ),
      ],
    },
    {
      'id': 'lesson_alphabet_1',
      'titleLatin': 'Vowels I',
      'titleOlChiki': 'ᱨᱟᱦᱟ ᱟᱲᱟᱝ I',
      'blocks': [
        const LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱚ',
          textLatin: 'Vowel "a" – open sound, as in "father"',
        ),
        const LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱟ',
          textLatin: 'Vowel "aa" – elongated open sound',
        ),
        const LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱤ',
          textLatin: 'Vowel "i" – short "i" sound as in "sit"',
        ),
        const LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱩ',
          textLatin: 'Vowel "u" – sound as in "put"',
        ),
        const LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱮ',
          textLatin: 'Vowel "e" – short "e" sound as in "bed"',
        ),
      ],
    },
    {
      'id': 'lesson_alphabet_2',
      'titleLatin': 'Consonants I',
      'titleOlChiki': 'ᱠᱮᱪᱮᱫ ᱟᱲᱟᱝ I',
      'blocks': [
        const LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱜ',
          textLatin: 'Consonant "ag" – as in ᱜᱟᱰᱟ (river)',
        ),
        const LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱝ',
          textLatin: 'Consonant "ang" – nasal sound',
        ),
        const LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱞ',
          textLatin: 'Consonant "al" – as in ᱞᱟᱹᱭ (to take)',
        ),
        const LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱠ',
          textLatin: 'Consonant "ak" – as in ᱠᱟᱹᱢᱤ (work)',
        ),
        const LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱡ',
          textLatin: 'Consonant "aj" – as in ᱡᱚᱦᱟᱨ (hello)',
        ),
      ],
    },
    {
      'id': 'lesson_alphabet_3',
      'titleLatin': 'Consonants II',
      'titleOlChiki': 'ᱠᱮᱪᱮᱫ ᱟᱲᱟᱝ II',
      'blocks': [
        const LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱪ',
          textLatin: 'Consonant "ach" – as in ᱪᱮᱛᱟᱱ (field)',
        ),
        const LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱫ',
          textLatin: 'Consonant "ad" – as in ᱫᱟᱠᱟ (food/rice)',
        ),
        const LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱯ',
          textLatin: 'Consonant "ap" – as in ᱯᱟᱱᱛᱮ (path)',
        ),
        const LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱢ',
          textLatin: 'Consonant "am" – as in ᱢᱟᱹᱡᱷᱤ (village head)',
        ),
      ],
    },
    {
      'id': 'lesson_alphabet_4',
      'titleLatin': 'Vowels II',
      'titleOlChiki': 'ᱨᱟᱦᱟ ᱟᱲᱟᱝ II',
      'blocks': [
        const LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱳ',
          textLatin: 'Vowel "o" – rounded sound as in "go"',
        ),
        const LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱚᱦ',
          textLatin: 'Vowel combination "ah" – aspirated',
        ),
        const LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱟᱹ',
          textLatin: 'Modified vowel "aa" – checked vowel variant',
        ),
        const LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱮᱹ',
          textLatin: 'Modified vowel "e" – nasalized variant',
        ),
      ],
    },
  ];

  for (int i = 0; i < alphabetLessons.length; i++) {
    final lesson = alphabetLessons[i];
    await lessonsNotifier.addLesson(
      LessonModel(
        id: lesson['id'] as String,
        categoryId: actualAlphabetsId,
        titleOlChiki: lesson['titleOlChiki'] as String,
        titleLatin: lesson['titleLatin'] as String,
        order: i,
        blocks: lesson['blocks'] as List<LessonBlockModel>,
      ),
    );
  }

  // ── Numbers Category ──
  final actualNumbersId = await addCategoryIfNew(
    const CategoryModel(
      id: 'cat_numbers',
      titleOlChiki: 'ᱮᱞᱠᱷᱟ',
      titleLatin: 'Numbers',
      iconName: 'numbers',
      gradientPreset: 'peach',
      order: 1,
      totalLessons: 2,
    ),
  );

  // Seed numbers (0-9)
  await numbersNotifier.seed();

  const olChikiNumerals = ['᱐', '᱑', '᱒', '᱓', '᱔', '᱕', '᱖', '᱗', '᱘', '᱙'];
  const latinLabels = [
    '0 – Zero', '1 – One', '2 – Two', '3 – Three', '4 – Four',
    '5 – Five', '6 – Six', '7 – Seven', '8 – Eight', '9 – Nine',
  ];

  await lessonsNotifier.addLesson(
    LessonModel(
      id: 'lesson_numbers_0_9',
      categoryId: actualNumbersId,
      titleOlChiki: '᱐-᱙ ᱮᱞᱠᱷᱟ',
      titleLatin: 'Numbers 0-9',
      blocks: List.generate(
        10,
        (i) => LessonBlockModel(
          type: 'text',
          textOlChiki: olChikiNumerals[i],
          textLatin: latinLabels[i],
        ),
      ).toList(),
    ),
  );

  // Numbers 10-20 lesson
  const olChikiTens = ['᱑᱐', '᱑᱑', '᱑᱒', '᱑᱓', '᱑᱔', '᱑᱕', '᱑᱖', '᱑᱗', '᱑᱘', '᱑᱙', '᱒᱐'];
  const latinTens = [
    '10 – Ten', '11 – Eleven', '12 – Twelve', '13 – Thirteen', '14 – Fourteen',
    '15 – Fifteen', '16 – Sixteen', '17 – Seventeen', '18 – Eighteen',
    '19 – Nineteen', '20 – Twenty',
  ];

  await lessonsNotifier.addLesson(
    LessonModel(
      id: 'lesson_numbers_10_20',
      categoryId: actualNumbersId,
      titleOlChiki: '᱑᱐-᱒᱐ ᱮᱞᱠᱷᱟ',
      titleLatin: 'Numbers 10-20',
      order: 1,
      blocks: List.generate(
        11,
        (i) => LessonBlockModel(
          type: 'text',
          textOlChiki: olChikiTens[i],
          textLatin: latinTens[i],
        ),
      ).toList(),
    ),
  );

  // ── Vocabulary Category ──
  final actualVocabId = await addCategoryIfNew(
    const CategoryModel(
      id: 'cat_vocab',
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
    {
      'id': 'lesson_vocab_0',
      'titleLatin': 'Greetings',
      'titleOlChiki': 'ᱡᱚᱦᱟᱨ',
      'blocks': const [
        LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱡᱚᱦᱟᱨ',
          textLatin: 'Hello / Greetings',
        ),
        LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱥᱮᱛᱟ',
          textLatin: 'Good morning',
        ),
        LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱢᱟᱦᱟ',
          textLatin: 'Good night',
        ),
        LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱟᱹᱰᱤ ᱡᱚᱦᱟᱨ',
          textLatin: 'See you again / Goodbye',
        ),
        LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱥᱟᱨᱦᱟᱣ',
          textLatin: 'Welcome',
        ),
      ],
    },
    {
      'id': 'lesson_vocab_1',
      'titleLatin': 'Family',
      'titleOlChiki': 'ᱯᱟᱨᱤᱣᱟᱨ',
      'blocks': const [
        LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱵᱟᱵᱟ',
          textLatin: 'Father',
        ),
        LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱟᱭᱳ',
          textLatin: 'Mother',
        ),
        LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱫᱟᱫᱟ',
          textLatin: 'Elder brother',
        ),
        LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱫᱟᱹᱭ',
          textLatin: 'Elder sister',
        ),
        LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱟᱹᱛᱩ',
          textLatin: 'Grandfather',
        ),
        LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱟᱹᱭᱳ',
          textLatin: 'Grandmother',
        ),
      ],
    },
    {
      'id': 'lesson_vocab_2',
      'titleLatin': 'Colors',
      'titleOlChiki': 'ᱨᱚᱝ',
      'blocks': const [
        LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱟᱨᱟᱜ',
          textLatin: 'Red',
        ),
        LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱥᱟᱥᱟᱝ',
          textLatin: 'Green',
        ),
        LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱦᱟᱹᱨᱭᱟᱹᱲ',
          textLatin: 'Yellow',
        ),
        LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱯᱩᱱᱫ',
          textLatin: 'White',
        ),
        LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱦᱮᱱᱫᱮ',
          textLatin: 'Black',
        ),
      ],
    },
    {
      'id': 'lesson_vocab_3',
      'titleLatin': 'Animals',
      'titleOlChiki': 'ᱡᱟᱱᱣᱟᱨ',
      'blocks': const [
        LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱥᱮᱛᱟ',
          textLatin: 'Dog',
        ),
        LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱢᱮᱨᱳᱢ',
          textLatin: 'Cat',
        ),
        LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱜᱟᱹᱭ',
          textLatin: 'Cow',
        ),
        LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱥᱩᱠᱨᱤ',
          textLatin: 'Pig',
        ),
        LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱪᱮᱨᱮ',
          textLatin: 'Bird',
        ),
        LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱦᱟᱹᱠᱩ',
          textLatin: 'Hen / Chicken',
        ),
      ],
    },
  ];

  for (int i = 0; i < vocabLessons.length; i++) {
    final lesson = vocabLessons[i];
    await lessonsNotifier.addLesson(
      LessonModel(
        id: lesson['id'] as String,
        categoryId: actualVocabId,
        titleOlChiki: lesson['titleOlChiki'] as String,
        titleLatin: lesson['titleLatin'] as String,
        order: i,
        blocks: lesson['blocks'] as List<LessonBlockModel>,
      ),
    );
  }

  // ── Sentences Category ──
  final actualSentencesId = await addCategoryIfNew(
    const CategoryModel(
      id: 'cat_sentences',
      titleOlChiki: 'ᱣᱟᱠᱭ',
      titleLatin: 'Sentences',
      iconName: 'sentences',
      gradientPreset: 'ocean',
      order: 3,
      totalLessons: 2,
    ),
  );

  await sentencesNotifier.seed();

  await lessonsNotifier.addLesson(
    const LessonModel(
      id: 'lesson_sentences_basics',
      categoryId: 'cat_sentences',
      titleOlChiki: 'ᱢᱩᱞ ᱣᱟᱠᱭ',
      titleLatin: 'Basic Sentences',
      blocks: [
        LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱟᱢᱟᱜ ᱧᱩᱛᱩᱢ ᱪᱮᱫ?',
          textLatin: 'What is your name?',
        ),
        LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱤᱧᱟᱜ ᱧᱩᱛᱩᱢ ᱫᱚ ᱥᱟᱱᱛᱷᱟᱞ',
          textLatin: 'My name is Santhal',
        ),
        LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱟᱢ ᱪᱮᱫᱟᱜ ᱠᱟᱱᱟ?',
          textLatin: 'How are you?',
        ),
        LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱤᱧ ᱵᱟᱝ ᱠᱟᱱᱟ',
          textLatin: 'I am fine',
        ),
        LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱟᱢ ᱚᱠᱟ ᱠᱷᱚᱱ ᱠᱟᱱᱟ?',
          textLatin: 'Where are you from?',
        ),
      ],
    ),
  );

  await lessonsNotifier.addLesson(
    const LessonModel(
      id: 'lesson_sentences_daily',
      categoryId: 'cat_sentences',
      titleOlChiki: 'ᱫᱤᱱᱟᱹᱢ ᱣᱟᱠᱭ',
      titleLatin: 'Daily Sentences',
      order: 1,
      blocks: [
        LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱤᱧ ᱥᱮᱨᱢᱟ ᱠᱟᱱᱟ',
          textLatin: 'I am hungry',
        ),
        LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱫᱟᱠᱟ ᱡᱚᱢ ᱢᱮ',
          textLatin: 'Please eat food',
        ),
        LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱫᱟᱹᱲ ᱧᱩ ᱢᱮ',
          textLatin: 'Please drink water',
        ),
        LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱤᱧ ᱥᱟᱹᱠᱟᱢ ᱞᱮᱠᱟ ᱵᱮᱱᱟᱣ ᱠᱟᱱᱟ',
          textLatin: 'I am studying',
        ),
        LessonBlockModel(
          type: 'text',
          textOlChiki: 'ᱟᱹᱰᱤ ᱡᱚᱦᱟᱨ',
          textLatin: 'Goodbye / See you again',
        ),
      ],
    ),
  );

  // ── Quiz ──
  const quizId = 'quiz_basics_1';
  await ref.read(quizzesProvider.notifier).addQuiz(
    QuizModel(
      id: quizId,
      categoryId: actualAlphabetsId,
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
