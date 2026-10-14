import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/core/logging/app_logger.dart';

import '../../core/api/appwrite_db_service.dart';
import '../../core/api/appwrite_query_builders.dart';
import '../../core/storage/cache_service.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../models/content_models.dart';

final bannersProvider =
    AsyncNotifierProvider<BannersNotifier, List<FeaturedBannerModel>>(
      BannersNotifier.new,
    );

// Alias for backward compatibility
final featuredBannersProvider = bannersProvider;

/// Featured banners: cache-first, then refreshed from Appwrite.
///
/// The cached list (if any) is emitted immediately while the network request
/// is in flight; the remote result then replaces it. A network failure keeps
/// the cached list, or surfaces the error when nothing is cached.
class BannersNotifier extends AsyncNotifier<List<FeaturedBannerModel>> {
  static const String _collectionId = 'banners';
  static const String _cacheKey = 'cached_banners';

  @override
  FutureOr<List<FeaturedBannerModel>> build() async {
    // Re-create the notifier when the auth state changes.
    ref.watch(isAuthenticatedProvider);
    final db = ref.read(appwriteDbServiceProvider);
    var active = true;
    ref.onDispose(() => active = false);

    final cached = await CacheService.getList(
      _cacheKey,
      FeaturedBannerModel.fromJson,
    );
    if (active && cached != null) state = AsyncValue.data(cached);

    try {
      final data = await db.listAllDocuments(
        _collectionId,
        queries: [DbQuery.orderAsc('order')],
      );
      final banners = data.map(FeaturedBannerModel.fromJson).toList();
      await CacheService.set(
        _cacheKey,
        banners.map((e) => e.toJson()).toList(),
      );
      return banners;
    } catch (e, stack) {
      AppLogger.warning(
        'Loading banners failed',
        name: 'BannersNotifier',
        error: e,
        stackTrace: stack,
      );
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<void> _mutate(String action, Future<void> Function() write) async {
    try {
      await write();
    } catch (e, stack) {
      AppLogger.error(
        '$action banner failed',
        name: 'BannersNotifier',
        error: e,
        stackTrace: stack,
      );
      return;
    }
    ref.invalidateSelf();
    await future;
  }

  Future<void> add(FeaturedBannerModel item) => _mutate(
    'Add',
    () => ref
        .read(appwriteDbServiceProvider)
        .createDocument(_collectionId, item.id, item.toJson()),
  );

  Future<void> updateItem(FeaturedBannerModel item) => _mutate(
    'Update',
    () => ref
        .read(appwriteDbServiceProvider)
        .updateDocument(_collectionId, item.id, item.toJson()),
  );

  Future<void> delete(String id) => _mutate(
    'Delete',
    () => ref.read(appwriteDbServiceProvider).deleteDocument(_collectionId, id),
  );

  // Aliases for admin screens
  void addBanner(FeaturedBannerModel item) => add(item);
  void updateBanner(FeaturedBannerModel item) => updateItem(item);
  void deleteBanner(String id) => delete(id);

  Future<void> seed() async {
    ref.invalidateSelf();
    await future;
  }
}
