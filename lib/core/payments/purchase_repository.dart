import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../api/appwrite_functions_service.dart';
import '../auth/edge_auth.dart';
import '../config/cloudflare_config.dart';
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
  final http.Client? _httpClient;
  final EdgeAuth? _edgeAuth;
  PurchaseRepository(this.ref, {http.Client? httpClient, EdgeAuth? edgeAuth})
    : _httpClient = httpClient,
      _edgeAuth = edgeAuth;
  final Set<String> _revokedUsers = {};
  final Map<String, int> _generations = {};
  bool _disposed = false;
  static const offlineEntitlementGrace = Duration(hours: 24);

  http.Client get _client => _httpClient ?? http.Client();

  void dispose() {
    _disposed = true;
  }

  void _notify(String userId) {
    if (!_disposed) {
      ref.read(entitlementRevisionProvider(userId).notifier).state++;
    }
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
    final generation = _generations[userId] ?? 0;

    EntitlementResult discarded() => const EntitlementResult(
      categoryIds: {},
      status: EntitlementStatus.unauthenticated,
    );

    // The Worker answers for the user in the session JWT (D1 is the
    // purchase ledger); it never trusts a client-supplied user id.
    final http.Response res;
    try {
      final authHeaders = await _edgeAuth?.headers() ?? const {};
      res = await _client
          .get(
            Uri.parse(CloudflareConfig.paymentsEntitlementsEndpoint),
            headers: {...authHeaders, 'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 6));
    } catch (e) {
      AppLogger.debug('Entitlements fetch failed: $e');
      if (_disposed || generation != (_generations[userId] ?? 0)) {
        return discarded();
      }
      return _offlineResult(userId, userCacheKey);
    }
    if (_disposed || generation != (_generations[userId] ?? 0)) {
      return discarded();
    }

    if (res.statusCode == 401 || res.statusCode == 403) {
      final firstDenial = _revokedUsers.add(userId);
      await CacheService.delete(userCacheKey);
      if (firstDenial) _notify(userId);
      return const EntitlementResult(
        categoryIds: {},
        status: EntitlementStatus.permissionDenied,
        sanitizedErrorMessage: 'Access denied to purchase records.',
      );
    }

    Object? body;
    try {
      body = res.statusCode == 200 ? jsonDecode(res.body) : null;
    } catch (_) {}
    if (body is! Map || body['ok'] != true || body['categoryIds'] is! List) {
      AppLogger.debug('Entitlements fetch HTTP ${res.statusCode}');
      return const EntitlementResult(
        categoryIds: {},
        status: EntitlementStatus.serverError,
        sanitizedErrorMessage:
            'Service temporarily unavailable. Please try again later.',
      );
    }
    // The session belongs to someone else (account switched mid-flight).
    if (body['userId'] != userId) return discarded();

    final categoryIds = (body['categoryIds'] as List)
        .map((e) => e.toString())
        .where((id) => id.isNotEmpty)
        .toSet();
    _revokedUsers.remove(userId);
    await CacheService.set(userCacheKey, {
      'ids': categoryIds.toList(),
    }, ttl: entitlementTtl);
    return EntitlementResult(
      categoryIds: categoryIds,
      status: EntitlementStatus.verified,
    );
  }

  /// Offline: serve the last verified set for up to [offlineEntitlementGrace].
  Future<EntitlementResult> _offlineResult(
    String userId,
    String userCacheKey,
  ) async {
    if (!_revokedUsers.contains(userId)) {
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
        if (stale != null) {
          return EntitlementResult(
            categoryIds: stale,
            status: EntitlementStatus.staleCached,
            isFromCache: true,
            sanitizedErrorMessage:
                'Offline access is limited to 24 hours since verification.',
          );
        }
      }
    }
    return const EntitlementResult(
      categoryIds: {},
      status: EntitlementStatus.networkUnavailable,
      sanitizedErrorMessage: 'Reconnect to verify your purchases.',
    );
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

  /// Forces a fresh re-validation of user purchases from server, bypassing local cache.
  Future<EntitlementResult> restorePurchases(String userId) async {
    await clearUserEntitlementCache(userId);
    return fetchEntitlements(userId, skipRevalidate: true);
  }

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
      final functions = ref.read(appwriteFunctionsServiceProvider);

      final payload = <String, dynamic>{
        'categoryId': categoryId,
        if (idempotencyKey != null && idempotencyKey.isNotEmpty)
          'idempotencyKey': idempotencyKey,
      };

      final response = await functions.execute(
        'createRazorpayOrder',
        body: payload,
        usePost: true,
      );

      final resBody = Map<String, dynamic>.from(response.bodyJson ?? {});
      if (resBody['order'] is Map) {
        final order = resBody['order'] as Map;
        resBody['orderId'] ??= order['id'];
        resBody['amount'] ??= order['amount'];
        resBody['currency'] ??= order['currency'];
        resBody['receipt'] ??= order['receipt'];
      }
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
      final functions = ref.read(appwriteFunctionsServiceProvider);

      final response = await functions.execute(
        'verifyCoursePurchase',
        body: {
          'unlockMethod': 'razorpay',
          'categoryId': categoryId,
          'razorpayPaymentId': paymentId,
          'razorpayOrderId': orderId,
          'razorpaySignature': signature,
          'orderId': orderId,
          'paymentId': paymentId,
          'signature': signature,
        },
        usePost: true,
      );

      final resBody = response.bodyJson ?? {};
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
  final repo = PurchaseRepository(ref, edgeAuth: EdgeAuth.instance);
  ref.onDispose(repo.dispose);
  return repo;
});
