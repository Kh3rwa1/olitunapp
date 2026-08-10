import 'dart:async';
import 'dart:convert';
import 'package:appwrite/appwrite.dart' as appwrite;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/appwrite_db_service.dart';
import '../auth/appwrite_auth_service.dart';
import '../storage/cache_service.dart';
import '../logging/app_logger.dart';

enum EntitlementStatus {
  verified,
  cached,
  staleCached,
  unauthenticated,
  permissionDenied,
  networkUnavailable,
  serverError,
}

class EntitlementResult {
  final Set<String> categoryIds;
  final EntitlementStatus status;
  final String? sanitizedErrorMessage;
  final bool isFromCache;

  const EntitlementResult({
    required this.categoryIds,
    required this.status,
    this.sanitizedErrorMessage,
    this.isFromCache = false,
  });

  bool get hasData => categoryIds.isNotEmpty;
  bool get isSuccess =>
      status == EntitlementStatus.verified ||
      status == EntitlementStatus.cached ||
      status == EntitlementStatus.staleCached;
}

class PurchaseRepository {
  final Ref ref;
  PurchaseRepository(this.ref);

  static String _getCacheKey(String userId) =>
      'entitlements:production:$userId';

  /// Financial entitlement TTL: 5 minutes max
  static const Duration entitlementTtl = Duration(minutes: 5);

  /// Fetch user course entitlements with typed result states and stale cache protection.
  Future<EntitlementResult> fetchEntitlements(
    String userId, {
    bool skipRevalidate = false,
  }) async {
    if (userId.isEmpty) {
      return const EntitlementResult(
        categoryIds: {},
        status: EntitlementStatus.unauthenticated,
        sanitizedErrorMessage: 'User is not authenticated.',
      );
    }

    final userCacheKey = _getCacheKey(userId);

    // Attempt cache first for optimistic UI rendering
    final cached = await CacheService.get(
      userCacheKey,
      (json) => Set<String>.from(json['ids'] as List),
    );

    if (cached != null) {
      if (!skipRevalidate) {
        _triggerRevalidation(userId, userCacheKey, cached);
      }
      return EntitlementResult(
        categoryIds: cached,
        status: EntitlementStatus.cached,
        isFromCache: true,
      );
    }

    return _fetchFromServer(userId, userCacheKey);
  }

  /// Backward-compatible helper returning category IDs set.
  Future<Set<String>> fetchPurchasedCategoryIds(
    String userId, {
    bool skipRevalidate = false,
  }) async {
    final result = await fetchEntitlements(
      userId,
      skipRevalidate: skipRevalidate,
    );
    return result.categoryIds;
  }

  Future<EntitlementResult> _fetchFromServer(
    String userId,
    String userCacheKey,
  ) async {
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

      // Save user-scoped cache with 5 minute TTL
      await CacheService.set(userCacheKey, {
        'ids': categoryIds.toList(),
      }, ttl: entitlementTtl);

      return EntitlementResult(
        categoryIds: categoryIds,
        status: EntitlementStatus.verified,
      );
    } catch (e) {
      AppLogger.debug('❌ fetchPurchasedCategoryIds failed: $e');

      // Attempt to recover stale cache entry if server request fails
      final staleCache = await CacheService.getIgnoringTtl(
        userCacheKey,
        (json) => Set<String>.from(json['ids'] as List),
      );

      if (staleCache != null && staleCache.isNotEmpty) {
        return EntitlementResult(
          categoryIds: staleCache,
          status: EntitlementStatus.staleCached,
          sanitizedErrorMessage:
              'Unable to refresh purchases. Displaying cached entitlements.',
          isFromCache: true,
        );
      }

      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('socketexception') ||
          errorStr.contains('network') ||
          errorStr.contains('connection')) {
        return const EntitlementResult(
          categoryIds: {},
          status: EntitlementStatus.networkUnavailable,
          sanitizedErrorMessage:
              'Network connection unavailable. Please check your internet connection.',
        );
      }

      if (errorStr.contains('401') ||
          errorStr.contains('403') ||
          errorStr.contains('unauthorized') ||
          errorStr.contains('permission')) {
        return const EntitlementResult(
          categoryIds: {},
          status: EntitlementStatus.permissionDenied,
          sanitizedErrorMessage: 'Access denied to purchase records.',
        );
      }

      return const EntitlementResult(
        categoryIds: {},
        status: EntitlementStatus.serverError,
        sanitizedErrorMessage:
            'Service temporarily unavailable. Please try again later.',
      );
    }
  }

  void _triggerRevalidation(
    String userId,
    String userCacheKey,
    Set<String> currentCached,
  ) {
    unawaited(
      Future.microtask(() async {
        try {
          final db = ref.read(appwriteDbServiceProvider);
          final result = await db.listDocuments(
            'course_purchases',
            queries: [
              appwrite.Query.equal('userId', userId),
              appwrite.Query.equal('status', 'verified'),
            ],
          );

          final fresh = result
              .map((doc) {
                final raw = doc['categoryId'];
                if (raw is String) return raw;
                if (raw is Map) {
                  return (raw['\$id'] ?? raw['id'] ?? '') as String;
                }
                return '';
              })
              .where((id) => id.isNotEmpty)
              .toSet();

          if (fresh.length != currentCached.length ||
              !fresh.containsAll(currentCached)) {
            AppLogger.debug(
              'SWR Revalidation: Entitlements changed for user $userId. Updating cache.',
            );
            await CacheService.set(userCacheKey, {
              'ids': fresh.toList(),
            }, ttl: entitlementTtl);
          }
        } catch (e) {
          AppLogger.debug(
            'SWR Revalidation background fetch failed for $userId: $e',
          );
        }
      }),
    );
  }

  /// Purge user-scoped cache upon logout or account change.
  Future<void> clearUserCache(String userId) async {
    if (userId.isNotEmpty) {
      await CacheService.delete(_getCacheKey(userId));
    }
  }

  Future<void> clearAllCaches() async {
    await CacheService.delete('purchased_categories');
  }

  /// Create Razorpay payment order on the server
  Future<Map<String, dynamic>> createRazorpayOrder(
    String categoryId, {
    String? idempotencyKey,
  }) async {
    try {
      final client = ref.read(appwriteAuthServiceProvider).client;
      final functions = appwrite.Functions(client);

      final payload = <String, dynamic>{
        'categoryId': categoryId,
        if (idempotencyKey != null && idempotencyKey.isNotEmpty)
          'idempotencyKey': idempotencyKey,
      };

      final response = await functions.createExecution(
        functionId: 'createRazorpayOrder',
        body: jsonEncode(payload),
      );

      final resBody = jsonDecode(response.responseBody) as Map<String, dynamic>;
      return resBody;
    } catch (e) {
      AppLogger.debug('❌ createRazorpayOrder failed: $e');
      return {
        'ok': false,
        'message': 'Failed to create payment order. Please try again.',
      };
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
      return {
        'ok': false,
        'message': 'Failed to verify purchase. Please try again.',
      };
    }
  }
}

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  return PurchaseRepository(ref);
});
