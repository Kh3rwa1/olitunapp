import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/features/auth/presentation/providers/auth_providers.dart';
import 'package:itun/shared/providers/app_settings_provider.dart';
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
      (await Directory.systemTemp.createTemp('test_hive_app_settings_')).path,
    );
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  test(
    'appSettingsProvider fetches from Cloudflare Edge first without hitting Appwrite',
    () async {
      final mockHttpClient = MockClient((request) async {
        if (request.url.path.contains('/api/v1/settings')) {
          return http.Response(
            jsonEncode({
              'ok': true,
              'settings': {
                'onboarding_video_url': 'https://edge.video/welcome.mp4',
                'razorpay_key_id': 'rzp_edge_123',
                'translation_engine': 'google',
              },
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
          appSettingsHttpClientProvider.overrideWithValue(mockHttpClient),
        ],
      );
      addTearDown(container.dispose);

      final settings = await container.read(appSettingsProvider.future);
      expect(
        settings['onboarding_video_url'],
        'https://edge.video/welcome.mp4',
      );
      expect(settings['razorpay_key_id'], 'rzp_edge_123');
      expect(settings['translation_engine'], 'google');
    },
  );

  ProviderContainer containerWith(http.Client client) {
    final container = ProviderContainer(
      overrides: [
        isAuthenticatedProvider.overrideWith((ref) => true),
        appSettingsHttpClientProvider.overrideWithValue(client),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('appSettingsProvider treats empty Worker settings as valid', () async {
    final container = containerWith(
      MockClient(
        (request) async => http.Response(
          jsonEncode({'ok': true, 'settings': {}, 'documents': []}),
          200,
        ),
      ),
    );

    final settings = await container.read(appSettingsProvider.future);
    expect(settings, isEmpty);
  });

  test(
    'appSettingsProvider returns empty settings when the Worker fails, never Appwrite',
    () async {
      final container = containerWith(
        MockClient((request) async => http.Response('Edge error', 500)),
      );

      final settings = await container.read(appSettingsProvider.future);
      expect(settings, isEmpty);
    },
  );
}
