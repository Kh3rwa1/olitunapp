import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/shared/providers/bakhed_content_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:itun/core/storage/cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
    },
  );

  test(
    'bakhedLearningContentProvider returns empty content when the Worker fails, never Appwrite',
    () async {
      final container = ProviderContainer(
        overrides: [
          bakhedContentHttpClientProvider.overrideWithValue(
            MockClient((request) async => http.Response('Edge error', 500)),
          ),
        ],
      );
      addTearDown(container.dispose);

      final content = await container.read(
        bakhedLearningContentProvider('bakhed_test_2').future,
      );
      expect(content.isEmpty, isTrue);
    },
  );
}
