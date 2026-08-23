import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/category_repository.dart';
import 'category_providers.dart';

import '../../../auth/presentation/providers/auth_providers.dart';

final categoryNotifierProvider =
    NotifierProvider<CategoryNotifier, AsyncValue<List<CategoryEntity>>>(
      CategoryNotifier.new,
    );

class CategoryNotifier extends Notifier<AsyncValue<List<CategoryEntity>>> {
  bool _disposed = false;

  CategoryRepository get _repository => ref.read(categoryRepositoryProvider);

  @override
  AsyncValue<List<CategoryEntity>> build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    // Re-create the notifier when the auth state changes.
    ref.watch(isAuthenticatedProvider);
    // Deferred: `state` may not be read or written inside build().
    Future.microtask(loadCategories);
    return const AsyncValue.loading();
  }

  Future<void> loadCategories() async {
    if (_disposed) return;
    if (!state.hasValue) {
      state = const AsyncValue.loading();
    }
    final result = await _repository.getCategories();
    if (_disposed) return;
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
    if (_disposed) return;
    result.fold(
      (failure) => null, // Handle error
      (_) => loadCategories(),
    );
  }

  Future<void> updateCategory(CategoryEntity category) async {
    final result = await _repository.updateCategory(category);
    if (_disposed) return;
    result.fold(
      (failure) => null, // Handle error
      (_) => loadCategories(),
    );
  }

  Future<void> deleteCategory(String id) async {
    final result = await _repository.deleteCategory(id);
    if (_disposed) return;
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
