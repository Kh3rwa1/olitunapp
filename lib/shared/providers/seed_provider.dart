import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/categories/data/models/category_model.dart';
import '../../features/categories/domain/entities/category_entity.dart';
import 'providers.dart';
import 'seeders/alphabet_seeder.dart';
import 'seeders/greeting_seeder.dart';
import 'seeders/number_seeder.dart';
import 'seeders/quiz_seeder.dart';
import 'seeders/sentence_seeder.dart';
import 'seeders/vocab_seeder.dart';

Future<void> seedAppContent(WidgetRef ref) async {
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

  final actualAlphabetsId = await AlphabetSeeder.seed(ref, addCategoryIfNew);
  await NumberSeeder.seed(ref, addCategoryIfNew);
  await VocabSeeder.seed(ref, addCategoryIfNew);
  await SentenceSeeder.seed(ref, addCategoryIfNew);
  await GreetingSeeder.seed(ref, addCategoryIfNew);

  await QuizSeeder.seed(ref, actualAlphabetsId);
}
