import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/appwrite_db_service.dart';
import '../models/content_models.dart';

final bannersProvider =
    StateNotifierProvider<BannersNotifier, AsyncValue<List<FeaturedBannerModel>>>(
      (ref) => BannersNotifier(ref),
    );

// Alias for backward compatibility
final featuredBannersProvider = bannersProvider;

class BannersNotifier
    extends StateNotifier<AsyncValue<List<FeaturedBannerModel>>> {
  BannersNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadBanners();
  }

  final Ref ref;

  Future<void> _loadBanners() async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      final data = await db.listDocuments(
        'banners',
        queries: [Query.orderAsc('order'), Query.limit(500)],
      );
      state = AsyncValue.data(
        data.map((e) => FeaturedBannerModel.fromJson(e)).toList(),
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> add(FeaturedBannerModel item) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.createDocument('banners', item.id, item.toJson());
      await _loadBanners();
    } catch (e) {
      debugPrint('❌ add banner FAILED: $e');
    }
  }

  Future<void> update(FeaturedBannerModel item) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.updateDocument('banners', item.id, item.toJson());
      await _loadBanners();
    } catch (e) {
      debugPrint('❌ update banner FAILED: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.deleteDocument('banners', id);
      await _loadBanners();
    } catch (e) {
      debugPrint('❌ delete banner FAILED: $e');
    }
  }

  // Aliases for admin screens
  void addBanner(FeaturedBannerModel item) => add(item);
  void updateBanner(FeaturedBannerModel item) => update(item);
  void deleteBanner(String id) => delete(id);

  Future<void> seed() async => _loadBanners();
}
