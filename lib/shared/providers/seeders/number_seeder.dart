import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/categories/data/models/category_model.dart';
import '../../../features/lessons/data/models/lesson_model.dart';
import '../../utils/santali_numbers.dart';
import '../providers.dart';
import '../../../core/api/appwrite_db_service.dart';

class NumberSeeder {
  static LessonBlockModel _numberBlock(int value) {
    return LessonBlockModel(
      type: 'text',
      textOlChiki: SantaliNumbers.toOlChikiNumeral(value),
      textLatin: '$value – ${SantaliNumbers.englishName(value)}',
      data: {
        'pronunciation': SantaliNumbers.nameLatin(value),
        'meaning': SantaliNumbers.englishName(value),
        'meaning_en': SantaliNumbers.teachingLanguageName(value, 'en'),
        'meaning_bn': SantaliNumbers.teachingLanguageName(value, 'bn'),
        'meaning_hi': SantaliNumbers.teachingLanguageName(value, 'hi'),
        'meaning_or': SantaliNumbers.teachingLanguageName(value, 'or'),
        'pronunciation_bn': SantaliNumbers.pronunciation(value, 'bn'),
        'pronunciation_hi': SantaliNumbers.pronunciation(value, 'hi'),
        'pronunciation_or': SantaliNumbers.pronunciation(value, 'or'),
        'pronunciation_en': SantaliNumbers.pronunciation(value, 'en'),
        'pronunciation_sat': SantaliNumbers.pronunciation(value, 'sat'),
      },
    );
  }

  static LessonModel _rangeLesson({
    required String id,
    required String categoryId,
    required int start,
    required int end,
    required int order,
  }) {
    final startNumeral = SantaliNumbers.toOlChikiNumeral(start);
    final endNumeral = SantaliNumbers.toOlChikiNumeral(end);
    return LessonModel(
      id: id,
      categoryId: categoryId,
      titleOlChiki: '$startNumeral-$endNumeral ᱮᱞᱠᱷᱟ',
      titleLatin: 'Numbers $start-$end',
      order: order,
      blocks: List.generate(
        end - start + 1,
        (i) => _numberBlock(start + i),
      ).toList(),
    );
  }

  static Future<String> seed(
    WidgetRef ref,
    Future<String> Function(CategoryModel) addCategoryIfNew,
    Future<void> Function(LessonModel) addLessonIfNew,
  ) async {
    final numbersNotifier = ref.read(numbersProvider.notifier);

    final actualNumbersId = await addCategoryIfNew(
      const CategoryModel(
        id: 'cat_numbers',
        titleOlChiki: 'ᱮᱞᱠᱷᱟ',
        titleLatin: 'Numbers',
        iconName: 'numbers',
        gradientPreset: 'peach',
        order: 1,
        totalLessons: 4,
      ),
    );

    final numbersRows = await ref
        .read(appwriteDbServiceProvider)
        .listDocuments('numbers');
    if (numbersRows.isEmpty) {
      // Seed numbers (0-100)
      await numbersNotifier.seed();
    }

    await addLessonIfNew(
      _rangeLesson(
        id: 'lesson_numbers_0_9',
        categoryId: actualNumbersId,
        start: 0,
        end: 9,
        order: 0,
      ),
    );

    // Numbers 10-20 lesson (Ol Chiki numerals generated to avoid
    // mixed-script typos).
    await addLessonIfNew(
      _rangeLesson(
        id: 'lesson_numbers_10_20',
        categoryId: actualNumbersId,
        start: 10,
        end: 20,
        order: 1,
      ),
    );

    await addLessonIfNew(
      _rangeLesson(
        id: 'lesson_numbers_21_50',
        categoryId: actualNumbersId,
        start: 21,
        end: 50,
        order: 2,
      ),
    );

    await addLessonIfNew(
      _rangeLesson(
        id: 'lesson_numbers_51_100',
        categoryId: actualNumbersId,
        start: 51,
        end: 100,
        order: 3,
      ),
    );

    return actualNumbersId;
  }
}
