import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/categories/data/models/category_model.dart';
import '../../../features/lessons/data/models/lesson_model.dart';
import '../providers.dart';

class VocabSeeder {
  static Future<String> seed(
    WidgetRef ref,
    Future<String> Function(CategoryModel) addCategoryIfNew,
  ) async {
    final wordsNotifier = ref.read(wordsProvider.notifier);
    final lessonsNotifier = ref.read(lessonNotifierProvider.notifier);

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
          LessonBlockModel(type: 'text', textOlChiki: 'ᱟᱨᱟᱜ', textLatin: 'Red'),
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
          LessonBlockModel(type: 'text', textOlChiki: 'ᱥᱮᱛᱟ', textLatin: 'Dog'),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱮᱨᱳᱢ',
            textLatin: 'Cat',
          ),
          LessonBlockModel(type: 'text', textOlChiki: 'ᱜᱟᱹᱭ', textLatin: 'Cow'),
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

    return actualVocabId;
  }
}
