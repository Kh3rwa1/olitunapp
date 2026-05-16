import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/categories/data/models/category_model.dart';
import '../../../features/lessons/data/models/lesson_model.dart';
import '../providers.dart';

class NumberSeeder {
  static Future<String> seed(
    WidgetRef ref,
    Future<String> Function(CategoryModel) addCategoryIfNew,
  ) async {
    final numbersNotifier = ref.read(numbersProvider.notifier);
    final lessonsNotifier = ref.read(lessonNotifierProvider.notifier);

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
      '0 – Zero',
      '1 – One',
      '2 – Two',
      '3 – Three',
      '4 – Four',
      '5 – Five',
      '6 – Six',
      '7 – Seven',
      '8 – Eight',
      '9 – Nine',
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
    const olChikiTens = [
      '᱑᱐',
      '᱑᱑',
      '᱑᱒',
      '᱑᱓',
      '᱑᱔',
      '᱑᱕',
      '᱑᱖',
      '᱑۷',
      '᱑᱘',
      '᱑᱙',
      '᱒᱐',
    ];
    const latinTens = [
      '10 – Ten',
      '11 – Eleven',
      '12 – Twelve',
      '13 – Thirteen',
      '14 – Fourteen',
      '15 – Fifteen',
      '16 – Sixteen',
      '17 – Seventeen',
      '18 – Eighteen',
      '19 – Nineteen',
      '20 – Twenty',
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

    return actualNumbersId;
  }
}
