import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/core/api/appwrite_db_service.dart';
import 'package:itun/shared/providers/bakhed_content_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:itun/core/storage/cache_service.dart';

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
      (await Directory.systemTemp.createTemp('test_hive_bakhed_cf_')).path,
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
    'bakhedLearningContentProvider fetches from Cloudflare Edge first without hitting Appwrite',
    () async {
      final mockHttpClient = MockClient((request) async {
        if (request.url.path.contains('/api/v1/bakhed/content') &&
            request.url.queryParameters['id'] == 'bakhed_test_1') {
          return http.Response(
            jsonEncode({
              'ok': true,
              'bakhedId': 'bakhed_test_1',
              'lyrics': [
                {
                  'id': 'l1',
                  'lineIndex': 0,
                  'startMs': 0,
                  'endMs': 1200,
                  'olChiki': 'ᱡᱚᱦᱟᱨ',
                  'latin': 'Johar',
                  'meaning': 'Greetings',
                },
              ],
              'vocabulary': [
                {
                  'id': 'v1',
                  'olChiki': 'ᱥᱮᱨᱮᱧ',
                  'latin': 'Sereng',
                  'meaning': 'Song',
                },
              ],
              'culturalNotes': [
                {'noteId': 'n1', 'title': 'Sohrai', 'body': 'Harvest festival'},
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
          appwriteDbServiceProvider.overrideWithValue(mockDb),
          bakhedContentHttpClientProvider.overrideWithValue(mockHttpClient),
        ],
      );
      addTearDown(container.dispose);

      final content = await container.read(
        bakhedLearningContentProvider('bakhed_test_1').future,
      );
      expect(content.lyrics.length, 1);
      expect(content.lyrics[0].olChiki, 'ᱡᱚᱦᱟᱨ');
      expect(content.vocabulary.length, 1);
      expect(content.vocabulary[0].latin, 'Sereng');
      expect(content.culturalNotes.length, 1);
      expect(content.culturalNotes[0].title, 'Sohrai');
      verifyNever(
        () => mockDb.listAllDocuments(any(), queries: any(named: 'queries')),
      );
    },
  );

  test(
    'bakhedLearningContentProvider falls back to Appwrite DB when Cloudflare edge fails',
    () async {
      final mockHttpClient = MockClient((request) async {
        return http.Response('Edge error', 500);
      });

      when(
        () => mockDb.listAllDocuments(
          'bakhed_lyrics',
          queries: any(named: 'queries'),
        ),
      ).thenAnswer(
        (_) async => [
          {
            '\$id': 'l_db_1',
            'lineIndex': 0,
            'startMs': 0,
            'endMs': 1000,
            'olChiki': 'ᱫᱟᱨᱮ',
            'latin': 'Dare',
            'meaning': 'Tree',
          },
        ],
      );
      when(
        () => mockDb.listAllDocuments(
          'bakhed_vocabulary',
          queries: any(named: 'queries'),
        ),
      ).thenAnswer((_) async => <Map<String, dynamic>>[]);
      when(
        () => mockDb.listAllDocuments(
          'bakhed_cultural_notes',
          queries: any(named: 'queries'),
        ),
      ).thenAnswer((_) async => <Map<String, dynamic>>[]);

      final container = ProviderContainer(
        overrides: [
          appwriteDbServiceProvider.overrideWithValue(mockDb),
          bakhedContentHttpClientProvider.overrideWithValue(mockHttpClient),
        ],
      );
      addTearDown(container.dispose);

      final content = await container.read(
        bakhedLearningContentProvider('bakhed_test_1').future,
      );
      expect(content.lyrics.length, 1);
      expect(content.lyrics[0].olChiki, 'ᱫᱟᱨᱮ');
      verify(
        () => mockDb.listAllDocuments(
          'bakhed_lyrics',
          queries: any(named: 'queries'),
        ),
      ).called(1);
    },
  );
}
