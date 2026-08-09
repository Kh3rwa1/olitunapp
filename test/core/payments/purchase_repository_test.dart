import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:itun/core/payments/purchase_repository.dart';
import 'package:itun/core/storage/cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync('hive_purchase_test_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    CacheService.resetForTesting();
  });

  group('PurchaseRepository Typed Entitlements & Error Handling Suite', () {
    test('returns unauthenticated status when userId is empty', () async {
      final container = ProviderContainer();
      final repository = container.read(purchaseRepositoryProvider);

      final result = await repository.fetchEntitlements('');

      expect(result.status, EntitlementStatus.unauthenticated);
      expect(result.categoryIds, isEmpty);
      expect(result.sanitizedErrorMessage, contains('not authenticated'));
    });

    test('EntitlementResult helper properties evaluate correctly', () {
      const successResult = EntitlementResult(
        categoryIds: {'cat_1', 'cat_2'},
        status: EntitlementStatus.verified,
      );

      expect(successResult.hasData, isTrue);
      expect(successResult.isSuccess, isTrue);

      const errorResult = EntitlementResult(
        categoryIds: {},
        status: EntitlementStatus.serverError,
        sanitizedErrorMessage: 'Service unavailable',
      );

      expect(errorResult.hasData, isFalse);
      expect(errorResult.isSuccess, isFalse);
      expect(errorResult.sanitizedErrorMessage, 'Service unavailable');
    });

    test('clearUserCache purges user-specific entitlement cache', () async {
      final container = ProviderContainer();
      final repository = container.read(purchaseRepositoryProvider);
      const userId = 'user_test_logout';

      await CacheService.set('entitlements:production:$userId', {
        'ids': ['cat_99'],
      });

      var cachedData = await CacheService.get(
        'entitlements:production:$userId',
        (json) => Set<String>.from(json['ids'] as List),
      );
      expect(cachedData, contains('cat_99'));

      await repository.clearUserCache(userId);

      cachedData = await CacheService.get(
        'entitlements:production:$userId',
        (json) => Set<String>.from(json['ids'] as List),
      );
      expect(cachedData, isNull);
    });
  });
}
