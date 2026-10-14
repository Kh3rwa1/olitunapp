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
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/auth/presentation/providers/auth_providers.dart';
import 'package:itun/shared/providers/learner_content_providers.dart';
import 'package:itun/shared/providers/quizzes_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAppwriteDbService extends Mock implements AppwriteDbService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAppwriteDbService mockDb;
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
    mockDb = MockAppwriteDbService();
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
          appwriteDbServiceProvider.overrideWithValue(mockDb),
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
      verifyNever(() => mockDb.listAllDocuments(any()));
    },
  );

  test(
    'quizzesProvider falls back to Appwrite DB when Cloudflare edge fails',
    () async {
      final mockHttpClient = MockClient((request) async {
        return http.Response('Edge error', 500);
      });

      when(
        () =>
            mockDb.listAllDocuments('quizzes', queries: any(named: 'queries')),
      ).thenAnswer(
        (_) async => [
          {
            'id': 'appwrite_quiz_1',
            'categoryId': 'cat_numbers',
            'title': 'Appwrite Numbers Quiz',
            'level': 'beginner',
            'order': 0,
            'isActive': true,
            'questions': [
              {
                'promptOlChiki': '᱑',
                'promptLatin': 'What number?',
                'optionsOlChiki': ['1', '2', '3', '4'],
                'optionsLatin': ['1', '2', '3', '4'],
                'correctIndex': 0,
              },
            ],
          },
        ],
      );

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          isAuthenticatedProvider.overrideWith((ref) => true),
          appwriteDbServiceProvider.overrideWithValue(mockDb),
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
      expect(quizzes.any((q) => q.id == 'appwrite_quiz_1'), isTrue);
      verify(
        () =>
            mockDb.listAllDocuments('quizzes', queries: any(named: 'queries')),
      ).called(1);
    },
  );
}
