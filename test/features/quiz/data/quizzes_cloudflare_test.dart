import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/core/storage/cache_service.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/core/auth/auth_providers.dart';
import 'package:itun/shared/providers/learner_content_providers.dart';
import 'package:itun/features/quiz/data/quizzes_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async => '.',
        );
    Hive.init(
      (await Directory.systemTemp.createTemp('test_hive_quizzes_cf_')).path,
    );
  });

  setUp(() async {
    CacheService.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    await CacheService.clear();
  });

  tearDown(() async {
    await CacheService.clear();
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  test(
    'quizzesProvider fetches from Cloudflare Edge first without hitting Appwrite',
    () async {
      final mockHttpClient = MockClient((request) async {
        if (request.url.path.contains('/api/v1/quizzes')) {
          return http.Response(
            jsonEncode({
              'ok': true,
              'total': 1,
              'quizzes': [
                {
                  'id': 'cf_quiz_1',
                  'categoryId': 'cat_alphabets',
                  'title': 'Edge Alphabet Mastery',
                  'level': 'beginner',
                  'order': 0,
                  'isActive': true,
                  'questions': [
                    {
                      'promptOlChiki': 'ᱚ',
                      'promptLatin': 'What sound?',
                      'optionsOlChiki': ['a', 'b', 'c', 'd'],
                      'optionsLatin': ['a', 'b', 'c', 'd'],
                      'correctIndex': 0,
                    },
                  ],
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
          sharedPreferencesProvider.overrideWithValue(prefs),
          isAuthenticatedProvider.overrideWith((ref) => true),
          learnerWordsProvider.overrideWith((ref) => const AsyncValue.data([])),
          learnerSentencesProvider.overrideWith(
            (ref) => const AsyncValue.data([]),
          ),
          quizzesProvider.overrideWith(
            () => QuizzesNotifier(httpClient: mockHttpClient),
          ),
        ],
      );
      addTearDown(container.dispose);

      final quizzes = await container.read(quizzesProvider.future);
      expect(quizzes, isNotEmpty);
      expect(quizzes.any((q) => q.id == 'cf_quiz_1'), isTrue);
    },
  );

  ProviderContainer containerWith(http.Client client) {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        isAuthenticatedProvider.overrideWith((ref) => true),
        learnerWordsProvider.overrideWith((ref) => const AsyncValue.data([])),
        learnerSentencesProvider.overrideWith(
          (ref) => const AsyncValue.data([]),
        ),
        quizzesHttpClientProvider.overrideWithValue(client),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test(
    'quizzesProvider treats an empty Worker list as valid (bundled defaults)',
    () async {
      final requests = <Uri>[];
      final container = containerWith(
        MockClient((request) async {
          requests.add(request.url);
          return http.Response(jsonEncode({'ok': true, 'quizzes': []}), 200);
        }),
      );

      final quizzes = await container.read(quizzesProvider.future);
      expect(quizzes, isNotEmpty);
      expect(requests.single.path, '/api/v1/quizzes');
    },
  );

  test(
    'quizzesProvider serves bundled defaults when the Worker fails, never Appwrite',
    () async {
      final container = containerWith(
        MockClient((request) async => http.Response('Edge error', 500)),
      );

      final quizzes = await container.read(quizzesProvider.future);
      expect(quizzes, isNotEmpty);
    },
  );
}
