import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/categories/data/models/category_model.dart';
import '../../../features/lessons/data/models/lesson_model.dart';
import '../providers.dart';

class SentenceSeeder {
  static Future<String> seed(
    WidgetRef ref,
    Future<String> Function(CategoryModel) addCategoryIfNew,
  ) async {
    final sentencesNotifier = ref.read(sentencesProvider.notifier);
    final lessonsNotifier = ref.read(lessonNotifierProvider.notifier);

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
      LessonModel(
        id: 'lesson_sentences_basics',
        categoryId: actualSentencesId,
        titleOlChiki: 'ᱢᱩᱞ ᱣᱟᱠᱭ',
        titleLatin: 'Basic Sentences',
        blocks: const [
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
      LessonModel(
        id: 'lesson_sentences_daily',
        categoryId: actualSentencesId,
        titleOlChiki: 'ᱫᱤᱱᱟᱹᱢ ᱣᱟᱠᱭ',
        titleLatin: 'Daily Sentences',
        order: 1,
        blocks: const [
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

    return actualSentencesId;
  }
}
