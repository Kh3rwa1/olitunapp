import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/domain/purchase_metrics_calculator.dart';
import 'package:itun/shared/models/content_models.dart';

void main() {
  group('PurchaseMetricsCalculator', () {
    test(
      'calculates ₹997 gross, ₹199 refunded, ₹798 net without double subtraction',
      () {
        final items = [
          PurchaseModel(
            id: 'p1',
            userId: 'user_1',
            categoryId: 'cat_alphabet',
            unlockMethod: 'razorpay',
            amountPaidInr: 299,
            status: 'verified',
            purchasedAt: '2026-08-01T10:00:00Z',
            razorpayPaymentId: 'pay_1',
          ),
          PurchaseModel(
            id: 'p2',
            userId: 'user_2',
            categoryId: 'cat_words',
            unlockMethod: 'razorpay',
            amountPaidInr: 499,
            status: 'verified',
            purchasedAt: '2026-08-02T10:00:00Z',
            razorpayPaymentId: 'pay_2',
          ),
          PurchaseModel(
            id: 'p3',
            userId: 'user_3',
            categoryId: 'cat_numbers',
            unlockMethod: 'razorpay',
            amountPaidInr: 199,
            status: 'refunded',
            purchasedAt: '2026-08-03T10:00:00Z',
            razorpayPaymentId: 'pay_3',
          ),
        ];

        final result = PurchaseMetricsCalculator.calculate(items);

        expect(result.grossCollectedInr, 997);
        expect(result.refundedInr, 199);
        expect(result.netRevenueInr, 798);
        expect(result.verifiedPaidCount, 3);
        expect(result.activePaidCount, 2);
        expect(result.refundedCount, 1);
        expect(result.reviewUnlockCount, 0);
        expect(result.failedCount, 0);
        expect(result.verifiedPaidShare, 100.0);
      },
    );

    test('deduplicates duplicate payment IDs from inflating revenue', () {
      final items = [
        PurchaseModel(
          id: 'doc_1',
          userId: 'user_1',
          categoryId: 'cat_alphabet',
          unlockMethod: 'razorpay',
          amountPaidInr: 299,
          status: 'verified',
          purchasedAt: '2026-08-01T10:00:00Z',
          razorpayPaymentId: 'pay_dup_100',
        ),
        PurchaseModel(
          id: 'doc_2', // duplicate ingestion
          userId: 'user_1',
          categoryId: 'cat_alphabet',
          unlockMethod: 'razorpay',
          amountPaidInr: 299,
          status: 'verified',
          purchasedAt: '2026-08-01T10:00:00Z',
          razorpayPaymentId: 'pay_dup_100',
        ),
      ];

      final result = PurchaseMetricsCalculator.calculate(items);
      expect(result.grossCollectedInr, 299);
      expect(result.netRevenueInr, 299);
      expect(result.activePaidCount, 1);
    });

    test(
      'excludes play store review and failed transactions from gross revenue',
      () {
        final items = [
          PurchaseModel(
            id: 'p1',
            userId: 'user_1',
            categoryId: 'cat_alphabet',
            unlockMethod: 'razorpay',
            amountPaidInr: 299,
            status: 'verified',
            purchasedAt: '2026-08-01T10:00:00Z',
            razorpayPaymentId: 'pay_1',
          ),
          PurchaseModel(
            id: 'p2',
            userId: 'user_2',
            categoryId: 'cat_words',
            unlockMethod: 'play_store_review',
            amountPaidInr: 0,
            status: 'verified',
            purchasedAt: '2026-08-02T10:00:00Z',
          ),
          PurchaseModel(
            id: 'p3',
            userId: 'user_3',
            categoryId: 'cat_numbers',
            unlockMethod: 'razorpay',
            amountPaidInr: 199,
            status: 'failed',
            purchasedAt: '2026-08-03T10:00:00Z',
            razorpayPaymentId: 'pay_failed_1',
          ),
        ];

        final result = PurchaseMetricsCalculator.calculate(items);
        expect(result.grossCollectedInr, 299);
        expect(result.refundedInr, 0);
        expect(result.netRevenueInr, 299);
        expect(result.activePaidCount, 1);
        expect(result.reviewUnlockCount, 1);
        expect(result.failedCount, 1);
        expect(
          result.verifiedPaidShare,
          50.0,
        ); // 1 paid / (1 paid + 1 review) = 50%
      },
    );

    test('handles empty dataset safely', () {
      final result = PurchaseMetricsCalculator.calculate([]);
      expect(result.grossCollectedInr, 0);
      expect(result.refundedInr, 0);
      expect(result.netRevenueInr, 0);
      expect(result.verifiedPaidCount, 0);
      expect(result.verifiedPaidShare, 0.0);
    });
  });
}
