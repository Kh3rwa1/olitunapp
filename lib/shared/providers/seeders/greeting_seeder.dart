import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/categories/data/models/category_model.dart';
import '../../../features/lessons/data/models/lesson_model.dart';
import '../providers.dart';

class GreetingSeeder {
  static Future<String> seed(
    WidgetRef ref,
    Future<String> Function(CategoryModel) addCategoryIfNew,
  ) async {
    final lessonsNotifier = ref.read(lessonNotifierProvider.notifier);

    final actualGreetingsId = await addCategoryIfNew(
      const CategoryModel(
        id: 'cat_phrases',
        titleOlChiki: 'ᱚᱥᱴᱟᱭ ᱠᱟᱛᱷᱟ',
        titleLatin: 'Greetings',
        iconName: 'greetings',
        gradientPreset: 'sunset',
        order: 4,
        totalLessons: 4,
      ),
    );

    final greetingLessons = [
      {
        'id': 'lesson_greet_0',
        'titleLatin': 'Basic Greetings',
        'titleOlChiki': 'ᱡᱚᱦᱟᱨ',
        'blocks': const [
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱚᱦᱟᱨ',
            textLatin: 'Johar – Hello / Greetings',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱥᱮᱛᱟᱜ',
            textLatin: 'Sagun setag – Good morning',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱛᱤᱠᱤᱱ',
            textLatin: 'Sagun tikin – Good afternoon',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱟᱹᱭᱩᱵ',
            textLatin: 'Sagun ayub – Good evening',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱧᱤᱫᱟᱹ',
            textLatin: 'Sagun njida – Good night',
          ),
        ],
      },
      {
        'id': 'lesson_greet_1',
        'titleLatin': 'Meeting People',
        'titleOlChiki': 'ᱦᱚᱲ ᱥᱟᱶᱛᱟ ᱧᱟᱯᱟᱢ',
        'blocks': const [
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢᱟᱜ ᱧᱩᱛᱩᱢ ᱪᱮᱫ?',
            textLatin: 'Amag njutum ced? – What is your name?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧᱟᱜ ᱧᱩᱛᱩᱢ ᱫᱚ ... ᱠᱟᱱᱟ',
            textLatin: 'Injag njutum do ... kana – My name is ...',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱚᱠᱟ ᱠᱷᱚᱱᱮᱢ ᱦᱮᱡ ᱠᱟᱱᱟ?',
            textLatin: 'Am oka khonem hej kana? – Where are you from?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱫᱚ ... ᱠᱷᱚᱱᱤᱧ ᱦᱮᱡ ᱠᱟᱱᱟ',
            textLatin: 'In do ... khoninj hej kana – I am from ...',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱥᱟᱶ ᱧᱟᱯᱟᱢ ᱠᱟᱛᱮ ᱨᱟᱹᱥᱠᱟᱹᱧ ᱵᱩᱡᱷᱟᱹᱣ ᱠᱮᱫᱟ',
            textLatin:
                'Am saw njapam kate raskanj bujhau keda – Nice to meet you!',
          ),
        ],
      },
      {
        'id': 'lesson_greet_2',
        'titleLatin': 'Polite Phrases',
        'titleOlChiki': 'ᱢᱟᱹᱱ ᱟᱹᱲᱟᱹ',
        'blocks': const [
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱨᱦᱟᱣ',
            textLatin: 'Sarhaw – Thank you',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱠᱟᱹ ᱠᱟᱹᱧ ᱢᱮ',
            textLatin: 'Ika kanj me – Excuse me / Sorry',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱮᱸ',
            textLatin: 'Hẽ – Yes',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱟᱝ',
            textLatin: 'Bang – No',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱭᱟ ᱠᱟᱛᱮ',
            textLatin: 'Daya kate – Please',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ',
            textLatin: 'Adi napay – Very good / Well done',
          ),
        ],
      },
      {
        'id': 'lesson_greet_3',
        'titleLatin': 'Farewells',
        'titleOlChiki': 'ᱵᱤᱫᱟᱹᱭ ᱠᱟᱛᱷᱟ',
        'blocks': const [
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱚᱦᱟᱨ ᱜᱮ',
            textLatin: 'Johar ge – Goodbye',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱟᱯᱟ ᱵᱚᱱ ᱧᱟᱯᱟᱢᱟ',
            textLatin: 'Gapa bon njapama – See you tomorrow',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱱᱟᱯᱟᱭ ᱛᱮ ᱛᱟᱦᱮᱸᱱ ᱢᱮ',
            textLatin: 'Napay te tahen me – Take care / Stay well',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱫᱚᱧ ᱪᱟᱞᱟᱜ ᱠᱟᱱᱟ',
            textLatin: 'In donj chalag kana – I am leaving now',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱩᱞᱟᱹᱲ ᱡᱚᱦᱟᱨ',
            textLatin: 'Dulaar Johar – Goodbye with love',
          ),
        ],
      },
    ];

    for (int i = 0; i < greetingLessons.length; i++) {
      final lesson = greetingLessons[i];
      await lessonsNotifier.addLesson(
        LessonModel(
          id: lesson['id'] as String,
          categoryId: actualGreetingsId,
          titleOlChiki: lesson['titleOlChiki'] as String,
          titleLatin: lesson['titleLatin'] as String,
          order: i,
          blocks: lesson['blocks'] as List<LessonBlockModel>,
        ),
      );
    }

    return actualGreetingsId;
  }
}
