import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/core/api/admin_content_client.dart';
import 'package:itun/core/storage/cache_service.dart';
import 'package:itun/core/auth/auth_providers.dart';
import 'package:itun/shared/models/catalog/rhyme_model.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/banners_provider.dart';
import 'package:itun/shared/providers/letters_provider.dart';
import 'package:itun/features/rhymes/data/rhymes_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_admin_worker.dart';

/// Admin writes from the letters / banners / rhymes notifiers go to the
/// Worker admin routes with the admin JWT; learner reads stay on the public
/// list routes.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAdminWorker worker;
  late List<Uri> publicReads;

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async => '.',
        );
    Hive.init(
      (await Directory.systemTemp.createTemp('test_hive_admin_writes_')).path,
    );
  });

  setUp(() async {
    CacheService.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await CacheService.clear();
    worker = FakeAdminWorker();
    publicReads = [];
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  final publicClient = MockClient((request) async {
    publicReads.add(request.url);
    final key = request.url.pathSegments.last;
    return http.Response(jsonEncode({'ok': true, key: []}), 200);
  });

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        isAuthenticatedProvider.overrideWith((ref) => true),
        adminContentClientProvider.overrideWithValue(worker.adminClient),
        lettersHttpClientProvider.overrideWithValue(publicClient),
        bannersHttpClientProvider.overrideWithValue(publicClient),
        rhymesHttpClientProvider.overrideWithValue(publicClient),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  void expectWrite(
    String method,
    String path, {
    Map<String, Object?> fields = const {},
  }) {
    final request = worker.requestsWith(method).last;
    expect(request.url.path, path);
    expect(request.headers['Authorization'], 'Bearer ${FakeAdminWorker.jwt}');
    if (method == 'PUT') {
      final body = worker.bodyOf(request);
      expect(body.containsKey('id'), isFalse);
      expect(body.values, isNot(contains(null)));
      fields.forEach((key, value) => expect(body[key], value));
    }
  }

  test('letters add/update/delete use the Worker admin routes', () async {
    final c = container();
    await c.read(lettersProvider.future);
    final notifier = c.read(lettersProvider.notifier);
    final letter = LetterModel(
      id: 'l_test',
      charOlChiki: 'ᱚ',
      transliterationLatin: 'La',
      pronunciation: 'o',
    );

    await notifier.add(letter);
    expectWrite(
      'PUT',
      '/api/v1/admin/content/letters/l_test',
      fields: {'charOlChiki': 'ᱚ', 'transliterationLatin': 'La'},
    );
    await notifier.updateItem(letter);
    expect(worker.requestsWith('PUT'), hasLength(2));
    await notifier.delete('l_test');
    expectWrite('DELETE', '/api/v1/admin/content/letters/l_test');
    expect(worker.rows['letters'], isEmpty);
    // Learner list reads stayed on the public route.
    expect(publicReads, isNotEmpty);
    expect(publicReads.every((u) => u.path == '/api/v1/letters'), isTrue);
  });

  test('banners add/update/delete use the Worker admin routes', () async {
    final c = container();
    await c.read(bannersProvider.future);
    final notifier = c.read(bannersProvider.notifier);
    final banner = FeaturedBannerModel(id: 'b_1', title: 'Johar');

    await notifier.add(banner);
    expectWrite(
      'PUT',
      '/api/v1/admin/content/banners/b_1',
      fields: {'title': 'Johar', 'isActive': true},
    );
    await notifier.updateItem(banner);
    await notifier.delete('b_1');
    expectWrite('DELETE', '/api/v1/admin/content/banners/b_1');
  });

  test('rhymes add/delete use the Worker admin routes', () async {
    final c = container();
    await c.read(rhymesProvider.future);
    final notifier = c.read(rhymesProvider.notifier);
    final rhyme = RhymeModel(
      id: 'r_1',
      titleOlChiki: 'ᱵᱟᱠᱷᱮᱬ',
      titleLatin: 'Bakhed',
      contentOlChiki: '',
      contentLatin: 'Prayer',
    );

    await notifier.add(rhyme);
    expectWrite(
      'PUT',
      '/api/v1/admin/content/rhymes/r_1',
      fields: {'titleLatin': 'Bakhed'},
    );
    await notifier.delete('r_1');
    expectWrite('DELETE', '/api/v1/admin/content/rhymes/r_1');
  });

  test('a rejected write is not applied and does not throw', () async {
    final c = container();
    await c.read(bannersProvider.future);
    worker.failStatus = 403;

    await c
        .read(bannersProvider.notifier)
        .add(FeaturedBannerModel(id: 'b_x', title: 'Denied'));

    expect(worker.requestsWith('PUT'), hasLength(1));
    expect(worker.rows['banners'], isNull);
  });
}
