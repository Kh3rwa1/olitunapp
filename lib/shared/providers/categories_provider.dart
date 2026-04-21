import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/appwrite_db_service.dart';
import '../../core/storage/cache_service.dart';
import '../models/content_models.dart';

final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, AsyncValue<List<CategoryModel>>>(
      (ref) => CategoriesNotifier(ref),
    );

class CategoriesNotifier
    extends StateNotifier<AsyncValue<List<CategoryModel>>> {
  CategoriesNotifier(this.ref) : super(AsyncValue.data(_seedCategories)) {
    _loadCategories();
  }

  final Ref ref;
  static const String _cacheKey = 'cached_categories';

  static final List<CategoryModel> _seedCategories = [
    // ... (rest of seeds)
    CategoryModel(
      id: 'seed_alphabet',
      titleOlChiki: 'ᱚᱞ ᱪᱤᱠᱤ',
      titleLatin: 'Alphabet',
      iconName: 'abc',
      gradientPreset: 'skyBlue',
      order: 0,
      totalLessons: 6,
      description: 'Learn the Ol Chiki script letters',
    ),
    CategoryModel(
      id: 'seed_numbers',
      titleOlChiki: 'ᱮᱞᱠᱷᱟ',
      titleLatin: 'Numbers',
      iconName: 'pin',
      gradientPreset: 'sunset',
      order: 1,
      totalLessons: 4,
      description: 'Learn Santali numbers and counting',
    ),
    CategoryModel(
      id: 'seed_words',
      titleOlChiki: 'ᱨᱚᱲ',
      titleLatin: 'Words',
      iconName: 'menu_book',
      gradientPreset: 'forest',
      order: 2,
      totalLessons: 5,
      description: 'Build your Santali vocabulary',
    ),
    CategoryModel(
      id: 'seed_sentences',
      titleOlChiki: 'ᱣᱟᱠᱭ',
      titleLatin: 'Sentences',
      iconName: 'chat_bubble',
      gradientPreset: 'ocean',
      order: 3,
      totalLessons: 4,
      description: 'Form sentences in Santali',
    ),
  ];

  Future<void> _loadCategories() async {
    // 1. Try to load from Cache first for instant UI response
    final cached = await CacheService.getList(_cacheKey, (json) => CategoryModel.fromJson(json));
    if (cached != null && cached.isNotEmpty) {
      state = AsyncValue.data(cached);
    }

    // 2. Fetch from network
    try {
      final db = ref.read(appwriteDbServiceProvider);
      final data = await db.listDocuments(
        'categories',
        queries: [Query.orderAsc('order'), Query.limit(500)],
      );
      final list = data.map((e) => CategoryModel.fromJson(e)).toList();
      
      if (list.isNotEmpty) {
        state = AsyncValue.data(list);
        
        // 3. Save to cache
        await CacheService.set(_cacheKey, list.map((e) => e.toJson()).toList());
      }
    } catch (e) {
      debugPrint('❌ _loadCategories network FAILED: $e');
      
      // If we don't have state yet (no cache or network), use seeds
      if (!state.hasValue || state.value!.isEmpty) {
        state = AsyncValue.data(_seedCategories);
      }
    }
  }

  Future<void> refresh() async => _loadCategories();

  Future<void> add(CategoryModel item) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.createDocument('categories', item.id, item.toJson());
      await _loadCategories();
    } catch (e) {
      debugPrint('❌ add category FAILED: $e');
    }
  }

  Future<void> update(CategoryModel item) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.updateDocument('categories', item.id, item.toJson());
      await _loadCategories();
    } catch (e) {
      debugPrint('❌ update category FAILED: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.deleteDocument('categories', id);
      await _loadCategories();
    } catch (e) {
      debugPrint('❌ delete category FAILED: $e');
    }
  }

  // Aliases for admin screens
  void addCategory(CategoryModel item) => add(item);
  void updateCategory(CategoryModel item) => update(item);
  void deleteCategory(String id) => delete(id);

  Future<void> reorderCategories(int oldIndex, int newIndex) async {
    final current = state.value ?? [];
    if (oldIndex < 0 ||
        oldIndex >= current.length ||
        newIndex < 0 ||
        newIndex >= current.length) {
      return;
    }

    final updated = [...current];
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);

    for (int i = 0; i < updated.length; i++) {
      updated[i] = updated[i].copyWith(order: i);
    }
    state = AsyncValue.data(updated);
  }

  Future<void> seed() async {
    state = const AsyncValue.loading();
    _loadCategories();
  }
}
