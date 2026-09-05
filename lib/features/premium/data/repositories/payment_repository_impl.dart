import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:itun/core/logging/app_logger.dart';
import 'package:itun/core/payments/purchase_repository.dart';

/// Server-authorized payment repository implementation for premium course entitlements.
///
/// Wraps underlying [PurchaseRepository] providing idempotent order creation,
/// cryptographic signature verification against Appwrite functions, and
/// safe multi-device purchase restoration.
class PaymentRepositoryImpl {
  final PurchaseRepository _purchaseRepo;

  PaymentRepositoryImpl(this._purchaseRepo);

  /// Creates a Razorpay order idempotently on the backend.
  Future<Map<String, dynamic>> createOrder(
    String categoryId, {
    String? idempotencyKey,
  }) async {
    return _purchaseRepo.createRazorpayOrder(
      categoryId,
      idempotencyKey: idempotencyKey,
    );
  }

  /// Verifies a captured payment server-side via the verifyCoursePurchase function.
  Future<Map<String, dynamic>> verifyPayment({
    required String categoryId,
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    final result = await _purchaseRepo.verifyPurchase(
      categoryId: categoryId,
      paymentId: paymentId,
      orderId: orderId,
      signature: signature,
    );

    if (result['ok'] == true) {
      AppLogger.debug('Payment verified successfully for category $categoryId');
    } else {
      AppLogger.warning(
        'Payment verification failed for category $categoryId: ${result['message']}',
      );
    }

    return result;
  }

  /// Restores user purchases by clearing local entitlement cache and revalidating from the server.
  Future<EntitlementResult> restorePurchases(String userId) async {
    return _purchaseRepo.restorePurchases(userId);
  }

  /// Checks whether a specific course/category has a verified active entitlement.
  Future<bool> isCategoryUnlocked(String userId, String categoryId) async {
    final result = await _purchaseRepo.fetchEntitlements(userId);
    return result.categoryIds.contains(categoryId);
  }

  /// Fetches all verified purchased category IDs for a user.
  Future<Set<String>> getPurchasedCategoryIds(String userId) async {
    return _purchaseRepo.fetchPurchasedCategoryIds(userId);
  }
}

final paymentRepositoryProvider = Provider<PaymentRepositoryImpl>((ref) {
  return PaymentRepositoryImpl(ref.watch(purchaseRepositoryProvider));
});
