import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:itun/core/logging/app_logger.dart';

import '../../core/api/admin_content_client.dart';
import '../../core/api/edge_json_client.dart';
import '../../core/config/cloudflare_config.dart';
import '../../core/observability/crash_reporting.dart';
import '../../core/storage/cache_service.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/rhymes/domain/rhyme_catalog.dart';
import '../../features/rhymes/domain/rhyme_category_model.dart';
import '../../features/rhymes/domain/rhyme_model.dart';

// ============== RHYMES ==============

final rhymesProvider = AsyncNotifierProvider<RhymesNotifier, List<RhymeModel>>(
  RhymesNotifier.new,
);

/// HTTP client for rhymes Worker reads (overridable in tests).
final rhymesHttpClientProvider = Provider<http.Client>(
  (ref) => ref.watch(edgeHttpClientProvider),
);

/// Rhymes: cache-first, refreshed from the Cloudflare Worker, with a bundled
/// seed as the last-resort fallback.
class RhymesNotifier extends AsyncNotifier<List<RhymeModel>> {
  static const String _collectionId = 'rhymes';
  static const String _cacheKey = 'cached_rhymes';

  final http.Client? _httpClient;
  RhymesNotifier({http.Client? httpClient}) : _httpClient = httpClient;

  http.Client get _client => _httpClient ?? ref.read(rhymesHttpClientProvider);

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

  @override
  FutureOr<List<RhymeModel>> build() async {
    // Re-create the notifier when the auth state changes.
    ref.watch(isAuthenticatedProvider);
    var active = true;
    ref.onDispose(() => active = false);

    List<RhymeModel>? cached;
    try {
      cached = await CacheService.getList(_cacheKey, RhymeModel.fromJson);
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to load cached rhymes',
        name: 'RhymesProviders',
        error: e,
        stackTrace: stack,
      );
    }
    final hasCache = cached != null && cached.isNotEmpty;
    if (active && hasCache) state = AsyncValue.data(cached);

    try {
      final rows = await EdgeJsonClient.getList(
        _client,
        Uri.parse(CloudflareConfig.rhymesEndpoint),
        'rhymes',
        timeout: const Duration(seconds: 4),
      );
      final rhymes = <RhymeModel>[];
      for (final row in rows) {
        try {
          final rhyme = RhymeModel.fromJson(row);
          if (rhyme.id.isNotEmpty && rhyme.titleLatin.isNotEmpty) {
            rhymes.add(rhyme);
          }
        } catch (e, stack) {
          AppLogger.warning(
            'Skipping malformed rhyme from Cloudflare',
            name: 'RhymesProviders',
            error: e,
            stackTrace: stack,
          );
        }
      }

      if (rhymes.isEmpty) return _seedRhymes;
      await CacheService.set(_cacheKey, rhymes.map((e) => e.toJson()).toList());
      return rhymes;
    } catch (e, stack) {
      AppLogger.error(
        'Error loading rhymes from Cloudflare',
        name: 'RhymesProviders',
        error: e,
        stackTrace: stack,
      );
      CrashReporting.recordError(e, stack);
      return hasCache ? cached : _seedRhymes;
    }
  }

  Future<void> _mutate(String action, Future<void> Function() write) async {
    try {
      await write();
    } catch (e, stack) {
      AppLogger.error(
        '$action rhyme failed',
        name: 'RhymesProviders',
        error: e,
        stackTrace: stack,
      );
      return;
    }
    ref.invalidateSelf();
    await future;
  }

  Future<void> add(RhymeModel item) => _mutate(
    'Add',
    () => ref
        .read(adminContentClientProvider)
        .upsert(_collectionId, item.id, item.toJson(), dropNulls: true),
  );

  Future<void> updateItem(RhymeModel item) => _mutate(
    'Update',
    () => ref
        .read(adminContentClientProvider)
        .upsert(_collectionId, item.id, item.toJson(), dropNulls: true),
  );

  Future<void> delete(String id) => _mutate(
    'Delete',
    () => ref.read(adminContentClientProvider).delete(_collectionId, id),
  );

  Future<void> addRhyme(RhymeModel item) async => add(item);
  Future<void> updateRhyme(RhymeModel item) async => updateItem(item);
  Future<void> deleteRhyme(String id) async => delete(id);

  Future<void> seed() async {
    ref.invalidateSelf();
    await future;
  }
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
