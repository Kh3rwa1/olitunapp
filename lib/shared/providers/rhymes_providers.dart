import 'package:flutter/foundation.dart';
import 'package:itun/core/logging/app_logger.dart';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/appwrite_db_service.dart';
import '../../core/storage/cache_service.dart';
import '../../core/observability/crash_reporting.dart';
import '../../features/rhymes/domain/rhyme_model.dart';
import '../../features/rhymes/domain/rhyme_category_model.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/rhymes/domain/rhyme_catalog.dart';

// ============== RHYMES ==============

final rhymesProvider =
    NotifierProvider<RhymesNotifier, AsyncValue<List<RhymeModel>>>(
      RhymesNotifier.new,
    );

class RhymesNotifier extends Notifier<AsyncValue<List<RhymeModel>>> {
  bool _disposed = false;

  @override
  AsyncValue<List<RhymeModel>> build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    // Re-create the notifier when the auth state changes.
    ref.watch(isAuthenticatedProvider);
    // Deferred: `state` may not be read or written inside build().
    Future.microtask(_loadRhymes);
    return const AsyncValue.loading();
  }

  static const String _cacheKey = 'cached_rhymes';

  static final List<RhymeModel> _seedRhymes = [
    RhymeModel(
      id: 'seed_sohrai',
      titleOlChiki: 'ᱥᱚᱦᱨᱟᱭ ᱵᱟᱠᱷᱮᱬ',
      titleLatin: 'Sohrai Bakhed',
      contentOlChiki:
          'ᱡᱚᱦᱟᱨ ᱛᱚᱵᱮ ᱢᱟᱨᱟᱝ ᱵᱩᱨᱩ, ᱡᱟᱦᱮᱨ ᱮᱨᱟ, ᱢᱚᱬᱮ ᱠᱚ ᱛᱩᱨᱩᱭ ᱠᱚ᱾\nᱜᱟᱹᱭ ᱰᱟᱝᱜᱽᱨᱟ ᱠᱚ ᱥᱟᱨᱠᱚᱜ ᱢᱟ, ᱦᱳᱲᱳ ᱪᱟᱣᱞᱮ ᱯᱮᱨᱮᱡᱚᱜ ᱢᱟ᱾\nᱟᱹᱛᱩ ᱫᱤᱥᱚᱢ ᱥᱩᱠᱷ ᱥᱟᱹᱱᱛᱤ ᱛᱮ ᱛᱟᱦᱮᱸᱱ ᱢᱟ᱾',
      contentLatin:
          'Johar tobe Marang Buru, Jaher Era, Mone ko Turui ko.\nGay dangra ko sarkog ma, horo cawle perejog ma.\nAtu disom sukh santi te tahen ma.',
      category: 'Sohrai',
      tags: ['harvest', 'cattle', 'thanksgiving', 'sacred'],
      isFeatured: true,
    ),
    RhymeModel(
      id: 'seed_baha',
      titleOlChiki: 'ᱵᱟᱦᱟ ᱵᱟᱠᱷᱮᱬ',
      titleLatin: 'Baha Bakhed',
      contentOlChiki:
          'ᱥᱟᱹᱜᱩᱱ ᱵᱟᱦᱟ ᱯᱚᱨᱚᱵᱽ ᱨᱮ ᱥᱟᱨᱡᱚᱢ ᱵᱟᱦᱟ ᱥᱟᱶᱛᱮ ᱡᱚᱦᱟᱨ᱾\nᱫᱷᱟᱹᱨᱛᱤ ᱯᱩᱨᱤ ᱱᱟᱶᱟ ᱥᱟᱠᱟᱢ ᱛᱮ ᱥᱟᱡᱟᱣᱜ ᱠᱟᱱᱟ᱾\nᱥᱟᱱᱟᱢ ᱢᱟᱹᱱᱢᱤ ᱠᱚ ᱨᱟᱹᱥᱠᱟᱹ ᱛᱮ ᱠᱚ ᱮᱱᱮᱡ ᱥᱮᱨᱮᱧ ᱢᱟ᱾',
      contentLatin:
          'Sagun Baha Porob re Sarjom Baha sawte Johar.\nDharti puri nawa sakam te sajawg kana.\nSanam manmi ko raska te ko enej sereny ma.',
      category: 'Baha',
      tags: ['spring', 'sal flower', 'renewal', 'nature'],
    ),
    RhymeModel(
      id: 'seed_karam',
      titleOlChiki: 'ᱠᱟᱨᱟᱢ ᱵᱟᱠᱷᱮᱬ',
      titleLatin: 'Karam Bakhed',
      contentOlChiki:
          'ᱠᱟᱨᱟᱢ ᱫᱟᱨᱮ ᱩᱢᱩᱞ ᱨᱮ ᱵᱚᱭᱦᱟ ᱥᱟᱹᱜᱟᱹᱭ ᱠᱮᱴᱮᱡᱚᱜ ᱢᱟ᱾\nᱫᱷᱚᱱ ᱫᱩᱨᱤᱵᱽ ᱦᱟᱨᱟᱜ ᱢᱟ, ᱡᱤᱣᱤ ᱡᱤᱭᱟᱹᱲ ᱛᱟᱦᱮᱸᱱ ᱢᱟ᱾',
      contentLatin:
          'Karam dare umul re boyha sagay ketejog ma.\nDhon durib harag ma, jiwi jiyar tahen ma.',
      category: 'Karam',
      tags: ['brotherhood', 'prosperity', 'fertility'],
    ),
    RhymeModel(
      id: 'seed_sakrat',
      titleOlChiki: 'ᱥᱟᱠᱨᱟᱛ ᱵᱟᱠᱷᱮᱬ',
      titleLatin: 'Sakrat Bakhed',
      contentOlChiki:
          'ᱯᱤᱴᱷᱟᱹ ᱞᱟᱹᱰᱩ ᱡᱚᱢ ᱥᱟᱶᱛᱮ ᱟᱹᱜᱤᱞ ᱦᱟᱯᱲᱟᱢ ᱠᱚ ᱩᱭᱦᱟᱹᱨ ᱠᱚᱣᱟ ᱵᱚᱱ᱾\nᱵᱷᱮᱡᱟ ᱛᱩᱧ ᱨᱮ ᱡᱤᱛᱠᱟᱹᱨ ᱦᱩᱭᱩᱜ ᱢᱟ᱾',
      contentLatin:
          'Pitha ladu jom sawte agil hapram ko uyhar kowa bon.\nBheja tuny re jitkar huyug ma.',
      category: 'Sakrat',
      tags: ['archery', 'ancestors', 'winter'],
    ),
    RhymeModel(
      id: 'seed_dasae',
      titleOlChiki: 'ᱫᱟᱥᱟᱭ ᱥᱮᱨᱮᱧ',
      titleLatin: 'Dasae Sereng',
      contentOlChiki:
          'ᱦᱟᱭ ᱨᱮ ᱦᱟᱭ ᱫᱤᱥᱚᱢ ᱫᱟᱥᱟᱭ ᱨᱮ,\nᱵᱩᱣᱟᱝ ᱨᱟᱦᱟ ᱛᱮ ᱫᱤᱥᱚᱢ ᱟᱸᱫᱚᱲᱚᱜ ᱠᱟᱱ᱾',
      contentLatin:
          'Hay re hay disom Dasae re,\nBuwang raha te disom andorog kan.',
      category: 'Dasae',
      tags: ['buwang', 'remembrance', 'traditional'],
    ),
    RhymeModel(
      id: 'seed_mage',
      titleOlChiki: 'ᱢᱟᱜᱮ ᱥᱤᱢ ᱵᱟᱠᱷᱮᱬ',
      titleLatin: 'Mage Sim Bakhed',
      contentOlChiki:
          'ᱥᱟᱹᱜᱩᱱ ᱢᱟᱜᱮ ᱪᱟᱸᱫᱚ ᱨᱮ ᱚᱲᱟᱜ ᱫᱩᱣᱟᱹᱨ ᱥᱟᱯᱷᱟ ᱠᱟᱛᱮ ᱡᱚᱦᱟᱨ᱾\nᱥᱟᱱᱟᱢ ᱫᱩᱠᱷ ᱠᱚ ᱥᱟᱦᱟᱜ ᱢᱟ᱾',
      contentLatin:
          'Sagun Mage Cando re orag duwar sapha kate Johar.\nSanam dukh ko sahag ma.',
      category: 'Mage',
      tags: ['hearth', 'purification', 'household'],
    ),
  ];

  Future<void> _loadRhymes() async {
    // 1. Try Cache
    try {
      final cached = await CacheService.getList(_cacheKey, RhymeModel.fromJson);
      if (cached != null && cached.isNotEmpty && !_disposed) {
        state = AsyncValue.data(cached);
      }
    } catch (e) {
      debugPrint('❌ rhymes_providers: Failed to load cached rhymes: $e');
    }

    // 2. Fetch Network
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
          debugPrint('⚠️ rhymes_providers: Skipping malformed rhyme row: $e');
        }
      }

      final resultList = rhymes.isEmpty ? _seedRhymes : rhymes;
      if (!_disposed) {
        state = AsyncValue.data(resultList);
      }

      // 3. Save Cache
      if (rhymes.isNotEmpty) {
        await CacheService.set(
          _cacheKey,
          rhymes.map((e) => e.toJson()).toList(),
        );
      }
    } catch (e, stack) {
      // Critical error logging in production
      debugPrint('❌ rhymes_providers: Error loading rhymes from Appwrite: $e');
      debugPrint(stack.toString());

      CrashReporting.recordError(e, stack);
      CrashReporting.addAppwriteBreadcrumb(
        operation: 'list',
        collection: 'rhymes',
        success: false,
        error: e.toString(),
      );

      if (!_disposed && (!state.hasValue || state.value!.isEmpty)) {
        state = AsyncValue.data(_seedRhymes);
      }
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

final rhymeCategoriesProvider = Provider<AsyncValue<List<RhymeCategoryModel>>>((
  ref,
) {
  final rhymesAsync = ref.watch(rhymesProvider);
  return rhymesAsync.whenData(RhymeCatalog.collectCategories);
});
