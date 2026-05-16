import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/categories/data/models/category_model.dart';
import '../../../features/lessons/data/models/lesson_model.dart';
import '../../models/content_models.dart' hide CategoryModel, LessonModel;
import '../providers.dart';

class AlphabetSeeder {
  static Future<String> seed(
    WidgetRef ref,
    Future<String> Function(CategoryModel) addCategoryIfNew,
  ) async {
    final lettersNotifier = ref.read(lettersProvider.notifier);
    final lessonsNotifier = ref.read(lessonNotifierProvider.notifier);

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

    return actualAlphabetsId;
  }
}
