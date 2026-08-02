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

  group('Payment Security & Order Integrity Tests', () {
    test('PurchaseRepository initializes user-scoped key provider', () {
      final container = ProviderContainer();
      final repo = container.read(purchaseRepositoryProvider);

      expect(repo, isNotNull);
    });

    test('PurchaseRepository fetchPurchasedCategoryIds uses user-scoped cache', () async {
      final container = ProviderContainer();
      final repo = container.read(purchaseRepositoryProvider);

      const userId = 'user_secure_123';
      final cacheKey = 'entitlements:production:$userId';

      // Pre-seed user-scoped cache
      await CacheService.set(cacheKey, {
        'ids': ['cat_ol_chiki_1', 'cat_santali_2']
      });

      final result = await repo.fetchPurchasedCategoryIds(userId);
      expect(result, containsAll(['cat_ol_chiki_1', 'cat_santali_2']));

      // Cleanup
      await repo.clearUserCache(userId);
    });
  });
}
