import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/appwrite_db_service.dart';
import '../../features/rhymes/domain/rhyme_model.dart';
import '../../features/rhymes/domain/rhyme_category_model.dart';

// ============== RHYMES ==============

final rhymesProvider =
    StateNotifierProvider<RhymesNotifier, AsyncValue<List<RhymeModel>>>(
      RhymesNotifier.new,
    );

class RhymesNotifier extends StateNotifier<AsyncValue<List<RhymeModel>>> {
  RhymesNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadRhymes();
  }

  final Ref ref;

  static final List<RhymeModel> _seedRhymes = [
    RhymeModel(
      id: 'seed_1', titleOlChiki: 'ᱤᱥᱤᱱ ᱥᱟᱱᱟᱢ', titleLatin: 'Isin Sanam',
      contentOlChiki: 'ᱤᱥᱤᱱ ᱥᱟᱱᱟᱢ ᱨᱮ\nᱵᱤᱨ ᱦᱚᱨ ᱥᱟᱱᱟᱢ',
      contentLatin: 'Isin sanam re\nBir hor sanam', category: 'Nature',
    ),
    RhymeModel(
      id: 'seed_2', titleOlChiki: 'ᱢᱮᱨᱟᱢ ᱯᱟᱥᱤ', titleLatin: 'Meram Pasi',
      contentOlChiki: 'ᱢᱮᱨᱟᱢ ᱯᱟᱥᱤ\nᱠᱟᱛᱮ ᱟᱥᱤ',
      contentLatin: 'Meram pasi\nKate asi', category: 'Animal',
    ),
  ];

  Future<void> _loadRhymes() async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      final data = await db.listDocuments('rhymes', queries: [Query.limit(500)]);
      state = AsyncValue.data(data.map(RhymeModel.fromJson).toList());
    } catch (e) {
      state = AsyncValue.data(_seedRhymes);
    }
  }

  Future<void> add(RhymeModel item) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.createDocument('rhymes', item.id, item.toJson());
      await _loadRhymes();
    } catch (e) { debugPrint('❌ add rhyme FAILED: $e'); }
  }

  Future<void> update(RhymeModel item) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.updateDocument('rhymes', item.id, item.toJson());
      await _loadRhymes();
    } catch (e) { debugPrint('❌ update rhyme FAILED: $e'); }
  }

  Future<void> delete(String id) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.deleteDocument('rhymes', id);
      await _loadRhymes();
    } catch (e) { debugPrint('❌ delete rhyme FAILED: $e'); }
  }

  Future<void> addRhyme(RhymeModel item) async => add(item);
  Future<void> updateRhyme(RhymeModel item) async => update(item);
  Future<void> deleteRhyme(String id) async => delete(id);

  Future<void> seed() async => _loadRhymes();
}

// ============== RHYME CATEGORIES ==============

final rhymeCategoriesProvider =
    StateNotifierProvider<RhymeCategoriesNotifier, AsyncValue<List<RhymeCategoryModel>>>(
      RhymeCategoriesNotifier.new,
    );

class RhymeCategoriesNotifier
    extends StateNotifier<AsyncValue<List<RhymeCategoryModel>>> {
  RhymeCategoriesNotifier(this.ref) : super(const AsyncValue.loading()) {
    _load();
  }

  final Ref ref;

  Future<void> _load() async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      final data = await db.listDocuments(
        'rhyme_categories', queries: [Query.orderAsc('order'), Query.limit(500)],
      );
      state = AsyncValue.data(data.map(RhymeCategoryModel.fromJson).toList());
    } catch (e, st) {
      debugPrint('Error loading rhyme categories: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> add(RhymeCategoryModel item) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.createDocument('rhyme_categories', item.id, item.toJson());
      await _load();
    } catch (e) { debugPrint('Error adding rhyme category: $e'); rethrow; }
  }

  Future<void> update(RhymeCategoryModel item) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.updateDocument('rhyme_categories', item.id, item.toJson());
      await _load();
    } catch (e) { debugPrint('Error updating rhyme category: $e'); rethrow; }
  }

  Future<void> delete(String id) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.deleteDocument('rhyme_categories', id);
      await _load();
    } catch (e) { debugPrint('Error deleting rhyme category: $e'); rethrow; }
  }
}

// ============== RHYME SUBCATEGORIES ==============

final rhymeSubcategoriesProvider =
    StateNotifierProvider<RhymeSubcategoriesNotifier, AsyncValue<List<RhymeSubcategoryModel>>>(
      RhymeSubcategoriesNotifier.new,
    );

class RhymeSubcategoriesNotifier
    extends StateNotifier<AsyncValue<List<RhymeSubcategoryModel>>> {
  RhymeSubcategoriesNotifier(this.ref) : super(const AsyncValue.loading()) {
    _load();
  }

  final Ref ref;

  Future<void> _load() async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      final data = await db.listDocuments(
        'rhyme_subcategories', queries: [Query.orderAsc('order'), Query.limit(500)],
      );
      state = AsyncValue.data(data.map(RhymeSubcategoryModel.fromJson).toList());
    } catch (e, st) {
      debugPrint('Error loading rhyme subcategories: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> add(RhymeSubcategoryModel item) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.createDocument('rhyme_subcategories', item.id, item.toJson());
      await _load();
    } catch (e) { debugPrint('Error adding rhyme subcategory: $e'); rethrow; }
  }

  Future<void> update(RhymeSubcategoryModel item) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.updateDocument('rhyme_subcategories', item.id, item.toJson());
      await _load();
    } catch (e) { debugPrint('Error updating rhyme subcategory: $e'); rethrow; }
  }

  Future<void> delete(String id) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.deleteDocument('rhyme_subcategories', id);
      await _load();
    } catch (e) { debugPrint('Error deleting rhyme subcategory: $e'); rethrow; }
  }
}

// Filtered subcategories by category
final rhymeSubcategoriesByCategoryProvider =
    Provider.family<AsyncValue<List<RhymeSubcategoryModel>>, String>((ref, categoryId) {
      final subcatsAsync = ref.watch(rhymeSubcategoriesProvider);
      return subcatsAsync.when(
        data: (subcats) => AsyncValue.data(
          subcats.where((s) => s.categoryId == categoryId).toList(),
        ),
        loading: () => const AsyncValue.loading(),
        error: AsyncValue.error,
      );
    });
