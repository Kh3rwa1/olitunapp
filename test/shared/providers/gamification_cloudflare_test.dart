import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/core/api/appwrite_db_service.dart';
import 'package:itun/shared/providers/gamification_content_provider.dart';
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
      (await Directory.systemTemp.createTemp('test_hive_gamification_')).path,
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
    'gamificationContentProvider fetches from Cloudflare Edge first without hitting Appwrite',
    () async {
      final mockHttpClient = MockClient((request) async {
        if (request.url.path.contains('/api/v1/gamification/content')) {
          return http.Response(
            jsonEncode({
              'ok': true,
              'bravoMessages': [
                {
                  'messageId': 'edge_bravo_1',
                  'title': 'Great Job from Edge',
                  'body': 'Keep up the practice!',
                },
              ],
              'badges': [
                {
                  'badgeId': 'edge_badge_1',
                  'name': 'Edge Explorer',
                  'description': 'Learned from Cloudflare Edge',
                  'category': 'learning',
                  'icon': '🌟',
                  'target': 5,
                  'rewardStars': 25,
                },
              ],
              'missionTemplates': [],
              'rewardMessages': [],
              'quizFeedbackMessages': [],
              'config': {'starsPerLesson': 10},
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
          gamificationHttpClientProvider.overrideWithValue(mockHttpClient),
        ],
      );
      addTearDown(container.dispose);

      final content = await container.read(gamificationContentProvider.future);
      expect(content.bravoMessages.length, 1);
      expect(content.bravoMessages[0]['messageId'], 'edge_bravo_1');
      expect(content.badges.length, 1);
      expect(content.badges[0]['badgeId'], 'edge_badge_1');
      expect(content.config['starsPerLesson'], 10);
      verifyNever(
        () => mockDb.listAllDocuments(any(), queries: any(named: 'queries')),
      );
    },
  );

  test(
    'gamificationContentProvider serves the bundled fallback when the Worker fails, never Appwrite',
    () async {
      final container = ProviderContainer(
        overrides: [
          appwriteDbServiceProvider.overrideWithValue(mockDb),
          gamificationHttpClientProvider.overrideWithValue(
            MockClient((request) async => http.Response('Edge error', 500)),
          ),
        ],
      );
      addTearDown(container.dispose);

      final content = await container.read(gamificationContentProvider.future);
      expect(content.badges.first['badgeId'], 'first_lesson');
      verifyNever(
        () => mockDb.listAllDocuments(any(), queries: any(named: 'queries')),
      );
      verifyNever(
        () => mockDb.listDocuments(
          any(),
          queries: any(named: 'queries'),
          paginate: any(named: 'paginate'),
        ),
      );
    },
  );

  test(
    'gamificationContentProvider accepts empty Worker lists as valid',
    () async {
      final container = ProviderContainer(
        overrides: [
          appwriteDbServiceProvider.overrideWithValue(mockDb),
          gamificationHttpClientProvider.overrideWithValue(
            MockClient(
              (request) async => http.Response(
                jsonEncode({
                  'ok': true,
                  'bravoMessages': [],
                  'badges': [],
                  'missionTemplates': [],
                  'rewardMessages': [],
                  'quizFeedbackMessages': [],
                  'config': {},
                }),
                200,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final content = await container.read(gamificationContentProvider.future);
      expect(content.badges, isEmpty);
      expect(content.loadedFromFallback, isFalse);
    },
  );
}
