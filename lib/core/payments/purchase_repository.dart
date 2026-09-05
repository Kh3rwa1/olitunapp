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

final entitlementRevisionProvider = StateProvider.family<int, String>(
  (ref, userId) => 0,
);

class PurchaseRepository {
  final Ref ref;
  PurchaseRepository(this.ref);
  final Set<String> _revokedUsers = {};
  final Map<String, int> _generations = {};
  bool _disposed = false;
  static const offlineEntitlementGrace = Duration(hours: 24);

  void dispose() {
    _disposed = true;
  }

  void _notify(String userId) {
    if (!_disposed)
      ref.read(entitlementRevisionProvider(userId).notifier).state++;
  }

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
    final meta = await CacheService.getMeta(userCacheKey);
    final cached = await CacheService.get(
      userCacheKey,
      (json) => Set<String>.from(json['ids'] as List),
    );

    if (cached != null &&
        meta != null &&
        !meta.isExpired &&
        !_revokedUsers.contains(userId)) {
      if (!skipRevalidate) {
        _triggerRevalidation(userId, userCacheKey, cached);
      }
      final isStale = meta?.isExpired ?? false;
      return EntitlementResult(
        categoryIds: cached,
        status: isStale
            ? EntitlementStatus.staleCached
            : EntitlementStatus.cached,
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
    final generation = _generations[userId] ?? 0;
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

      if (_disposed || generation != (_generations[userId] ?? 0)) {
        return const EntitlementResult(
          categoryIds: {},
          status: EntitlementStatus.unauthenticated,
        );
      }
      _revokedUsers.remove(userId);
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

      if (_disposed || generation != (_generations[userId] ?? 0)) {
        return const EntitlementResult(
          categoryIds: {},
          status: EntitlementStatus.unauthenticated,
        );
      }
      final errorStr = e.toString().toLowerCase();
      final denied =
          e is appwrite.AppwriteException && (e.code == 401 || e.code == 403) ||
          errorStr.contains('401') ||
          errorStr.contains('403') ||
          errorStr.contains('unauthorized') ||
          errorStr.contains('permission');
      if (denied) {
        final firstDenial = _revokedUsers.add(userId);
        await CacheService.delete(userCacheKey);
        if (firstDenial) _notify(userId);
        return const EntitlementResult(
          categoryIds: {},
          status: EntitlementStatus.permissionDenied,
          sanitizedErrorMessage: 'Access denied to purchase records.',
        );
      }
      final isNetworkFailure =
          e is TimeoutException ||
          (e is appwrite.AppwriteException &&
              (e.code == 0 || e.type == 'network_failure')) ||
          errorStr.contains('socketexception') ||
          errorStr.contains('network') ||
          errorStr.contains('connection');
      if (isNetworkFailure && !_revokedUsers.contains(userId)) {
        final meta = await CacheService.getMeta(userCacheKey);
        final age = meta == null
            ? null
            : DateTime.now().millisecondsSinceEpoch - meta.lastSyncAtMs;
        if (age != null &&
            age >= 0 &&
            age <= offlineEntitlementGrace.inMilliseconds) {
          final stale = await CacheService.getIgnoringTtl(
            userCacheKey,
            (json) => Set<String>.from(json['ids'] as List),
          );
          if (stale != null)
            return EntitlementResult(
              categoryIds: stale,
              status: EntitlementStatus.staleCached,
              isFromCache: true,
              sanitizedErrorMessage:
                  'Offline access is limited to 24 hours since verification.',
            );
        }
        return const EntitlementResult(
          categoryIds: {},
          status: EntitlementStatus.networkUnavailable,
          sanitizedErrorMessage: 'Reconnect to verify your purchases.',
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
      Future<void>(() async {
        if (_disposed) return;
        final fresh = await _fetchFromServer(userId, userCacheKey);
        if (_disposed) return;
        if (fresh.status == EntitlementStatus.verified &&
            (fresh.categoryIds.length != currentCached.length ||
                !fresh.categoryIds.containsAll(currentCached))) {
          _notify(userId);
        }
      }),
    );
  }

  /// Purge user-scoped entitlement cache upon refund, logout or account change.
  Future<void> clearUserEntitlementCache(String userId) async {
    if (userId.isNotEmpty) {
      _generations[userId] = (_generations[userId] ?? 0) + 1;
      await CacheService.delete(_getCacheKey(userId));
      _notify(userId);
    }
  }

  /// Backward-compatible alias for clearUserEntitlementCache.
  Future<void> clearUserCache(String userId) =>
      clearUserEntitlementCache(userId);

  /// Backward-compatible alias for clearing caches.
  Future<void> clearAllCaches() async {
    // Purge legacy key if any still exists
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
  final repo = PurchaseRepository(ref);
  ref.onDispose(repo.dispose);
  return repo;
});
