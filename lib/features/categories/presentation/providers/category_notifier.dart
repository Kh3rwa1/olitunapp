import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/catalog/category_entity.dart';
import '../../domain/repositories/category_repository.dart';
import 'category_providers.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../shared/providers/content_providers.dart'
    show FailureException;
import '../../../../shared/providers/language_settings_providers.dart';

final categoryNotifierProvider =
    AsyncNotifierProvider<CategoryNotifier, List<CategoryEntity>>(
      CategoryNotifier.new,
    );

/// Localized category catalog. `build()` performs the fetch directly and
/// re-runs when the auth state or teaching language changes.
class CategoryNotifier extends AsyncNotifier<List<CategoryEntity>> {
  CategoryRepository get _repository => ref.read(categoryRepositoryProvider);

  @override
  FutureOr<List<CategoryEntity>> build() {
    // Rebuild when the auth state changes.
    ref.watch(isAuthenticatedProvider);
    // Rebuild when the teaching language changes (catalog is localized).
    ref.watch(teachingLanguageRevisionProvider);
    return _fetch();
  }

  Future<List<CategoryEntity>> _fetch() async {
    final result = await _repository.getCategories();
    return result.fold(
      (failure) => throw FailureException(failure),
      _deduplicateCategories,
    );
  }

  /// Re-fetches the catalog. Previously loaded data stays visible while the
  /// request is in flight; a failure is surfaced through [state], not thrown.
  Future<void> loadCategories() async {
    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {
      // Already reflected in `state` as AsyncError.
    }
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
    // Failures are ignored here (as before); the form surfaces its own errors.
    if (result.isRight()) await loadCategories();
  }

  Future<void> updateCategory(CategoryEntity category) async {
    final result = await _repository.updateCategory(category);
    // Failures are ignored here (as before); the form surfaces its own errors.
    if (result.isRight()) await loadCategories();
  }

  Future<void> deleteCategory(String id) async {
    final result = await _repository.deleteCategory(id);
    // Failures are ignored here (as before); the form surfaces its own errors.
    if (result.isRight()) await loadCategories();
  }

  Future<void> reorderCategories(int oldIndex, int newIndex) async {
    final current = state.value;
    if (current == null) return;
    final list = List<CategoryEntity>.from(current);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = AsyncData(list);
  }

  Future<void> seed() async {
    await loadCategories();
  }
}
