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
import 'package:itun/features/rhymes/domain/rhyme_model.dart';
import 'package:itun/shared/providers/rhymes_providers.dart';
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
      (await Directory.systemTemp.createTemp('test_hive_rhymes_')).path,
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
    'rhymesProvider fetches from Cloudflare Edge first without hitting Appwrite',
    () async {
      final mockHttpClient = MockClient((request) async {
        if (request.url.path.contains('/api/v1/rhymes')) {
          return http.Response(
            jsonEncode({
              'ok': true,
              'total': 1,
              'rhymes': [
                {
                  'id': 'cf_rhyme_1',
                  'titleOlChiki': 'ᱥᱚᱦᱨᱟᱭ',
                  'titleLatin': 'Edge Sohrai',
                  'contentOlChiki': 'ᱡᱚᱦᱟᱨ',
                  'contentLatin': 'Johar',
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
          rhymesProvider.overrideWith(
            () => RhymesNotifier(httpClient: mockHttpClient),
          ),
        ],
      );
      addTearDown(container.dispose);

      final rhymes = await container.read(rhymesProvider.future);
      expect(rhymes, hasLength(1));
      expect(rhymes.first.id, 'cf_rhyme_1');
      expect(rhymes.first.titleLatin, 'Edge Sohrai');
      verifyNever(() => mockDb.listAllDocuments(any()));
    },
  );

  test(
    'rhymesProvider treats an empty Worker list as valid (seed default, no Appwrite)',
    () async {
      final requests = <Uri>[];
      final container = ProviderContainer(
        overrides: [
          isAuthenticatedProvider.overrideWith((ref) => true),
          appwriteDbServiceProvider.overrideWithValue(mockDb),
          rhymesHttpClientProvider.overrideWithValue(
            MockClient((request) async {
              requests.add(request.url);
              return http.Response(jsonEncode({'ok': true, 'rhymes': []}), 200);
            }),
          ),
        ],
      );
      addTearDown(container.dispose);

      final rhymes = await container.read(rhymesProvider.future);
      expect(requests.single.path, '/api/v1/rhymes');
      expect(rhymes, isNotEmpty);
      expect(rhymes.first.id, startsWith('seed_'));
      verifyNever(() => mockDb.listAllDocuments(any()));
    },
  );

  test(
    'rhymesProvider falls back to seedRhymes when the Worker fails and nothing is cached',
    () async {
      final mockHttpClient = MockClient((request) async {
        return http.Response('Edge unavailable', 500);
      });

      final container = ProviderContainer(
        overrides: [
          isAuthenticatedProvider.overrideWith((ref) => true),
          appwriteDbServiceProvider.overrideWithValue(mockDb),
          rhymesProvider.overrideWith(
            () => RhymesNotifier(httpClient: mockHttpClient),
          ),
        ],
      );
      addTearDown(container.dispose);

      final rhymes = await container.read(rhymesProvider.future);
      expect(rhymes, isNotEmpty);
      expect(rhymes.first.titleLatin, contains('Bakhed'));
      verifyNever(() => mockDb.listAllDocuments(any()));
    },
  );

  test('rhymesProvider returns cached rhymes when available', () async {
    final mockHttpClient = MockClient((request) async {
      return http.Response('Edge unavailable', 500);
    });

    final cachedRhyme = RhymeModel(
      id: 'cached_1',
      titleOlChiki: 'ᱥᱚᱦᱨᱟᱭ',
      titleLatin: 'Cached Sohrai',
      contentOlChiki: 'ᱡᱚᱦᱟᱨ',
      contentLatin: 'Johar',
    );
    await CacheService.set('cached_rhymes', [cachedRhyme.toJson()]);

    final container = ProviderContainer(
      overrides: [
        appwriteDbServiceProvider.overrideWithValue(mockDb),
        rhymesProvider.overrideWith(
          () => RhymesNotifier(httpClient: mockHttpClient),
        ),
      ],
    );
    addTearDown(container.dispose);

    final rhymes = await container.read(rhymesProvider.future);
    expect(rhymes.any((r) => r.id == 'cached_1'), isTrue);
    verifyNever(() => mockDb.listAllDocuments(any()));
  });
}
