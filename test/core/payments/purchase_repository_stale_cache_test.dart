import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:itun/core/payments/purchase_repository.dart';
import 'package:itun/core/storage/cache_service.dart';
import 'package:itun/core/api/appwrite_db_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter/services.dart';

class MockAppwriteDbService extends Mock implements AppwriteDbService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAppwriteDbService mockDb;
  late ProviderContainer container;

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async => '.',
        );
    Hive.init('./test_hive_cache_v3');
  });

  setUp(() async {
    CacheService.resetForTesting();
    await CacheService.clear();
    mockDb = MockAppwriteDbService();
    container = ProviderContainer(
      overrides: [appwriteDbServiceProvider.overrideWithValue(mockDb)],
    );
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
      when(
        () => mockDb.listDocuments(
          'course_purchases',
          queries: any(named: 'queries'),
        ),
      ).thenAnswer(
        (_) async => [
          {
            '\$id': 'p1',
            'categoryId': 'cat_ol_chiki',
            'userId': userId,
            'status': 'verified',
          },
        ],
      );

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
      when(
        () => mockDb.listDocuments(
          'course_purchases',
          queries: any(named: 'queries'),
        ),
      ).thenThrow(Exception('SocketException: Client error (offline)'));

      // 4. Fetch entitlements again -> recovers stale cache and returns staleCached status
      final offlineResult = await repo.fetchEntitlements(userId);
      expect(offlineResult.status, EntitlementStatus.staleCached);
      expect(offlineResult.isFromCache, isTrue);
      expect(offlineResult.categoryIds, contains('cat_ol_chiki'));
    },
  );
}
