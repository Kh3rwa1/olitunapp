import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/appwrite_db_service.dart';
import '../storage/cache_service.dart';
import '../logging/app_logger.dart';

class PurchaseRepository {
  final Ref ref;
  PurchaseRepository(this.ref);

  static const String _cacheKey = 'purchased_categories';

  Future<Set<String>> fetchPurchasedCategoryIds(String userId) async {
    // Attempt cache first
    final cached = await CacheService.get(
      _cacheKey,
      (json) => Set<String>.from(json['ids'] as List),
    );
    if (cached != null) {
      return cached;
    }

    try {
      final db = ref.read(appwriteDbServiceProvider);
      final result = await db.listDocuments(
        'course_purchases',
        queries: [
          Query.equal('userId', userId),
          Query.equal('status', 'verified'),
        ],
      );

      final categoryIds = result
          .map((doc) {
            final raw = doc['categoryId'];
            if (raw is String) return raw;
            if (raw is Map) return (raw['\$id'] ?? raw['id'] ?? '') as String;
            return '';
          })
          .where((id) => id.isNotEmpty)
          .toSet();

      // Save cache (1 day TTL)
      await CacheService.set(_cacheKey, {'ids': categoryIds.toList()});
      return categoryIds;
    } catch (e) {
      AppLogger.debug('❌ fetchPurchasedCategoryIds failed: $e');
      return {};
    }
  }

  Future<void> clearCache() async {
    await CacheService.delete(_cacheKey);
  }
}

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  return PurchaseRepository(ref);
});
