import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:itun/core/logging/app_logger.dart';

import '../../core/api/admin_content_client.dart';
import '../../core/api/edge_json_client.dart';
import '../../core/config/cloudflare_config.dart';
import '../../core/storage/cache_service.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../models/content_models.dart';

/// HTTP client for banners Worker reads (overridable in tests).
final bannersHttpClientProvider = Provider<http.Client>(
  (ref) => ref.watch(edgeHttpClientProvider),
);

final bannersProvider =
    AsyncNotifierProvider<BannersNotifier, List<FeaturedBannerModel>>(
      BannersNotifier.new,
    );

// Alias for backward compatibility
final featuredBannersProvider = bannersProvider;

/// Featured banners: cache-first, then refreshed from the Cloudflare Worker.
///
/// The cached list (if any) is emitted immediately while the network request
/// is in flight; the remote result then replaces it (an empty Worker list is
/// authoritative). A network failure keeps the cached list, or yields an
/// empty list when nothing is cached.
class BannersNotifier extends AsyncNotifier<List<FeaturedBannerModel>> {
  static const String _collectionId = 'banners';
  static const String _cacheKey = 'cached_banners';

  final http.Client? _injectedClient;

  BannersNotifier({http.Client? httpClient}) : _injectedClient = httpClient;

  http.Client get _client =>
      _injectedClient ?? ref.read(bannersHttpClientProvider);

  @override
  FutureOr<List<FeaturedBannerModel>> build() async {
    // Re-create the notifier when the auth state changes.
    ref.watch(isAuthenticatedProvider);
    var active = true;
    ref.onDispose(() => active = false);

    final cached = await CacheService.getList(
      _cacheKey,
      FeaturedBannerModel.fromJson,
    );
    if (active && cached != null) state = AsyncValue.data(cached);

    try {
      final rows = await EdgeJsonClient.getList(
        _client,
        Uri.parse(CloudflareConfig.bannersEndpoint),
        'banners',
        timeout: const Duration(seconds: 4),
      );
      final banners = <FeaturedBannerModel>[];
      for (final row in rows) {
        try {
          banners.add(FeaturedBannerModel.fromJson(row));
        } catch (e, stack) {
          AppLogger.warning(
            'Skipping malformed banner from Cloudflare',
            name: 'BannersNotifier',
            error: e,
            stackTrace: stack,
          );
        }
      }
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
      return cached ?? const <FeaturedBannerModel>[];
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
        .read(adminContentClientProvider)
        .upsert(_collectionId, item.id, item.toJson(), dropNulls: true),
  );

  Future<void> updateItem(FeaturedBannerModel item) => _mutate(
    'Update',
    () => ref
        .read(adminContentClientProvider)
        .upsert(_collectionId, item.id, item.toJson(), dropNulls: true),
  );

  Future<void> delete(String id) => _mutate(
    'Delete',
    () => ref.read(adminContentClientProvider).delete(_collectionId, id),
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
