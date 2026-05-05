import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:itun/core/storage/cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    Hive.init('./test_hive_cache');
  });

  setUp(() async {
    CacheService.resetForTesting();
  });

  tearDownAll(() async {
    try {
      await Hive.deleteBoxFromDisk('content_cache');
      await Hive.close();
    } catch (_) {}
  });

  group('CacheService', () {
    test('set and get round-trips a single JSON object', () async {
      final data = {'name': 'Olitun', 'version': 1};
      await CacheService.set('test_single', data);

      final result = await CacheService.get<Map<String, dynamic>>(
        'test_single',
        (json) => json,
      );
      expect(result, isNotNull);
      expect(result!['name'], 'Olitun');
      expect(result['version'], 1);
    });

    test('get returns null for missing key', () async {
      final result = await CacheService.get<Map<String, dynamic>>(
        'nonexistent',
        (json) => json,
      );
      expect(result, isNull);
    });

    test('set and getList round-trips a list of JSON objects', () async {
      final data = [
        {'id': '1', 'title': 'Alphabet'},
        {'id': '2', 'title': 'Numbers'},
      ];
      await CacheService.set('test_list', data);

      final result = await CacheService.getList<Map<String, dynamic>>(
        'test_list',
        (json) => json,
      );
      expect(result, isNotNull);
      expect(result!.length, 2);
      expect(result[0]['title'], 'Alphabet');
      expect(result[1]['id'], '2');
    });

    test('getList returns null for missing key', () async {
      final result = await CacheService.getList<Map<String, dynamic>>(
        'nonexistent_list',
        (json) => json,
      );
      expect(result, isNull);
    });

    test('delete removes a key', () async {
      await CacheService.set('to_delete', {'a': 1});
      await CacheService.delete('to_delete');

      final result = await CacheService.get<Map<String, dynamic>>(
        'to_delete',
        (json) => json,
      );
      expect(result, isNull);
    });

    test('clear removes all keys', () async {
      await CacheService.set('key1', {'a': 1});
      await CacheService.set('key2', {'b': 2});
      await CacheService.clear();

      final r1 = await CacheService.get<Map<String, dynamic>>(
        'key1',
        (json) => json,
      );
      final r2 = await CacheService.get<Map<String, dynamic>>(
        'key2',
        (json) => json,
      );
      expect(r1, isNull);
      expect(r2, isNull);
    });

    test('overwriting a key replaces the value', () async {
      await CacheService.set('overwrite', {'v': 1});
      await CacheService.set('overwrite', {'v': 2});

      final result = await CacheService.get<Map<String, dynamic>>(
        'overwrite',
        (json) => json,
      );
      expect(result!['v'], 2);
    });

    test('get gracefully handles corrupted data', () async {
      // Write raw corrupted value directly to the box
      final box = await Hive.openBox('content_cache');
      await box.put('corrupted', 'not valid json{{{');

      final result = await CacheService.get<Map<String, dynamic>>(
        'corrupted',
        (json) => json,
      );
      expect(result, isNull);
    });

    test('getList gracefully handles corrupted data', () async {
      final box = await Hive.openBox('content_cache');
      await box.put('corrupted_list', 'not valid json');

      final result = await CacheService.getList<Map<String, dynamic>>(
        'corrupted_list',
        (json) => json,
      );
      expect(result, isNull);
    });
  });
}
