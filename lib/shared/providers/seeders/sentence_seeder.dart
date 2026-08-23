import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/categories/data/models/category_model.dart';
import '../../../features/lessons/data/models/lesson_model.dart';
import '../../../features/lessons/domain/entities/lesson_entity.dart';
import '../providers.dart';

/// Seeds the Sentences category from the bundled JSON asset
/// `assets/seed/sentence_lessons.json`.
class SentenceSeeder {
  static const String _assetPath = 'assets/seed/sentence_lessons.json';

  static Future<String> seed(
    WidgetRef ref,
    Future<String> Function(CategoryModel) addCategoryIfNew,
    Future<void> Function(LessonEntity) addLessonIfNew,
  ) async {
    final sentencesNotifier = ref.read(sentencesProvider.notifier);

    final actualSentencesId = await addCategoryIfNew(
      const CategoryModel(
        id: 'cat_sentences',
        titleOlChiki: 'ᱣᱟᱠᱭ',
        titleLatin: 'Sentences',
        iconName: 'sentences',
        gradientPreset: 'ocean',
        order: 3,
        totalLessons: 13,
      ),
    );

    await sentencesNotifier.seed();

    final raw =
        jsonDecode(await rootBundle.loadString(_assetPath)) as List<dynamic>;
    final lessons = raw
        .cast<Map<String, dynamic>>()
        .map(LessonModel.fromJson)
        .toList();

    for (var i = 0; i < lessons.length; i++) {
      await addLessonIfNew(
        lessons[i].copyWith(categoryId: actualSentencesId, order: i),
      );
    }

    return actualSentencesId;
  }
}
