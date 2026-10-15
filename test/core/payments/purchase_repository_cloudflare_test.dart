import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:itun/core/payments/purchase_repository.dart';
import 'package:itun/core/storage/cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'edge_entitlements_fake.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EdgeEntitlementsFake edge;

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async => '.',
        );
    Hive.init(
      (await Directory.systemTemp.createTemp(
        'test_hive_cloudflare_entitlements_',
      )).path,
    );
  });

  setUp(() async {
    CacheService.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await CacheService.clear();
    edge = EdgeEntitlementsFake();
  });

  tearDown(() async {
    await CacheService.clear();
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  PurchaseRepository repoFor() {
    final container = ProviderContainer(overrides: [edge.override]);
    addTearDown(container.dispose);
    return container.read(purchaseRepositoryProvider);
  }

  test('reads entitlements from the Worker', () async {
    edge.answer('user_cf_1', ['course_cat_1', 'course_cat_2']);

    final result = await repoFor().fetchEntitlements('user_cf_1');

    expect(result.status, EntitlementStatus.verified);
    expect(result.categoryIds, {'course_cat_1', 'course_cat_2'});
    expect(edge.calls, 1);
  });

  test('a Worker error is a server error, never a silent unlock', () async {
    edge.status(500);

    final result = await repoFor().fetchEntitlements('user_error');

    expect(result.status, EntitlementStatus.serverError);
    expect(result.categoryIds, isEmpty);
    expect(
      await CacheService.getMeta('entitlements:production:user_error'),
      isNull,
    );
  });

  test('offline without a recent verification grants nothing', () async {
    edge.offline();

    final result = await repoFor().fetchEntitlements('user_offline');

    expect(result.status, EntitlementStatus.networkUnavailable);
    expect(result.categoryIds, isEmpty);
  });

  test('ignores an edge answer for a different user', () async {
    edge.answer('someone_else', ['other_users_course']);

    final result = await repoFor().fetchEntitlements('user_switched');

    expect(result.categoryIds, isEmpty);
    expect(
      await CacheService.getMeta('entitlements:production:user_switched'),
      isNull,
    );
  });
}
