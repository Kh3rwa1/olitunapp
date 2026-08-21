import 'package:flutter_test/flutter_test.dart';
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

    test('calculates gross revenue from verified paid purchases only', () {
      final grossRevenue = testPurchases
          .where((p) => p.status == 'verified' && p.unlockMethod == 'razorpay')
          .fold(0, (sum, p) => sum + p.amountPaidInr);
      expect(grossRevenue, 299 + 499); // 798
    });

    test('calculates refunded amount from refunded purchases', () {
      final refundedAmount = testPurchases
          .where((p) => p.status == 'refunded')
          .fold(0, (sum, p) => sum + p.amountPaidInr);
      expect(refundedAmount, 199);
    });

    test('calculates net revenue accurately as gross minus refunded', () {
      final grossRevenue = testPurchases
          .where((p) => p.status == 'verified' && p.unlockMethod == 'razorpay')
          .fold(0, (sum, p) => sum + p.amountPaidInr);
      final refundedAmount = testPurchases
          .where((p) => p.status == 'refunded')
          .fold(0, (sum, p) => sum + p.amountPaidInr);
      final netRevenue = grossRevenue - refundedAmount;
      expect(netRevenue, 798 - 199); // 599
    });

    test('calculates verified paid share (paid / total verified unlocks)', () {
      final paidCount = testPurchases
          .where((p) => p.unlockMethod == 'razorpay' && p.status == 'verified')
          .length;
      final reviewCount = testPurchases
          .where((p) => p.unlockMethod == 'play_store_review')
          .length;
      final totalVerified = paidCount + reviewCount; // 2 paid + 1 review = 3
      final paidShare = (paidCount / totalVerified * 100).toStringAsFixed(1);
      expect(paidShare, '66.7');
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
