import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/domain/purchase_metrics_calculator.dart';
import 'package:itun/shared/models/content_models.dart';

PurchaseModel makeTestPurchase({
  required String id,
  required String userId,
  required String categoryId,
  required String unlockMethod,
  required int amountPaidInr,
  required String status,
  String? paymentId,
  String purchasedAt = '2026-08-01T10:00:00Z',
}) {
  return PurchaseModel(
    id: id,
    userId: userId,
    categoryId: categoryId,
    unlockMethod: unlockMethod,
    amountPaidInr: amountPaidInr,
    status: status,
    razorpayPaymentId: paymentId,
    purchasedAt: purchasedAt,
  );
}

void main() {
  group('PurchaseMetricsCalculator - Exhaustive 16-Case Accounting Matrix', () {
    test(
      'Case 1: calculates ₹997 gross, ₹199 refunded, ₹798 net without double subtraction',
      () {
        final items = [
          makeTestPurchase(
            id: 'p1',
            userId: 'user_1',
            categoryId: 'cat_alphabet',
            unlockMethod: 'razorpay',
            amountPaidInr: 299,
            status: 'verified',
            paymentId: 'pay_1',
          ),
          makeTestPurchase(
            id: 'p2',
            userId: 'user_2',
            categoryId: 'cat_words',
            unlockMethod: 'razorpay',
            amountPaidInr: 499,
            status: 'verified',
            paymentId: 'pay_2',
          ),
          makeTestPurchase(
            id: 'p3',
            userId: 'user_3',
            categoryId: 'cat_numbers',
            unlockMethod: 'razorpay',
            amountPaidInr: 199,
            status: 'refunded',
            paymentId: 'pay_3',
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

    test('Case 2: handles multiple refunds accurately', () {
      final items = [
        makeTestPurchase(
          id: 'p1',
          userId: 'u1',
          categoryId: 'cat_1',
          unlockMethod: 'razorpay',
          amountPaidInr: 500,
          status: 'verified',
          paymentId: 'pay_1',
        ),
        makeTestPurchase(
          id: 'p2',
          userId: 'u2',
          categoryId: 'cat_2',
          unlockMethod: 'razorpay',
          amountPaidInr: 200,
          status: 'refunded',
          paymentId: 'pay_2',
        ),
        makeTestPurchase(
          id: 'p3',
          userId: 'u3',
          categoryId: 'cat_3',
          unlockMethod: 'razorpay',
          amountPaidInr: 100,
          status: 'refunded',
          paymentId: 'pay_3',
        ),
      ];

      final result = PurchaseMetricsCalculator.calculate(items);
      expect(result.grossCollectedInr, 800);
      expect(result.refundedInr, 300);
      expect(result.netRevenueInr, 500);
      expect(result.refundedCount, 2);
      expect(result.activePaidCount, 1);
    });

    test('Case 3: handles zero-value purchase', () {
      final items = [
        makeTestPurchase(
          id: 'p0',
          userId: 'u0',
          categoryId: 'cat_free',
          unlockMethod: 'razorpay',
          amountPaidInr: 0,
          status: 'verified',
          paymentId: 'pay_0',
        ),
      ];

      final result = PurchaseMetricsCalculator.calculate(items);
      expect(result.grossCollectedInr, 0);
      expect(result.netRevenueInr, 0);
      expect(result.activePaidCount, 1);
    });

    test('Case 4: clamps negative amounts to 0', () {
      final items = [
        makeTestPurchase(
          id: 'pn',
          userId: 'un',
          categoryId: 'cat_neg',
          unlockMethod: 'razorpay',
          amountPaidInr: -500,
          status: 'verified',
          paymentId: 'pay_neg',
        ),
      ];

      final result = PurchaseMetricsCalculator.calculate(items);
      expect(result.grossCollectedInr, 0);
      expect(result.netRevenueInr, 0);
    });

    test('Case 5: deduplicates duplicate payment IDs', () {
      final items = [
        makeTestPurchase(
          id: 'doc_1',
          userId: 'user_1',
          categoryId: 'cat_alphabet',
          unlockMethod: 'razorpay',
          amountPaidInr: 299,
          status: 'verified',
          paymentId: 'pay_dup_100',
        ),
        makeTestPurchase(
          id: 'doc_2',
          userId: 'user_1',
          categoryId: 'cat_alphabet',
          unlockMethod: 'razorpay',
          amountPaidInr: 299,
          status: 'verified',
          paymentId: 'pay_dup_100',
        ),
      ];

      final result = PurchaseMetricsCalculator.calculate(items);
      expect(result.grossCollectedInr, 299);
      expect(result.netRevenueInr, 299);
      expect(result.activePaidCount, 1);
    });

    test('Case 6: deduplicates duplicate document IDs', () {
      final items = [
        makeTestPurchase(
          id: 'doc_same',
          userId: 'user_1',
          categoryId: 'cat_alphabet',
          unlockMethod: 'razorpay',
          amountPaidInr: 299,
          status: 'verified',
          paymentId: 'pay_a',
        ),
        makeTestPurchase(
          id: 'doc_same',
          userId: 'user_1',
          categoryId: 'cat_alphabet',
          unlockMethod: 'razorpay',
          amountPaidInr: 299,
          status: 'verified',
          paymentId: 'pay_b',
        ),
      ];

      final result = PurchaseMetricsCalculator.calculate(items);
      expect(result.grossCollectedInr, 299);
      expect(result.activePaidCount, 1);
    });

    test('Case 7: blank payment IDs do not collapse unrelated purchases', () {
      final items = [
        makeTestPurchase(
          id: 'doc_1',
          userId: 'u1',
          categoryId: 'cat_1',
          unlockMethod: 'razorpay',
          amountPaidInr: 299,
          status: 'verified',
          paymentId: '',
        ),
        makeTestPurchase(
          id: 'doc_2',
          userId: 'u2',
          categoryId: 'cat_2',
          unlockMethod: 'razorpay',
          amountPaidInr: 299,
          status: 'verified',
          paymentId: '',
        ),
      ];

      final result = PurchaseMetricsCalculator.calculate(items);
      expect(result.grossCollectedInr, 598);
      expect(result.activePaidCount, 2);
    });

    test(
      'Case 8: failed payments are excluded from revenue and increment failedCount',
      () {
        final items = [
          makeTestPurchase(
            id: 'p_fail',
            userId: 'u1',
            categoryId: 'cat_1',
            unlockMethod: 'razorpay',
            amountPaidInr: 299,
            status: 'failed',
            paymentId: 'pay_fail',
          ),
        ];

        final result = PurchaseMetricsCalculator.calculate(items);
        expect(result.grossCollectedInr, 0);
        expect(result.netRevenueInr, 0);
        expect(result.failedCount, 1);
        expect(result.activePaidCount, 0);
      },
    );

    test('Case 9: pending / uncaptured payments are excluded from revenue', () {
      final items = [
        makeTestPurchase(
          id: 'p_pending',
          userId: 'u1',
          categoryId: 'cat_1',
          unlockMethod: 'razorpay',
          amountPaidInr: 299,
          status: 'pending',
          paymentId: 'pay_pending',
        ),
      ];

      final result = PurchaseMetricsCalculator.calculate(items);
      expect(result.grossCollectedInr, 0);
      expect(result.netRevenueInr, 0);
    });

    test(
      'Case 10: review unlocks are counted in volume but excluded from monetary revenue',
      () {
        final items = [
          makeTestPurchase(
            id: 'p_rev',
            userId: 'u1',
            categoryId: 'cat_1',
            unlockMethod: 'play_store_review',
            amountPaidInr: 0,
            status: 'verified',
          ),
        ];

        final result = PurchaseMetricsCalculator.calculate(items);
        expect(result.grossCollectedInr, 0);
        expect(result.reviewUnlockCount, 1);
        expect(result.activePaidCount, 0);
        expect(result.verifiedPaidShare, 0.0);
      },
    );

    test(
      'Case 11: manual / promo unlocks are counted in freeOrManualCount',
      () {
        final items = [
          makeTestPurchase(
            id: 'p_promo',
            userId: 'u1',
            categoryId: 'cat_1',
            unlockMethod: 'promo',
            amountPaidInr: 0,
            status: 'verified',
          ),
        ];

        final result = PurchaseMetricsCalculator.calculate(items);
        expect(result.grossCollectedInr, 0);
        expect(result.freeOrManualCount, 1);
      },
    );

    test('Case 12: unknown status is excluded from revenue', () {
      final items = [
        makeTestPurchase(
          id: 'p_unknown',
          userId: 'u1',
          categoryId: 'cat_1',
          unlockMethod: 'razorpay',
          amountPaidInr: 299,
          status: 'some_unknown_status',
          paymentId: 'pay_un',
        ),
      ];

      final result = PurchaseMetricsCalculator.calculate(items);
      expect(result.grossCollectedInr, 0);
      expect(result.netRevenueInr, 0);
    });

    test('Case 13: unknown unlock method handles status safely', () {
      final items = [
        makeTestPurchase(
          id: 'p_custom',
          userId: 'u1',
          categoryId: 'cat_1',
          unlockMethod: 'unrecognized_gateway',
          amountPaidInr: 500,
          status: 'failed',
        ),
      ];

      final result = PurchaseMetricsCalculator.calculate(items);
      expect(result.failedCount, 1);
      expect(result.grossCollectedInr, 0);
    });

    test('Case 14: empty dataset returns empty result safely', () {
      final result = PurchaseMetricsCalculator.calculate([]);
      expect(result.grossCollectedInr, 0);
      expect(result.refundedInr, 0);
      expect(result.netRevenueInr, 0);
      expect(result.verifiedPaidCount, 0);
      expect(result.verifiedPaidShare, 0.0);
    });

    test('Case 15: preserves isSampledOrPartial flag correctly', () {
      final items = [
        makeTestPurchase(
          id: 'p1',
          userId: 'u1',
          categoryId: 'cat_1',
          unlockMethod: 'razorpay',
          amountPaidInr: 299,
          status: 'verified',
        ),
      ];

      final partialResult = PurchaseMetricsCalculator.calculate(
        items,
        isSampledOrPartial: true,
      );
      expect(partialResult.isSampledOrPartial, isTrue);

      final fullResult = PurchaseMetricsCalculator.calculate(items);
      expect(fullResult.isSampledOrPartial, isFalse);
    });

    test(
      'Case 16: integer arithmetic avoids floating-point calculation errors',
      () {
        final items = [
          makeTestPurchase(
            id: 'p1',
            userId: 'u1',
            categoryId: 'c1',
            unlockMethod: 'razorpay',
            amountPaidInr: 1000000,
            status: 'verified',
          ),
          makeTestPurchase(
            id: 'p2',
            userId: 'u2',
            categoryId: 'c2',
            unlockMethod: 'razorpay',
            amountPaidInr: 333333,
            status: 'refunded',
          ),
        ];

        final result = PurchaseMetricsCalculator.calculate(items);
        expect(result.grossCollectedInr, 1333333);
        expect(result.refundedInr, 333333);
        expect(result.netRevenueInr, 1000000);
      },
    );
  });
}
