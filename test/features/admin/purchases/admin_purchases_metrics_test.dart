import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/domain/purchase_metrics_calculator.dart';
import 'package:itun/features/admin/presentation/common/safe_csv_helper.dart';
import 'package:itun/shared/models/content_models.dart';

void main() {
  group('Purchases Metrics & Revenue Calculation', () {
    final testPurchases = [
      PurchaseModel(
        id: 'p1',
        userId: 'user_1',
        categoryId: 'santali_basics',
        unlockMethod: 'razorpay',
        amountPaidInr: 299,
        razorpayPaymentId: 'pay_12345',
        razorpayOrderId: 'order_12345',
        status: 'verified',
        purchasedAt: '2026-08-20T10:00:00Z',
        verifiedAt: '2026-08-20T10:00:05Z',
      ),
      PurchaseModel(
        id: 'p2',
        userId: 'user_2',
        categoryId: 'santali_advanced',
        unlockMethod: 'razorpay',
        amountPaidInr: 499,
        razorpayPaymentId: 'pay_67890',
        razorpayOrderId: 'order_67890',
        status: 'verified',
        purchasedAt: '2026-08-20T11:00:00Z',
        verifiedAt: '2026-08-20T11:00:05Z',
      ),
      PurchaseModel(
        id: 'p3',
        userId: 'user_3',
        categoryId: 'santali_basics',
        unlockMethod: 'razorpay',
        amountPaidInr: 299,
        razorpayPaymentId: 'pay_failed',
        razorpayOrderId: 'order_failed',
        status: 'failed',
        purchasedAt: '2026-08-20T12:00:00Z',
      ),
      PurchaseModel(
        id: 'p4',
        userId: 'user_4',
        categoryId: 'santali_basics',
        unlockMethod: 'play_store_review',
        amountPaidInr: 0,
        status: 'verified',
        purchasedAt: '2026-08-20T13:00:00Z',
      ),
      PurchaseModel(
        id: 'p5',
        userId: 'user_5',
        categoryId: 'santali_grammar',
        unlockMethod: 'razorpay',
        amountPaidInr: 199,
        razorpayPaymentId: 'pay_refunded',
        razorpayOrderId: 'order_refunded',
        status: 'refunded',
        purchasedAt: '2026-08-19T10:00:00Z',
      ),
    ];

    test(
      'calculates gross collected revenue including original payments later refunded',
      () {
        final metrics = PurchaseMetricsCalculator.calculate(testPurchases);
        // 299 (p1 verified) + 499 (p2 verified) + 199 (p5 refunded) = 997
        expect(metrics.grossCollectedInr, 997);
      },
    );

    test('calculates refunded amount from confirmed refunded purchases', () {
      final metrics = PurchaseMetricsCalculator.calculate(testPurchases);
      // 199 (p5 refunded)
      expect(metrics.refundedInr, 199);
      expect(metrics.refundedCount, 1);
    });

    test(
      'calculates net revenue accurately as gross minus refunded without double deduction',
      () {
        final metrics = PurchaseMetricsCalculator.calculate(testPurchases);
        // 997 gross - 199 refunded = 798 net
        expect(metrics.netRevenueInr, 798);
      },
    );

    test('calculates verified paid share (paid / total verified unlocks)', () {
      final metrics = PurchaseMetricsCalculator.calculate(testPurchases);
      // 2 active paid / (2 active paid + 1 review unlock) = 66.7%
      expect(metrics.verifiedPaidShare.toStringAsFixed(1), '66.7');
    });

    test('builds formula-safe CSV export for purchase records', () {
      final headers = [
        'Purchase ID',
        'User ID',
        'Category ID',
        'Unlock Method',
        'Amount (INR)',
        'Status',
      ];
      final rows = testPurchases.map((p) {
        return <Object?>[
          p.id,
          p.userId,
          p.categoryId,
          p.unlockMethod,
          p.amountPaidInr,
          p.status,
        ];
      }).toList();

      final csv = SafeCsvHelper.buildCsv(headers: headers, rows: rows);
      expect(csv, contains('Purchase ID,User ID,Category ID'));
      expect(csv, contains('p1,user_1,santali_basics,razorpay,299,verified'));
      expect(
        csv,
        contains('p4,user_4,santali_basics,play_store_review,0,verified'),
      );
    });
  });
}
