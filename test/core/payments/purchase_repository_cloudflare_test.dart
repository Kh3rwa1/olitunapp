import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/core/api/appwrite_db_service.dart';
import 'package:itun/core/payments/purchase_repository.dart';
import 'package:itun/core/storage/cache_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAppwriteDbService extends Mock implements AppwriteDbService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAppwriteDbService mockDb;

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async => '.',
        );
    Hive.init(
      (await Directory.systemTemp.createTemp(
        'test_hive_cloudflare_entitlements_',
      )).path,
    );
  });

  setUp(() async {
    CacheService.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await CacheService.clear();
    mockDb = MockAppwriteDbService();
  });

  tearDown(() async {
    await CacheService.clear();
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  test(
    'fetches entitlements from Cloudflare Workers D1 first without hitting Appwrite',
    () async {
      var cloudflareHits = 0;
      final mockHttpClient = MockClient((request) async {
        if (request.url.path.contains('/api/v1/payments/entitlements')) {
          cloudflareHits++;
          return http.Response(
            jsonEncode({
              'ok': true,
              'userId': 'user_cf_1',
              'categoryIds': ['course_cat_1', 'course_cat_2'],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final container = ProviderContainer(
        overrides: [
          appwriteDbServiceProvider.overrideWithValue(mockDb),
          purchaseRepositoryProvider.overrideWith(
            (ref) => PurchaseRepository(ref, httpClient: mockHttpClient),
          ),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(purchaseRepositoryProvider);
      final result = await repo.fetchEntitlements('user_cf_1');

      expect(result.status, EntitlementStatus.verified);
      expect(result.categoryIds, {'course_cat_1', 'course_cat_2'});
      expect(cloudflareHits, 1);
      // Appwrite DB should never have been queried
      verifyNever(
        () => mockDb.listDocuments(any(), queries: any(named: 'queries')),
      );
    },
  );

  test(
    'falls back to Appwrite DB when Cloudflare Workers fails and triggers sync',
    () async {
      var syncCalled = false;
      final mockHttpClient = MockClient((request) async {
        if (request.url.path == '/api/v1/payments/entitlements') {
          return http.Response('Edge error', 500);
        }
        if (request.url.path == '/api/v1/payments/entitlements/sync') {
          syncCalled = true;
          return http.Response(jsonEncode({'ok': true, 'synced': 1}), 200);
        }
        return http.Response('Not Found', 404);
      });

      when(
        () => mockDb.listDocuments(
          'course_purchases',
          queries: any(named: 'queries'),
        ),
      ).thenAnswer(
        (_) async => [
          {'categoryId': 'fallback_cat_1', 'status': 'verified'},
        ],
      );

      final container = ProviderContainer(
        overrides: [
          appwriteDbServiceProvider.overrideWithValue(mockDb),
          purchaseRepositoryProvider.overrideWith(
            (ref) => PurchaseRepository(ref, httpClient: mockHttpClient),
          ),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(purchaseRepositoryProvider);
      final result = await repo.fetchEntitlements('user_fallback');

      expect(result.status, EntitlementStatus.verified);
      expect(result.categoryIds, {'fallback_cat_1'});
      verify(
        () => mockDb.listDocuments(
          'course_purchases',
          queries: any(named: 'queries'),
        ),
      ).called(1);

      // Allow async background sync microtask to execute
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(syncCalled, isTrue);
    },
  );
}
