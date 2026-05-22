import 'package:itun/core/logging/app_logger.dart';
import 'package:appwrite/appwrite.dart';
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
      id: 'seed_1',
      titleOlChiki: 'ᱤᱥᱤᱱ ᱥᱟᱱᱟᱢ',
      titleLatin: 'Isin Sanam',
      contentOlChiki: 'ᱤᱥᱤᱱ ᱥᱟᱱᱟᱢ ᱨᱮ\nᱵᱤᱨ ᱦᱚᱨ ᱥᱟᱱᱟᱢ',
      contentLatin: 'Isin sanam re\nBir hor sanam',
      category: 'Sohrai',
    ),
    RhymeModel(
      id: 'seed_2',
      titleOlChiki: 'ᱢᱮᱨᱟᱢ ᱯᱟᱥᱤ',
      titleLatin: 'Meram Pasi',
      contentOlChiki: 'ᱢᱮᱨᱟᱢ ᱯᱟᱥᱤ\nᱠᱟᱛᱮ ᱟᱥᱤ',
      contentLatin: 'Meram pasi\nKate asi',
      category: 'Baha',
    ),
  ];

  Future<void> _loadRhymes() async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      final data = await db.listDocuments(
        'rhymes',
        queries: [Query.limit(500)],
      );
      final rhymes = <RhymeModel>[];
      for (final row in data) {
        try {
          final rhyme = RhymeModel.fromJson(row);
          if (rhyme.id.isNotEmpty && rhyme.titleLatin.isNotEmpty) {
            rhymes.add(rhyme);
          }
        } catch (e) {
          AppLogger.debug('Skipping malformed rhyme row: $e');
        }
      }
      state = AsyncValue.data(rhymes.isEmpty ? _seedRhymes : rhymes);
    } catch (e) {
      AppLogger.debug('Error loading rhymes, using seed fallback: $e');
      state = AsyncValue.data(_seedRhymes);
    }
  }

  Future<void> add(RhymeModel item) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.createDocument('rhymes', item.id, item.toJson());
      await _loadRhymes();
    } catch (e) {
      AppLogger.debug('❌ add rhyme FAILED: $e');
    }
  }

  Future<void> update(RhymeModel item) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.updateDocument('rhymes', item.id, item.toJson());
      await _loadRhymes();
    } catch (e) {
      AppLogger.debug('❌ update rhyme FAILED: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.deleteDocument('rhymes', id);
      await _loadRhymes();
    } catch (e) {
      AppLogger.debug('❌ delete rhyme FAILED: $e');
    }
  }

  Future<void> addRhyme(RhymeModel item) async => add(item);
  Future<void> updateRhyme(RhymeModel item) async => update(item);
  Future<void> deleteRhyme(String id) async => delete(id);

  Future<void> seed() async => _loadRhymes();
}

// ============== RHYME CATEGORIES (derived from rhymes) ==============
// The rhyme_categories collection was removed in Phase 5.
// Categories are now derived dynamically from the loaded rhymes.

final rhymeCategoriesProvider =
    Provider<AsyncValue<List<RhymeCategoryModel>>>((ref) {
  final rhymesAsync = ref.watch(rhymesProvider);
  return rhymesAsync.whenData((rhymes) {
    final seen = <String>{};
    final categories = <RhymeCategoryModel>[];
    var order = 0;
    for (final rhyme in rhymes) {
      final name = rhyme.category;
      if (name == null || name.isEmpty || !seen.add(name)) continue;
      categories.add(RhymeCategoryModel(
        id: name,
        nameOlChiki: name,
        nameLatin: name,
        iconName: 'auto_awesome',
        order: order++,
      ));
    }
    categories.sort((a, b) => a.order.compareTo(b.order));
    return categories;
  });
});
