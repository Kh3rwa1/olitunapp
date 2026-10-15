import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/shared/providers/letters_provider.dart';
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
      (await Directory.systemTemp.createTemp('test_hive_letters_')).path,
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
    'lettersProvider fetches from Cloudflare Edge first without hitting Appwrite',
    () async {
      final mockHttpClient = MockClient((request) async {
        if (request.url.path.contains('/api/v1/letters')) {
          return http.Response(
            jsonEncode({
              'ok': true,
              'total': 2,
              'letters': [
                {
                  'id': 'edge_letter_1',
                  'charOlChiki': 'ᱚ',
                  'transliterationLatin': 'La',
                  'pronunciation': 'o',
                },
                {
                  'id': 'edge_letter_2',
                  'charOlChiki': 'ᱟ',
                  'transliterationLatin': 'Aah',
                  'pronunciation': 'aa',
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
          lettersHttpClientProvider.overrideWithValue(mockHttpClient),
        ],
      );
      addTearDown(container.dispose);

      final letters = await container.read(lettersProvider.future);
      expect(letters.length, 2);
      expect(letters[0].id, 'edge_letter_1');
      expect(letters[0].charOlChiki, 'ᱚ');
      expect(letters[1].id, 'edge_letter_2');
    },
  );

  ProviderContainer containerWith(http.Client client) {
    final container = ProviderContainer(
      overrides: [lettersHttpClientProvider.overrideWithValue(client)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test(
    'lettersProvider treats an empty Worker list as valid (seed default, no Appwrite)',
    () async {
      final container = containerWith(
        MockClient(
          (request) async =>
              http.Response(jsonEncode({'ok': true, 'letters': []}), 200),
        ),
      );

      final letters = await container.read(lettersProvider.future);
      expect(letters.any((l) => l.charOlChiki == 'ᱚ'), isTrue);
    },
  );

  test(
    'lettersProvider falls back to cached letters when the Worker fails, never Appwrite',
    () async {
      await CacheService.set('cached_letters', [
        {
          'id': 'cached_1',
          'charOlChiki': 'ᱤ',
          'transliterationLatin': 'Li',
          'pronunciation': 'i',
        },
      ]);
      final container = containerWith(
        MockClient((request) async => http.Response('Edge error', 500)),
      );

      final letters = await container.read(lettersProvider.future);
      expect(letters.single.id, 'cached_1');
    },
  );

  test(
    'lettersProvider falls back to seed letters when the Worker fails and nothing is cached',
    () async {
      final container = containerWith(
        MockClient((request) async => http.Response('Edge failure', 500)),
      );

      final letters = await container.read(lettersProvider.future);
      expect(letters.isNotEmpty, isTrue);
      expect(letters.any((l) => l.charOlChiki == 'ᱚ'), isTrue);
    },
  );
}
