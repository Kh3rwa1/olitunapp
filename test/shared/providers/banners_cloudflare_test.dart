import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/core/storage/cache_service.dart';
import 'package:itun/features/auth/presentation/providers/auth_providers.dart';
import 'package:itun/shared/providers/banners_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
    },
  );

  ProviderContainer containerWith(http.Client client) {
    final container = ProviderContainer(
      overrides: [
        isAuthenticatedProvider.overrideWith((ref) => true),
        bannersHttpClientProvider.overrideWithValue(client),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('bannersProvider treats an empty Worker list as valid', () async {
    final requests = <Uri>[];
    final container = containerWith(
      MockClient((request) async {
        requests.add(request.url);
        return http.Response(jsonEncode({'ok': true, 'banners': []}), 200);
      }),
    );

    final banners = await container.read(bannersProvider.future);
    expect(banners, isEmpty);
    expect(requests.single.path, '/api/v1/banners');
  });

  test(
    'bannersProvider keeps cached banners when the Worker fails, never Appwrite',
    () async {
      await CacheService.set('cached_banners', [
        {'id': 'cached_banner', 'title': 'Cached', 'order': 0},
      ]);
      final container = containerWith(
        MockClient((request) async => http.Response('Edge error', 500)),
      );

      final banners = await container.read(bannersProvider.future);
      expect(banners.single.id, 'cached_banner');
    },
  );

  test(
    'bannersProvider returns an empty list when the Worker fails and nothing is cached',
    () async {
      final container = containerWith(
        MockClient((request) async => http.Response('Edge error', 500)),
      );

      final banners = await container.read(bannersProvider.future);
      expect(banners, isEmpty);
    },
  );
}
