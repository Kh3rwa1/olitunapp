import 'package:itun/core/logging/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/catalog/category_model.dart';
import '../../../../shared/models/catalog/category_entity.dart';
import '../../../../shared/models/catalog/lesson_entity.dart';
import '../../../../core/config/appwrite_config.dart';
import 'seeders/alphabet_seeder.dart';
import 'seeders/greeting_seeder.dart';
import 'seeders/number_seeder.dart';
import 'seeders/quiz_seeder.dart';
import 'seeders/seed_existence.dart';
import 'seeders/sentence_seeder.dart';
import 'seeders/vocab_seeder.dart';
import 'package:itun/features/categories/presentation/providers/category_notifier.dart';
import 'package:itun/features/lessons/presentation/providers/lesson_notifier.dart';

Future<void> seedAppContent(WidgetRef ref) async {
  // Block seeding on the production project to protect integrity
  if (AppwriteConfig.projectId == '699495910038e39622c5') {
    AppLogger.debug(
      '🚫 Client-side seeding is disabled on the production Appwrite project.',
    );
    return;
  }

  final categoriesNotifier = ref.read(categoryNotifierProvider.notifier);

  // Load existing categories so we can skip duplicates
  await categoriesNotifier.loadCategories();
  final existing = ref.read(categoryNotifierProvider).value ?? [];
  final existingIds = existing.map((c) => c.id).toSet();
  final existingTitles = existing
      .map((c) => c.titleLatin.trim().toLowerCase())
      .toSet();

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

  // Existence comes from the Worker (D1). Writes go through the content
  // notifiers, i.e. the admin content write path.
  final existingLessonIds = await ref
      .read(seedExistenceCheckerProvider)
      .lessonIds();

  Future<void> addLessonIfNew(LessonEntity lesson) async {
    final exists = !existingLessonIds.add(lesson.id);
    if (exists) {
      if (lesson.id.startsWith('lesson_vocab_') ||
          lesson.id.startsWith('lesson_sentences_')) {
        AppLogger.debug(
          '🔄 Updating existing vocab/sentence lesson: ${lesson.id}',
        );
        await ref.read(lessonNotifierProvider.notifier).updateLesson(lesson);
      }
      return;
    }
    await ref.read(lessonNotifierProvider.notifier).addLesson(lesson);
  }

  final actualAlphabetsId = await AlphabetSeeder.seed(
    ref,
    addCategoryIfNew,
    addLessonIfNew,
  );
  await NumberSeeder.seed(ref, addCategoryIfNew, addLessonIfNew);
  await VocabSeeder.seed(ref, addCategoryIfNew, addLessonIfNew);
  await SentenceSeeder.seed(ref, addCategoryIfNew, addLessonIfNew);
  await GreetingSeeder.seed(ref, addCategoryIfNew, addLessonIfNew);

  try {
    await QuizSeeder.seed(ref, actualAlphabetsId);
  } catch (e, stack) {
    // Gracefully catch database exceptions if the quizzes collection is not set up
    // in Appwrite yet, allowing categories, words, and sentences to seed successfully.
    AppLogger.warning(
      '⚠️ Quizzes seeding skipped/failed',
      name: 'SeedProvider',
      error: e,
      stackTrace: stack,
    );
  }
}
