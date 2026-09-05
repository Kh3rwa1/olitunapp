import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/domain/purchase_metrics_calculator.dart';
import 'package:itun/shared/models/content_models.dart';

void main() {
  group('canonical payment ledger contract', () {
    test('backend JSON maps canonical fields into model and paid metrics', () {
      final purchase = PurchaseModel.fromJson({
        '\$id': 'ledger_1',
        '\$createdAt': '2026-09-05T10:00:00Z',
        'userId': 'user_1',
        'categoryId': 'course_1',
        'provider': 'razorpay',
        'providerOrderId': 'order_1',
        'providerPaymentId': 'payment_1',
        'paidAmount': 499,
        'paidAt': '2026-09-05T10:01:00Z',
        'status': 'verified',
      });
      expect(purchase.unlockMethod, 'razorpay');
      expect(purchase.razorpayOrderId, 'order_1');
      expect(purchase.razorpayPaymentId, 'payment_1');
      expect(purchase.amountPaidInr, 499);
      expect(purchase.purchasedAt, '2026-09-05T10:01:00Z');
      final metrics = PurchaseMetricsCalculator.calculate([purchase]);
      expect(metrics.grossCollectedInr, 499);
      expect(metrics.netRevenueInr, 499);
      expect(metrics.activePaidCount, 1);
    });

    test('canonical values override conflicting legacy values', () {
      final purchase = PurchaseModel.fromJson({
        'provider': 'razorpay',
        'unlockMethod': 'play_store_review',
        'providerPaymentId': 'canonical-payment',
        'razorpayPaymentId': 'legacy-payment',
        'providerOrderId': 'canonical-order',
        'razorpayOrderId': 'legacy-order',
        'paidAmount': 299,
        'amountPaidInr': 999,
        'paidAt': '2026-09-05T00:00:00Z',
        'purchasedAt': '2020-01-01T00:00:00Z',
        'status': 'verified',
      });
      expect(purchase.unlockMethod, 'razorpay');
      expect(purchase.razorpayPaymentId, 'canonical-payment');
      expect(purchase.razorpayOrderId, 'canonical-order');
      expect(purchase.amountPaidInr, 299);
      expect(purchase.purchasedAt, '2026-09-05T00:00:00Z');
    });

    test('legacy documents tolerate null additive schema attributes', () {
      final purchase = PurchaseModel.fromJson({
        '\$id': 'legacy_1',
        'provider': null,
        'paidAmount': null,
        'paidAt': null,
        'unlockMethod': 'razorpay',
        'razorpayPaymentId': 'pay_old',
        'razorpayOrderId': 'order_old',
        'amountPaidInr': 199,
        'purchasedAt': '2025-01-01T00:00:00Z',
        'status': 'verified',
      });
      expect(purchase.amountPaidInr, 199);
      expect(purchase.razorpayPaymentId, 'pay_old');
      expect(purchase.purchasedAt, '2025-01-01T00:00:00Z');
    });

    test('fractional INR is rejected rather than silently rounded', () {
      expect(
        () => PurchaseModel.fromJson({'paidAmount': 299.5}),
        throwsFormatException,
      );
    });

    test('pending expected amount is never decoded as money paid', () {
      final purchase = PurchaseModel.fromJson({
        'provider': 'razorpay',
        'expectedAmount': 499,
        'status': 'pending',
      });
      expect(purchase.amountPaidInr, 0);
      final metrics = PurchaseMetricsCalculator.calculate([purchase]);
      expect(metrics.grossCollectedInr, 0);
      expect(metrics.netRevenueInr, 0);
      expect(metrics.activePaidCount, 0);
    });

    test('canonical zero never falls back to a positive legacy amount', () {
      final purchase = PurchaseModel.fromJson({
        'paidAmount': 0,
        'amountPaidInr': 999,
      });
      expect(purchase.amountPaidInr, 0);
    });

    test('blank dates fall back to ledger creation time', () {
      final purchase = PurchaseModel.fromJson({
        'paidAt': '',
        'purchasedAt': '',
        'createdAt': '2026-09-05T10:00:00Z',
        '\$createdAt': '2026-09-04T10:00:00Z',
      });
      expect(purchase.purchasedAt, '2026-09-05T10:00:00Z');
    });

    test('canonical records survive the existing cache serialization', () {
      final purchase = PurchaseModel.fromJson({
        '\$id': 'canonical',
        'provider': 'razorpay',
        'paidAmount': 199,
        'providerPaymentId': 'pay_199',
        'paidAt': '2026-09-05T10:00:00Z',
        'status': 'verified',
      });
      final decoded = PurchaseModel.fromJson(purchase.toJson());
      expect(decoded.id, purchase.id);
      expect(decoded.amountPaidInr, purchase.amountPaidInr);
      expect(decoded.razorpayPaymentId, purchase.razorpayPaymentId);
      expect(decoded.purchasedAt, purchase.purchasedAt);
    });
  });
}
