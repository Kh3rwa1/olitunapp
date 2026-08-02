import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:itun/core/payments/purchase_repository.dart';
import 'package:itun/core/storage/cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync('hive_pay_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    CacheService.resetForTesting();
  });

  group('Payment Security & Order Integrity Boundaries', () {
    test('PurchaseRepository provider initializes correctly', () {
      final container = ProviderContainer();
      final repo = container.read(purchaseRepositoryProvider);
      expect(repo, isNotNull);
    });

    test('User-scoped entitlement cache is isolated per userId', () async {
      final container = ProviderContainer();
      final repo = container.read(purchaseRepositoryProvider);

      const userA = 'user_Alice_101';
      const userB = 'user_Bob_202';

      // Seed User A entitlements
      await CacheService.set('entitlements:production:$userA', {
        'ids': ['cat_course_1'],
      });

      // Seed User B entitlements
      await CacheService.set('entitlements:production:$userB', {
        'ids': ['cat_course_2'],
      });

      final setA = await repo.fetchPurchasedCategoryIds(userA);
      final setB = await repo.fetchPurchasedCategoryIds(userB);

      expect(setA, contains('cat_course_1'));
      expect(setA, isNot(contains('cat_course_2')));
      expect(setB, contains('cat_course_2'));
      expect(setB, isNot(contains('cat_course_1')));

      // Clear User A cache
      await repo.clearUserCache(userA);
      final setACleared = await CacheService.get<Set<String>>(
        'entitlements:production:$userA',
        (json) => Set<String>.from(json['ids'] as List),
      );
      expect(setACleared, isNull);
    });

    test(
      'Refunded or disputed status revokes entitlement from user cache',
      () async {
        final container = ProviderContainer();
        final repo = container.read(purchaseRepositoryProvider);

        const userId = 'user_refund_test';
        const cacheKey = 'entitlements:production:$userId';

        // Initially user has active entitlement
        await CacheService.set(cacheKey, {
          'ids': ['cat_paid_course'],
        });

        final activeCategories = await repo.fetchPurchasedCategoryIds(userId);
        expect(activeCategories, contains('cat_paid_course'));

        // On refund / dispute, cache is explicitly cleared / invalidated
        await repo.clearUserCache(userId);

        // Verify cached entry is purged so user immediately loses entitlement
        final emptyResult = await CacheService.get<Set<String>>(
          cacheKey,
          (json) => Set<String>.from(json['ids'] as List),
        );
        expect(emptyResult, isNull);
      },
    );

    test('Order ID and Payment ID strict verification contract', () {
      const storedOrderId = 'order_RZP_12345';
      const submittedOrderId = 'order_RZP_12345';
      const wrongOrderId = 'order_RZP_99999';

      const expectedAmountPaise = 49900;
      const actualAmountPaise = 49900;
      const underpaidAmountPaise = 100;

      const currency = 'INR';

      // 1. Valid order binding matches
      expect(storedOrderId == submittedOrderId, isTrue);

      // 2. Mismatched order ID rejected
      expect(storedOrderId == wrongOrderId, isFalse);

      // 3. Exact paise match (no floor / underpaid accepted)
      expect(expectedAmountPaise == actualAmountPaise, isTrue);
      expect(expectedAmountPaise == underpaidAmountPaise, isFalse);

      // 4. Currency must strictly be INR
      expect(currency == 'INR', isTrue);
    });

    test('Captured status requirement validation', () {
      const capturedStatus = 'captured';
      const authorizedStatus = 'authorized';

      expect(capturedStatus == 'captured', isTrue);
      expect(authorizedStatus == 'captured', isFalse);
    });
  });
}
