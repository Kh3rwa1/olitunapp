import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:itun/core/payments/purchase_repository.dart';
import 'package:itun/core/storage/cache_service.dart';
import 'package:flutter/services.dart';

import 'edge_entitlements_fake.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EdgeEntitlementsFake edge;
  late ProviderContainer container;

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async => '.',
        );
    Hive.init(
      (await Directory.systemTemp.createTemp('test_hive_cache_v3_')).path,
    );
  });

  setUp(() async {
    CacheService.resetForTesting();
    await CacheService.clear();
    edge = EdgeEntitlementsFake();
    container = ProviderContainer(overrides: [edge.override]);
  });

  tearDown(() async {
    container.dispose();
    await CacheService.clear();
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  test(
    'verified purchase -> TTL expires -> device offline -> entitlement remains available with staleCached status',
    () async {
      final repo = container.read(purchaseRepositoryProvider);
      const userId = 'user_123';

      // 1. Initial successful server fetch returns verified entitlement
      edge.answer(userId, ['cat_ol_chiki']);

      final initialResult = await repo.fetchEntitlements(userId);
      expect(initialResult.status, EntitlementStatus.verified);
      expect(initialResult.categoryIds, contains('cat_ol_chiki'));

      // 2. Fast-forward time past TTL by setting entry with short TTL
      const key = 'entitlements:production:$userId';
      await CacheService.set(
        key,
        {
          'ids': ['cat_ol_chiki'],
        },
        ttl: const Duration(milliseconds: 1), // 1ms TTL
      );
      await Future<void>.delayed(
        const Duration(milliseconds: 50),
      ); // wait for expiry

      // Verify CacheService.getStrictlyFresh returns null because it expired
      final normalGet = await CacheService.getStrictlyFresh(
        key,
        (json) => Set<String>.from(json['ids'] as List),
      );
      expect(normalGet, isNull);

      // 3. Device goes offline / server throws exception
      edge.offline();

      // 4. Fetch entitlements again -> recovers stale cache and returns staleCached status
      final offlineResult = await repo.fetchEntitlements(userId);
      expect(offlineResult.status, EntitlementStatus.staleCached);
      expect(offlineResult.isFromCache, isTrue);
      expect(offlineResult.categoryIds, contains('cat_ol_chiki'));
    },
  );
}
