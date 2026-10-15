import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analytics/analytics_service.dart';
import '../api/appwrite_functions_service.dart';
import '../auth/auth_providers.dart';
import '../logging/app_logger.dart';
import '../storage/hive_service.dart';
import 'pending_verification_store.dart';
import 'purchase_repository.dart';
import 'razorpay_launcher.dart';

/// A Worker-created Razorpay order (`POST /api/v1/payments/order`).
class CheckoutOrder {
  const CheckoutOrder({
    required this.orderId,
    required this.amountInPaise,
    required this.currency,
    required this.keyId,
    required this.categoryId,
    required this.categoryTitle,
  });

  final String orderId;
  final int amountInPaise;
  final String currency;
  final String keyId;
  final String categoryId;
  final String categoryTitle;

  /// Whole rupees when the amount is a round number, else two decimals.
  String get displayAmount => amountInPaise % 100 == 0
      ? '${amountInPaise ~/ 100}'
      : (amountInPaise / 100).toStringAsFixed(2);
}

sealed class OrderOutcome {
  const OrderOutcome();
}

class OrderReady extends OrderOutcome {
  const OrderReady(this.order);
  final CheckoutOrder order;
}

/// Terminal answers from the order route that end the purchase flow.
class OrderRejected extends OrderOutcome {
  const OrderRejected(this.outcome);
  final PurchaseOutcome outcome;
}

enum PurchaseOutcome {
  unlocked,
  alreadyOwned,
  free,
  cancelled,
  failed,
  networkError,
  notConfigured,
  pendingVerification,
  busy,
}

enum _VerifyResult { verified, retryLater, unrecoverable }

typedef PurchaseEventLogger =
    Future<void> Function(String event, String categoryId, String? reason);

/// Runs order → Razorpay → verify against the Cloudflare Worker and keeps a
/// persisted record of paid-but-unverified checkouts for later retry.
class CheckoutService {
  CheckoutService({
    required AppwriteFunctionsService functions,
    required RazorpayLauncher launcher,
    required PendingVerificationStore pendingStore,
    required Future<void> Function(String userId) refreshEntitlements,
    PurchaseEventLogger? logEvent,
  }) : _functions = functions,
       _launcher = launcher,
       _pending = pendingStore,
       _refreshEntitlements = refreshEntitlements,
       _logEvent = logEvent;

  final AppwriteFunctionsService _functions;
  final RazorpayLauncher _launcher;
  final PendingVerificationStore _pending;
  final Future<void> Function(String userId) _refreshEntitlements;
  final PurchaseEventLogger? _logEvent;
  bool _inFlight = false;

  bool get isPurchaseInFlight => _inFlight;

  Future<void> _log(String event, String categoryId, [String? reason]) async {
    try {
      await _logEvent?.call(event, categoryId, reason);
    } catch (e) {
      AppLogger.debug('Purchase analytics failed: $e');
    }
  }

  /// Drops the cached entitlement set so the owned categories refetch.
  Future<void> refreshEntitlements(String userId) =>
      _refreshEntitlements(userId);

  Future<void> logPaywallViewed(String categoryId) =>
      _log(LearningAnalyticsEvents.paywallViewed, categoryId);

  Future<OrderOutcome> createOrder(String categoryId) async {
    final res = await _functions.execute(
      'createRazorpayOrder',
      body: {'categoryId': categoryId},
      usePost: true,
    );
    final body = res.bodyJson ?? const <String, dynamic>{};
    switch (res.statusCode) {
      case 0:
        return const OrderRejected(PurchaseOutcome.networkError);
      case 409:
        return const OrderRejected(PurchaseOutcome.alreadyOwned);
      case 503:
        return const OrderRejected(PurchaseOutcome.notConfigured);
      case 400:
        // Only "already free" means open it; a bad price stays locked.
        final message = (body['message'] ?? '').toString().toLowerCase();
        return OrderRejected(
          message.contains('free')
              ? PurchaseOutcome.free
              : PurchaseOutcome.failed,
        );
    }
    final orderId = (body['orderId'] ?? '').toString();
    final keyId = (body['keyId'] ?? '').toString();
    final amount = body['amount'];
    if (res.statusCode != 200 ||
        body['ok'] != true ||
        orderId.isEmpty ||
        keyId.isEmpty ||
        amount is! num ||
        amount <= 0) {
      return const OrderRejected(PurchaseOutcome.failed);
    }
    return OrderReady(
      CheckoutOrder(
        orderId: orderId,
        amountInPaise: amount.toInt(),
        currency: (body['currency'] ?? 'INR').toString(),
        keyId: keyId,
        categoryId: (body['categoryId'] ?? categoryId).toString(),
        categoryTitle: (body['categoryTitle'] ?? '').toString(),
      ),
    );
  }

  /// Full purchase. Concurrent calls return [PurchaseOutcome.busy] so a double
  /// tap cannot create a second order or open a second checkout.
  Future<PurchaseOutcome> purchase({
    required String userId,
    required String categoryId,
    String? email,
    CheckoutOrder? preparedOrder,
  }) async {
    if (_inFlight) return PurchaseOutcome.busy;
    _inFlight = true;
    try {
      await _log(LearningAnalyticsEvents.purchaseStarted, categoryId);
      final outcome = await _purchase(userId, categoryId, email, preparedOrder);
      if (outcome == PurchaseOutcome.unlocked) {
        await _log(LearningAnalyticsEvents.purchaseSucceeded, categoryId);
      } else if (outcome != PurchaseOutcome.alreadyOwned &&
          outcome != PurchaseOutcome.free) {
        await _log(
          LearningAnalyticsEvents.purchaseFailed,
          categoryId,
          outcome.name,
        );
      }
      return outcome;
    } finally {
      _inFlight = false;
    }
  }

  Future<PurchaseOutcome> _purchase(
    String userId,
    String categoryId,
    String? email,
    CheckoutOrder? preparedOrder,
  ) async {
    var order = preparedOrder;
    if (order == null) {
      final created = await createOrder(categoryId);
      switch (created) {
        case OrderRejected(:final outcome):
          if (outcome == PurchaseOutcome.alreadyOwned) {
            await _refreshEntitlements(userId);
          }
          return outcome;
        case OrderReady(order: final ready):
          order = ready;
      }
    }

    final result = await _launcher.open(
      RazorpayCheckoutRequest(
        keyId: order.keyId,
        orderId: order.orderId,
        amountInPaise: order.amountInPaise,
        currency: order.currency,
        description: order.categoryTitle,
        prefillEmail: email,
      ),
    );
    switch (result) {
      case RazorpayCheckoutCancelled():
        return PurchaseOutcome.cancelled;
      case RazorpayCheckoutFailed(:final isNetworkError):
        return isNetworkError
            ? PurchaseOutcome.networkError
            : PurchaseOutcome.failed;
      case RazorpayCheckoutSuccess():
        final record = PendingVerification(
          userId: userId,
          categoryId: categoryId,
          orderId: result.orderId.isEmpty ? order.orderId : result.orderId,
          paymentId: result.paymentId,
          signature: result.signature,
        );
        // Persist before verifying: the money has moved, so a crash or a
        // failed call must not lose the proof of payment.
        await _pending.save(record);
        final verified = await _verify(record);
        return verified == _VerifyResult.verified
            ? PurchaseOutcome.unlocked
            : PurchaseOutcome.pendingVerification;
    }
  }

  Future<_VerifyResult> _verify(PendingVerification record) async {
    final res = await _functions.execute(
      'verifyCoursePurchase',
      body: {
        'orderId': record.orderId,
        'paymentId': record.paymentId,
        'signature': record.signature,
      },
      usePost: true,
    );
    final body = res.bodyJson ?? const <String, dynamic>{};
    if (res.statusCode == 200 && body['verified'] == true) {
      await _pending.remove(record.orderId);
      await _refreshEntitlements(record.userId);
      return _VerifyResult.verified;
    }
    // Unknown order / settled by another payment: retrying cannot succeed.
    if (res.statusCode == 404 || res.statusCode == 409) {
      await _pending.remove(record.orderId);
      return _VerifyResult.unrecoverable;
    }
    return _VerifyResult.retryLater;
  }

  /// Retries every stored verification for [userId]; returns how many
  /// verified. Called once per app start after sign-in is known.
  Future<int> retryPendingVerifications(String userId) async {
    var verified = 0;
    for (final record in _pending.forUser(userId)) {
      if (await _verify(record) == _VerifyResult.verified) {
        verified++;
        await _log(
          LearningAnalyticsEvents.purchaseSucceeded,
          record.categoryId,
          'retried',
        );
      }
    }
    return verified;
  }
}

final pendingVerificationStoreProvider = Provider<PendingVerificationStore>(
  (ref) => PendingVerificationStore(ref.watch(sharedPreferencesProvider)),
);

final checkoutServiceProvider = Provider<CheckoutService>((ref) {
  final analytics = ref.watch(learningAnalyticsServiceProvider);
  return CheckoutService(
    functions: ref.watch(appwriteFunctionsServiceProvider),
    launcher: ref.watch(razorpayLauncherProvider),
    pendingStore: ref.watch(pendingVerificationStoreProvider),
    refreshEntitlements: (userId) =>
        ref.read(purchaseRepositoryProvider).clearUserEntitlementCache(userId),
    logEvent: (event, categoryId, reason) => analytics.track(
      event,
      source: 'paywall',
      sourceId: categoryId,
      metadata: {'reason': ?reason},
    ),
  );
});

/// Retries paid-but-unverified checkouts once the signed-in user is known.
final pendingPurchaseVerificationRetryProvider = FutureProvider<int>((
  ref,
) async {
  try {
    final user = await ref.watch(currentUserProvider.future);
    if (user == null) return 0;
    return await ref
        .read(checkoutServiceProvider)
        .retryPendingVerifications(user.id);
  } catch (e) {
    AppLogger.debug('Pending purchase verification retry failed: $e');
    return 0;
  }
});
