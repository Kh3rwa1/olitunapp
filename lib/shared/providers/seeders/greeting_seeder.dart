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
            textLatin: 'Johar – Hello / Greetings (formal)',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱚᱦᱟᱨ ᱢᱮ',
            textLatin: 'Johar me – Hello to you',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱰᱤ ᱡᱚᱦᱟᱨ',
            textLatin: 'Aadi Johar – Good morning',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱮᱛᱟᱜ ᱡᱚᱦᱟᱨ',
            textLatin: 'Setag Johar – Good evening',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱟᱝ ᱡᱚᱦᱟᱨ',
            textLatin: 'Bang Johar – Good night',
          ),
        ],
      },
      {
        'id': 'lesson_greet_1',
        'titleLatin': 'Meeting People',
        'titleOlChiki': 'ᱦᱚᱲ ᱥᱟᱶᱛᱟ',
        'blocks': const [
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱧᱩᱛᱩᱢ ᱪᱮᱫ?',
            textLatin: 'Am nyutum ched? – What is your name?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱧᱩᱛᱩᱢ ... ᱠᱟᱱᱟ',
            textLatin: 'Iny nyutum ... kana – My name is ...',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱚᱠᱟ ᱨᱮᱱ?',
            textLatin: 'Am oka ren? – Where are you from?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ... ᱨᱮᱱ',
            textLatin: 'Iny ... ren – I am from ...',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱥᱟᱶᱛᱟ ᱛᱟᱦᱮᱸ ᱠᱟᱱᱟ ᱵᱟᱝ ᱞᱟᱜᱟᱛᱤᱡᱚᱜ',
            textLatin: 'Nice to meet you!',
          ),
        ],
      },
      {
        'id': 'lesson_greet_2',
        'titleLatin': 'Polite Phrases',
        'titleOlChiki': 'ᱢᱟᱨᱟᱝ ᱠᱟᱛᱷᱟ',
        'blocks': const [
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱨᱦᱟᱣ',
            textLatin: 'Sarhaw – Thank you',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱟᱹᱧ ᱜᱚᱡ',
            textLatin: 'Maany goj – Excuse me / Sorry',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱮᱸ',
            textLatin: 'Hen – Yes',
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
            textOlChiki: 'ᱟᱹᱰᱤ ᱞᱮᱠᱟ',
            textLatin: 'Aadi leka – Very good / Well done',
          ),
        ],
      },
      {
        'id': 'lesson_greet_3',
        'titleLatin': 'Farewells',
        'titleOlChiki': 'ᱟᱹᱞᱟᱹ ᱠᱟᱛᱷᱟ',
        'blocks': const [
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱞᱟᱹ',
            textLatin: 'Aalaa – Goodbye',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱛᱟᱦᱮᱸᱱ ᱡᱚᱦᱟᱨ',
            textLatin: 'Tahen Johar – See you later',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱮᱨᱢᱟ ᱡᱚᱠᱷᱮᱡ',
            textLatin: 'Serma jokhej – Take care',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱟᱹᱧ ᱥᱮᱱ ᱟ',
            textLatin: 'Maany sen a – I am leaving now',
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
