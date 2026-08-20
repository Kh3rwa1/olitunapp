import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:itun/core/storage/cache_service.dart';

void main() {
  group('CacheEntry', () {
    test('fresh entry is not expired', () {
      final entry = CacheEntry(
        data: {'key': 'value'},
        schemaVersion: cacheSchemaVersion,
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
        ttlMs: const Duration(hours: 1).inMilliseconds,
      );
      expect(entry.isExpired, false);
      expect(entry.isSchemaMismatch, false);
    });

    test('old entry is expired', () {
      final entry = CacheEntry(
        data: {'key': 'value'},
        schemaVersion: cacheSchemaVersion,
        createdAtMs: DateTime.now()
            .subtract(const Duration(hours: 2))
            .millisecondsSinceEpoch,
        ttlMs: const Duration(hours: 1).inMilliseconds,
      );
      expect(entry.isExpired, true);
    });

    test('entry with no TTL never expires', () {
      final entry = CacheEntry(
        data: {'key': 'value'},
        schemaVersion: cacheSchemaVersion,
        createdAtMs: DateTime.now()
            .subtract(const Duration(days: 365))
            .millisecondsSinceEpoch,
      );
      expect(entry.isExpired, false);
    });

    test('schema mismatch detected', () {
      final entry = CacheEntry(
        data: {'key': 'value'},
        schemaVersion: 0,
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
      );
      expect(entry.isSchemaMismatch, true);
    });

    test('toJson / fromJson roundtrip', () {
      final entry = CacheEntry(
        data: {'key': 'value'},
        schemaVersion: cacheSchemaVersion,
        createdAtMs: 1700000000000,
        ttlMs: 3600000,
      );
      final json = entry.toJson();
      final restored = CacheEntry.fromJson(json);

      expect(restored.schemaVersion, cacheSchemaVersion);
      expect(restored.createdAtMs, 1700000000000);
      expect(restored.ttlMs, 3600000);
      expect((restored.data as Map)['key'], 'value');
    });
  });

  group('CacheService integration', () {
    setUpAll(() async {
      Hive.init('test_hive_cache_v2');
      CacheService.resetForTesting();
    });

    tearDownAll(() async {
      await CacheService.clear();
    });

    test('set and get roundtrip', () async {
      await CacheService.set('test_key', {'name': 'Olitun'});
      final result = await CacheService.get<Map<String, dynamic>>(
        'test_key',
        (json) => json,
      );
      expect(result, isNotNull);
      expect(result!['name'], 'Olitun');
    });

    test('strictly fresh lookup on expired entry returns null', () async {
      await CacheService.set('expired_key', {
        'name': 'old',
      }, ttl: Duration.zero);
      // Wait a tick to ensure expiry
      await Future.delayed(const Duration(milliseconds: 10));
      final freshResult =
          await CacheService.getStrictlyFresh<Map<String, dynamic>>(
            'expired_key',
            (json) => json,
          );
      expect(freshResult, isNull);

      // Stale-while-revalidate returns cached data to ensure offline learning is never lost
      final staleResult = await CacheService.get<Map<String, dynamic>>(
        'expired_key',
        (json) => json,
      );
      expect(staleResult, isNotNull);
      expect(staleResult!['name'], 'old');
    });

    test(
      '30-day offline simulation preserves cached lessons and categories',
      () async {
        final now = DateTime.now();
        final thirtyDaysAgoMs = now
            .subtract(const Duration(days: 30))
            .millisecondsSinceEpoch;

        final entry = CacheEntry(
          data: {'title': 'Ol Chiki Mastery', 'id': 'lesson_30d'},
          schemaVersion: cacheSchemaVersion,
          createdAtMs: thirtyDaysAgoMs,
          ttlMs: const Duration(hours: 24).inMilliseconds,
        );

        final box = await Hive.openBox('content_cache');
        await box.put('lesson_30d_key', jsonEncode(entry.toJson()));

        final result = await CacheService.get<Map<String, dynamic>>(
          'lesson_30d_key',
          (json) => json,
        );
        expect(result, isNotNull);
        expect(result!['id'], 'lesson_30d');
        expect(result['title'], 'Ol Chiki Mastery');
      },
    );

    test(
      'evictStale preserves valid learning content past TTL by default',
      () async {
        await CacheService.set('stale_lesson', {
          'data': 'important',
        }, ttl: Duration.zero);
        await Future.delayed(const Duration(milliseconds: 10));

        final evictedCount = await CacheService.evictStale();
        expect(evictedCount, 0);

        final preserved = await CacheService.get<Map<String, dynamic>>(
          'stale_lesson',
          (json) => json,
        );
        expect(preserved, isNotNull);
      },
    );

    test('getMeta returns metadata', () async {
      await CacheService.set('meta_key', {'value': 42});
      final meta = await CacheService.getMeta('meta_key');
      expect(meta, isNotNull);
      expect(meta!.schemaVersion, cacheSchemaVersion);
      expect(meta.ttlMs, CacheService.defaultTtl.inMilliseconds);
    });

    test('delete removes entry', () async {
      await CacheService.set('del_key', {'temp': true});
      await CacheService.delete('del_key');
      final result = await CacheService.get<Map<String, dynamic>>(
        'del_key',
        (json) => json,
      );
      expect(result, isNull);
    });

    test('getList roundtrip', () async {
      await CacheService.set('list_key', [
        {'id': '1'},
        {'id': '2'},
      ]);
      final result = await CacheService.getList<Map<String, dynamic>>(
        'list_key',
        (json) => json,
      );
      expect(result, isNotNull);
      expect(result!.length, 2);
      expect(result[0]['id'], '1');
    });
  });
}
