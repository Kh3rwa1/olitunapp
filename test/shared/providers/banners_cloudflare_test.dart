import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/core/api/appwrite_db_service.dart';
import 'package:itun/core/storage/cache_service.dart';
import 'package:itun/features/auth/presentation/providers/auth_providers.dart';
import 'package:itun/shared/providers/banners_provider.dart';
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
      (await Directory.systemTemp.createTemp('test_hive_banners_')).path,
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
    'bannersProvider fetches from Cloudflare Edge first without hitting Appwrite',
    () async {
      final mockHttpClient = MockClient((request) async {
        if (request.url.path.contains('/api/v1/banners')) {
          return http.Response(
            jsonEncode({
              'ok': true,
              'total': 1,
              'banners': [
                {
                  'id': 'cf_banner_1',
                  'title': 'Learn Ol Chiki Today',
                  'subtitle': 'Master reading in 30 days',
                  'order': 0,
                  'isActive': true,
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final container = ProviderContainer(
        overrides: [
          isAuthenticatedProvider.overrideWith((ref) => true),
          appwriteDbServiceProvider.overrideWithValue(mockDb),
          bannersProvider.overrideWith(
            () => BannersNotifier(httpClient: mockHttpClient),
          ),
        ],
      );
      addTearDown(container.dispose);

      final banners = await container.read(bannersProvider.future);
      expect(banners, hasLength(1));
      expect(banners.first.id, 'cf_banner_1');
      expect(banners.first.title, 'Learn Ol Chiki Today');
      verifyNever(() => mockDb.listAllDocuments(any()));
    },
  );

  test(
    'bannersProvider falls back to Appwrite DB when Cloudflare edge fails',
    () async {
      final mockHttpClient = MockClient((request) async {
        return http.Response('Edge error', 500);
      });

      when(
        () =>
            mockDb.listAllDocuments('banners', queries: any(named: 'queries')),
      ).thenAnswer(
        (_) async => [
          {
            'id': 'appwrite_banner_1',
            'title': 'Appwrite Fallback Banner',
            'order': 0,
            'isActive': true,
          },
        ],
      );

      final container = ProviderContainer(
        overrides: [
          isAuthenticatedProvider.overrideWith((ref) => true),
          appwriteDbServiceProvider.overrideWithValue(mockDb),
          bannersProvider.overrideWith(
            () => BannersNotifier(httpClient: mockHttpClient),
          ),
        ],
      );
      addTearDown(container.dispose);

      final banners = await container.read(bannersProvider.future);
      expect(banners, hasLength(1));
      expect(banners.first.id, 'appwrite_banner_1');
      expect(banners.first.title, 'Appwrite Fallback Banner');
      verify(
        () =>
            mockDb.listAllDocuments('banners', queries: any(named: 'queries')),
      ).called(1);
    },
  );

  test(
    'bannersProvider gracefully returns empty list when both Edge and Appwrite fail',
    () async {
      final mockHttpClient = MockClient((request) async {
        return http.Response('Edge error', 500);
      });

      when(
        () =>
            mockDb.listAllDocuments('banners', queries: any(named: 'queries')),
      ).thenThrow(Exception('Appwrite offline'));

      final container = ProviderContainer(
        overrides: [
          isAuthenticatedProvider.overrideWith((ref) => true),
          appwriteDbServiceProvider.overrideWithValue(mockDb),
          bannersProvider.overrideWith(
            () => BannersNotifier(httpClient: mockHttpClient),
          ),
        ],
      );
      addTearDown(container.dispose);

      final banners = await container.read(bannersProvider.future);
      expect(banners, isEmpty);
    },
  );
}
