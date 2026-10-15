import 'dart:io';

import 'package:flutter/services.dart';

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:itun/core/payments/purchase_repository.dart';
import 'package:itun/core/storage/cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'edge_entitlements_fake.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EdgeEntitlementsFake edge;

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async => '.',
        );
    Hive.init(
      (await Directory.systemTemp.createTemp(
        'test_hive_entitlements_v2_',
      )).path,
    );
  });

  setUp(() async {
    CacheService.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await CacheService.clear();
    edge = EdgeEntitlementsFake();
  });

  tearDown(() async {
    await CacheService.clear();
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(overrides: [edge.override]);
  }

  test(
    'background refund refresh publishes a revision and removes the entitlement',
    () async {
      const userId = 'reactive_refund';
      await CacheService.set('entitlements:production:$userId', {
        'ids': ['refunded'],
      });
      edge.answer(userId, []);
      final container = createContainer();
      addTearDown(container.dispose);
      final changed = Completer<void>();
      container.listen(entitlementRevisionProvider(userId), (_, next) {
        if (next > 0 && !changed.isCompleted) changed.complete();
      });
      final repo = container.read(purchaseRepositoryProvider);
      expect(
        (await repo.fetchEntitlements(userId)).categoryIds,
        contains('refunded'),
      );
      await changed.future.timeout(const Duration(seconds: 5));
      expect(
        (await repo.fetchEntitlements(
          userId,
          skipRevalidate: true,
        )).categoryIds,
        isEmpty,
      );
    },
  );

  test(
    'permission denial revokes fresh cached access and notifies consumers',
    () async {
      const userId = 'denied_access';
      await CacheService.set('entitlements:production:$userId', {
        'ids': ['paid'],
      });
      edge.status(403);
      final container = createContainer();
      addTearDown(container.dispose);
      final changed = Completer<void>();
      container.listen(entitlementRevisionProvider(userId), (_, next) {
        if (next > 0 && !changed.isCompleted) changed.complete();
      });
      final repo = container.read(purchaseRepositoryProvider);
      await repo.fetchEntitlements(userId);
      await changed.future.timeout(const Duration(seconds: 5));
      final result = await repo.fetchEntitlements(userId);
      expect(result.status, EntitlementStatus.permissionDenied);
      expect(result.categoryIds, isEmpty);
      expect(
        await CacheService.getMeta('entitlements:production:$userId'),
        isNull,
      );
    },
  );

  test(
    'logout invalidates an in-flight verification before it can repopulate cache',
    () async {
      const userId = 'logout_race';
      final response = Completer<List<String>>();
      edge.answerLater(userId, response);
      final container = createContainer();
      addTearDown(container.dispose);
      final repo = container.read(purchaseRepositoryProvider);
      final pending = repo.fetchEntitlements(userId);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await repo.clearUserEntitlementCache(userId);
      response.complete(['paid']);
      expect((await pending).categoryIds, isEmpty);
      expect(
        await CacheService.getMeta('entitlements:production:$userId'),
        isNull,
      );
    },
  );

  group('PurchaseRepository - Entitlements & User-Scoped Cache', () {
    test(
      'Case 1: fetchEntitlements returns verified categories from the Worker and caches with user key',
      () async {
        edge.answer('user_456', ['santali_basics', 'santali_intermediate']);

        final container = createContainer();
        addTearDown(container.dispose);

        final repo = container.read(purchaseRepositoryProvider);
        final result = await repo.fetchEntitlements('user_456');

        expect(result.status, EntitlementStatus.verified);
        expect(result.categoryIds, {'santali_basics', 'santali_intermediate'});

        // Second fetch should be served from user-scoped cache
        final cachedResult = await repo.fetchEntitlements('user_456');
        expect(cachedResult.isFromCache, isTrue);
        expect(cachedResult.categoryIds, {
          'santali_basics',
          'santali_intermediate',
        });
      },
    );

    test(
      'Case 2: clearUserEntitlementCache purges user cache so next fetch hits server',
      () async {
        edge.answer('user_789', ['santali_basics']);

        final container = createContainer();
        addTearDown(container.dispose);

        final repo = container.read(purchaseRepositoryProvider);
        await repo.fetchEntitlements('user_789');

        // Purge user entitlement cache
        await repo.clearUserEntitlementCache('user_789');

        // When server returns updated entitlements (e.g. after refund)
        edge.answer('user_789', []);

        final freshResult = await repo.fetchEntitlements('user_789');
        expect(freshResult.status, EntitlementStatus.verified);
        expect(freshResult.categoryIds, isEmpty);
      },
    );

    test(
      'Case 3: refunding one category leaves other verified categories intact',
      () async {
        edge.answer('user_multi', ['santali_basics']);

        final container = createContainer();
        addTearDown(container.dispose);

        final repo = container.read(purchaseRepositoryProvider);
        final result = await repo.fetchEntitlements('user_multi');

        expect(result.categoryIds.contains('santali_basics'), isTrue);
        expect(result.categoryIds.contains('santali_advanced'), isFalse);
      },
    );
  });
}
