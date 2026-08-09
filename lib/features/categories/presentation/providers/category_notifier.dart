import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/category_repository.dart';
import 'category_providers.dart';

import '../../../auth/presentation/providers/auth_providers.dart';

final categoryNotifierProvider =
    StateNotifierProvider<CategoryNotifier, AsyncValue<List<CategoryEntity>>>((
      ref,
    ) {
      ref.watch(isAuthenticatedProvider);
      return CategoryNotifier(ref.watch(categoryRepositoryProvider));
    });

class CategoryNotifier extends StateNotifier<AsyncValue<List<CategoryEntity>>> {
  final CategoryRepository _repository;

  CategoryNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    if (!mounted) return;
    if (!state.hasValue) {
      state = const AsyncValue.loading();
    }
    final result = await _repository.getCategories();
    if (!mounted) return;
    result.fold(
      (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
      (categories) =>
          state = AsyncValue.data(_deduplicateCategories(categories)),
    );
  }

  /// Remove duplicate categories. Dedup by document ID first, then by
  /// normalized titleLatin so that seed-created and admin-created entries
  /// with the same logical name don't both appear.
  List<CategoryEntity> _deduplicateCategories(List<CategoryEntity> categories) {
    final seenIds = <String>{};
    final seenTitles = <String>{};
    final unique = <CategoryEntity>[];

    for (final cat in categories) {
      if (seenIds.contains(cat.id)) continue;
      final normTitle = cat.titleLatin.trim().toLowerCase();
      if (seenTitles.contains(normTitle)) continue;
      seenIds.add(cat.id);
      seenTitles.add(normTitle);
      unique.add(cat);
    }
    return unique;
  }

  Future<void> refresh() => loadCategories();

  Future<void> addCategory(CategoryEntity category) async {
    final result = await _repository.createCategory(category);
    if (!mounted) return;
    result.fold(
      (failure) => null, // Handle error
      (_) => loadCategories(),
    );
  }

  Future<void> updateCategory(CategoryEntity category) async {
    final result = await _repository.updateCategory(category);
    if (!mounted) return;
    result.fold(
      (failure) => null, // Handle error
      (_) => loadCategories(),
    );
  }

  Future<void> deleteCategory(String id) async {
    final result = await _repository.deleteCategory(id);
    if (!mounted) return;
    result.fold(
      (failure) => null, // Handle error
      (_) => loadCategories(),
    );
  }

  Future<void> reorderCategories(int oldIndex, int newIndex) async {
    final current = state.value;
    if (current == null) return;
    final list = List<CategoryEntity>.from(current);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = AsyncValue.data(list);
  }

  Future<void> seed() async {
    await loadCategories();
  }
}
