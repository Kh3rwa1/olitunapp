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

    test('canonical fields win over conflicting legacy fields', () {
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

    test('legacy fixture remains readable', () {
      final purchase = PurchaseModel.fromJson({
        '\$id': 'legacy_1',
        'unlockMethod': 'razorpay',
        'razorpayPaymentId': 'pay_old',
        'razorpayOrderId': 'order_old',
        'amountPaidInr': 199,
        'purchasedAt': '2025-01-01T00:00:00Z',
        'status': 'verified',
      });
      expect(purchase.amountPaidInr, 199);
      expect(purchase.razorpayPaymentId, 'pay_old');
    });

    test('fractional INR is rejected instead of silently rounded', () {
      expect(
        () => PurchaseModel.fromJson({'paidAmount': 299.5}),
        throwsFormatException,
      );
    });

    test('pending expected amount is not counted as paid', () {
      final purchase = PurchaseModel.fromJson({
        'provider': 'razorpay',
        'paidAmount': 499,
        'status': 'pending',
      });
      final metrics = PurchaseMetricsCalculator.calculate([purchase]);
      expect(metrics.grossCollectedInr, 0);
      expect(metrics.netRevenueInr, 0);
      expect(metrics.activePaidCount, 0);
    });
  });
}
