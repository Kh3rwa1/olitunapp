import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:itun/core/network/network_info.dart';
import 'package:itun/core/storage/cache_service.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/shared/repositories/content_repository.dart';

class _MockDatabases extends Mock implements Databases {}

class _MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('olitun_cached_list_');
    Hive.init(directory.path);
    CacheService.resetForTesting();
  });

  tearDown(() async {
    await Hive.close();
    CacheService.resetForTesting();
    await directory.delete(recursive: true);
  });

  test('cachedList never checks connectivity or calls Appwrite', () async {
    final databases = _MockDatabases();
    final network = _MockNetworkInfo();
    final repository = ContentRepository(
      databases: databases,
      networkInfo: network,
    );
    final item = ContentItem(
      id: 'local-word',
      kind: ContentKind.word,
      categoryId: 'offline_cache_test',
      title: 'Available before a network request',
      blocks: const [],
      updatedAt: DateTime(2026, 9, 8),
    );
    expect(
      await CacheService.set('content_list_word_offline_cache_test', [
        item.toJson(),
      ]),
      isTrue,
    );

    final result = await repository.cachedList(
      ContentKind.word,
      categoryId: 'offline_cache_test',
    );

    result.fold(
      (failure) => fail('Expected cached content, got $failure'),
      (items) => expect(
        items.any((value) => value.id == item.id && value.title == item.title),
        isTrue,
      ),
    );
    verifyZeroInteractions(databases);
    verifyZeroInteractions(network);
  });
}
