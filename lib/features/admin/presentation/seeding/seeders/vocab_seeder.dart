import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/models/catalog/category_model.dart';
import '../../../../../shared/models/catalog/lesson_model.dart';
import '../../../../../shared/models/catalog/lesson_entity.dart';
import '../../../../../shared/providers/providers.dart';

/// Seeds the Vocabulary category from the bundled JSON asset
/// `assets/seed/vocab_lessons.json`.
class VocabSeeder {
  static const String _assetPath = 'assets/seed/vocab_lessons.json';

  static Future<String> seed(
    WidgetRef ref,
    Future<String> Function(CategoryModel) addCategoryIfNew,
    Future<void> Function(LessonEntity) addLessonIfNew,
  ) async {
    final wordsNotifier = ref.read(wordsProvider.notifier);

    final actualVocabId = await addCategoryIfNew(
      const CategoryModel(
        id: 'cat_vocab',
        titleOlChiki: 'ᱨᱚᱲ',
        titleLatin: 'Vocabulary',
        iconName: 'words',
        gradientPreset: 'mint',
        order: 2,
        totalLessons: 14,
      ),
    );

    await wordsNotifier.seed();

    final raw =
        jsonDecode(await rootBundle.loadString(_assetPath)) as List<dynamic>;
    final lessons = raw
        .cast<Map<String, dynamic>>()
        .map(LessonModel.fromJson)
        .toList();

    for (var i = 0; i < lessons.length; i++) {
      await addLessonIfNew(
        lessons[i].copyWith(categoryId: actualVocabId, order: i),
      );
    }

    return actualVocabId;
  }
}
