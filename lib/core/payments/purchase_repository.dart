import 'dart:convert';
import 'package:appwrite/appwrite.dart' as appwrite;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/appwrite_db_service.dart';
import '../auth/appwrite_auth_service.dart';
import '../storage/cache_service.dart';
import '../logging/app_logger.dart';

class PurchaseRepository {
  final Ref ref;
  PurchaseRepository(this.ref);

  static String _getCacheKey(String userId) => 'entitlements:production:$userId';

  Future<Set<String>> fetchPurchasedCategoryIds(String userId) async {
    if (userId.isEmpty) return {};

    final userCacheKey = _getCacheKey(userId);

    // Attempt cache first (user-scoped)
    final cached = await CacheService.get(
      userCacheKey,
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
          appwrite.Query.equal('userId', userId),
          appwrite.Query.equal('status', 'verified'),
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

      // Save user-scoped cache (1 day TTL)
      await CacheService.set(userCacheKey, {'ids': categoryIds.toList()});
      return categoryIds;
    } catch (e) {
      AppLogger.debug('❌ fetchPurchasedCategoryIds failed: $e');
      return {};
    }
  }

  Future<void> clearUserCache(String userId) async {
    if (userId.isNotEmpty) {
      await CacheService.delete(_getCacheKey(userId));
    }
  }

  Future<void> clearAllCaches() async {
    await CacheService.delete('purchased_categories');
  }

  /// Create Razorpay payment order on the server
  Future<Map<String, dynamic>> createRazorpayOrder(String categoryId) async {
    try {
      final client = ref.read(appwriteAuthServiceProvider).client;
      final functions = appwrite.Functions(client);

      final response = await functions.createExecution(
        functionId: 'createRazorpayOrder',
        body: jsonEncode({'categoryId': categoryId}),
      );

      final resBody = jsonDecode(response.responseBody) as Map<String, dynamic>;
      return resBody;
    } catch (e) {
      AppLogger.debug('❌ createRazorpayOrder failed: $e');
      return {'ok': false, 'message': 'Failed to create order: $e'};
    }
  }

  /// Verify purchase on the server
  Future<Map<String, dynamic>> verifyPurchase({
    required String categoryId,
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    try {
      final client = ref.read(appwriteAuthServiceProvider).client;
      final functions = appwrite.Functions(client);

      final response = await functions.createExecution(
        functionId: 'verifyCoursePurchase',
        body: jsonEncode({
          'unlockMethod': 'razorpay',
          'categoryId': categoryId,
          'razorpayPaymentId': paymentId,
          'razorpayOrderId': orderId,
          'razorpaySignature': signature,
        }),
      );

      final resBody = jsonDecode(response.responseBody) as Map<String, dynamic>;
      return resBody;
    } catch (e) {
      AppLogger.debug('❌ verifyPurchase failed: $e');
      return {'ok': false, 'message': 'Failed to verify purchase: $e'};
    }
  }
}

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  return PurchaseRepository(ref);
});
