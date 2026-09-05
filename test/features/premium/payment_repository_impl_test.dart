import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:itun/core/payments/purchase_repository.dart';
import 'package:itun/features/premium/data/repositories/payment_repository_impl.dart';

class _MockPurchaseRepository extends Mock implements PurchaseRepository {}

void main() {
  late _MockPurchaseRepository mockPurchaseRepo;
  late ProviderContainer container;

  setUp(() {
    mockPurchaseRepo = _MockPurchaseRepository();
    container = ProviderContainer(
      overrides: [
        purchaseRepositoryProvider.overrideWithValue(mockPurchaseRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('PaymentRepositoryImpl', () {
    test(
      'createOrder delegates to PurchaseRepository with idempotencyKey',
      () async {
        when(
          () => mockPurchaseRepo.createRazorpayOrder(
            'cat_1',
            idempotencyKey: 'idem_key_1',
          ),
        ).thenAnswer(
          (_) async => {'ok': true, 'orderId': 'ord_1', 'amount': 49900},
        );

        final repo = container.read(paymentRepositoryProvider);
        final result = await repo.createOrder(
          'cat_1',
          idempotencyKey: 'idem_key_1',
        );

        expect(result['ok'], isTrue);
        expect(result['orderId'], 'ord_1');
        verify(
          () => mockPurchaseRepo.createRazorpayOrder(
            'cat_1',
            idempotencyKey: 'idem_key_1',
          ),
        ).called(1);
      },
    );

    test(
      'verifyPayment delegates to PurchaseRepository and returns response',
      () async {
        when(
          () => mockPurchaseRepo.verifyPurchase(
            categoryId: 'cat_1',
            paymentId: 'pay_1',
            orderId: 'ord_1',
            signature: 'sig_1',
          ),
        ).thenAnswer((_) async => {'ok': true, 'message': 'Verified'});

        final repo = container.read(paymentRepositoryProvider);
        final result = await repo.verifyPayment(
          categoryId: 'cat_1',
          paymentId: 'pay_1',
          orderId: 'ord_1',
          signature: 'sig_1',
        );

        expect(result['ok'], isTrue);
        verify(
          () => mockPurchaseRepo.verifyPurchase(
            categoryId: 'cat_1',
            paymentId: 'pay_1',
            orderId: 'ord_1',
            signature: 'sig_1',
          ),
        ).called(1);
      },
    );

    test(
      'restorePurchases forces cache purge and fresh server revalidation',
      () async {
        when(() => mockPurchaseRepo.restorePurchases('user_123')).thenAnswer(
          (_) async => const EntitlementResult(
            categoryIds: {'cat_1', 'cat_2'},
            status: EntitlementStatus.verified,
          ),
        );

        final repo = container.read(paymentRepositoryProvider);
        final result = await repo.restorePurchases('user_123');

        expect(result.status, EntitlementStatus.verified);
        expect(result.categoryIds, containsAll(['cat_1', 'cat_2']));
        verify(() => mockPurchaseRepo.restorePurchases('user_123')).called(1);
      },
    );

    test(
      'isCategoryUnlocked checks if category is in active entitlements',
      () async {
        when(() => mockPurchaseRepo.fetchEntitlements('user_123')).thenAnswer(
          (_) async => const EntitlementResult(
            categoryIds: {'cat_premium'},
            status: EntitlementStatus.verified,
          ),
        );

        final repo = container.read(paymentRepositoryProvider);
        final unlocked = await repo.isCategoryUnlocked(
          'user_123',
          'cat_premium',
        );
        final locked = await repo.isCategoryUnlocked('user_123', 'cat_other');

        expect(unlocked, isTrue);
        expect(locked, isFalse);
      },
    );
  });
}
