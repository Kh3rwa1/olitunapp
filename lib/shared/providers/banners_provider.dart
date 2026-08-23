import 'package:itun/core/logging/app_logger.dart';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/appwrite_db_service.dart';
import '../../core/storage/cache_service.dart';
import '../models/content_models.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';

final bannersProvider =
    NotifierProvider<BannersNotifier, AsyncValue<List<FeaturedBannerModel>>>(
      BannersNotifier.new,
    );

// Alias for backward compatibility
final featuredBannersProvider = bannersProvider;

class BannersNotifier extends Notifier<AsyncValue<List<FeaturedBannerModel>>> {
  bool _disposed = false;

  @override
  AsyncValue<List<FeaturedBannerModel>> build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    // Re-create the notifier when the auth state changes.
    ref.watch(isAuthenticatedProvider);
    // Deferred: `state` may not be read or written inside build().
    Future.microtask(_loadBanners);
    return const AsyncValue.data(<FeaturedBannerModel>[]);
  }

  static const String _cacheKey = 'cached_banners';

  Future<void> _loadBanners() async {
    final cached = await CacheService.getList(
      _cacheKey,
      FeaturedBannerModel.fromJson,
    );
    if (_disposed) return;
    if (cached != null) {
      state = AsyncValue.data(cached);
    }

    try {
      final db = ref.read(appwriteDbServiceProvider);
      final data = await db.listDocuments(
        'banners',
        queries: [Query.orderAsc('order'), Query.limit(500)],
      );
      if (_disposed) return;
      final banners = data.map(FeaturedBannerModel.fromJson).toList();
      state = AsyncValue.data(banners);
      await CacheService.set(
        _cacheKey,
        banners.map((e) => e.toJson()).toList(),
      );
    } catch (e, stack) {
      AppLogger.debug('❌ load banners FAILED: $e');
      if (_disposed) return;
      if (cached == null) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  Future<void> add(FeaturedBannerModel item) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.createDocument('banners', item.id, item.toJson());
      await _loadBanners();
    } catch (e) {
      AppLogger.debug('❌ add banner FAILED: $e');
    }
  }

  Future<void> update(FeaturedBannerModel item) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.updateDocument('banners', item.id, item.toJson());
      await _loadBanners();
    } catch (e) {
      AppLogger.debug('❌ update banner FAILED: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.deleteDocument('banners', id);
      await _loadBanners();
    } catch (e) {
      AppLogger.debug('❌ delete banner FAILED: $e');
    }
  }

  // Aliases for admin screens
  void addBanner(FeaturedBannerModel item) => add(item);
  void updateBanner(FeaturedBannerModel item) => update(item);
  void deleteBanner(String id) => delete(id);

  Future<void> seed() async => _loadBanners();
}
