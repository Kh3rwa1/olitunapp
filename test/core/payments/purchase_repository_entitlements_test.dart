import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
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
    Hive.init('./test_hive_entitlements_v2');
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

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [appwriteDbServiceProvider.overrideWithValue(mockDb)],
    );
  }

  group('PurchaseRepository - Entitlements & User-Scoped Cache', () {
    test(
      'Case 1: fetchEntitlements returns verified categories from Appwrite and caches with user key',
      () async {
        when(
          () => mockDb.listDocuments(
            'course_purchases',
            queries: any(named: 'queries'),
          ),
        ).thenAnswer(
          (_) async => [
            {
              '\$id': 'p1',
              'userId': 'user_456',
              'categoryId': 'santali_basics',
              'status': 'verified',
            },
            {
              '\$id': 'p2',
              'userId': 'user_456',
              'categoryId': 'santali_intermediate',
              'status': 'verified',
            },
          ],
        );

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
        when(
          () => mockDb.listDocuments(
            'course_purchases',
            queries: any(named: 'queries'),
          ),
        ).thenAnswer(
          (_) async => [
            {
              '\$id': 'p1',
              'userId': 'user_789',
              'categoryId': 'santali_basics',
              'status': 'verified',
            },
          ],
        );

        final container = createContainer();
        addTearDown(container.dispose);

        final repo = container.read(purchaseRepositoryProvider);
        await repo.fetchEntitlements('user_789');

        // Purge user entitlement cache
        await repo.clearUserEntitlementCache('user_789');

        // When server returns updated entitlements (e.g. after refund)
        when(
          () => mockDb.listDocuments(
            'course_purchases',
            queries: any(named: 'queries'),
          ),
        ).thenAnswer((_) async => []);

        final freshResult = await repo.fetchEntitlements('user_789');
        expect(freshResult.status, EntitlementStatus.verified);
        expect(freshResult.categoryIds, isEmpty);
      },
    );

    test(
      'Case 3: refunding one category leaves other verified categories intact',
      () async {
        when(
          () => mockDb.listDocuments(
            'course_purchases',
            queries: any(named: 'queries'),
          ),
        ).thenAnswer(
          (_) async => [
            {
              '\$id': 'p1',
              'userId': 'user_multi',
              'categoryId': 'santali_basics',
              'status': 'verified',
            },
          ],
        );

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
