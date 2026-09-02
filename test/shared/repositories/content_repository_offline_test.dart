import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:itun/core/network/network_info.dart';
import 'package:itun/core/offline/mutation_outbox_service.dart';
import 'package:itun/core/storage/cache_service.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/shared/repositories/content_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockDatabases extends Mock implements Databases {}

class _FakeNetworkInfo implements NetworkInfo {
  _FakeNetworkInfo({required bool connected}) : _connected = connected;

  final bool _connected;

  @override
  Future<bool> get isConnected async => _connected;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      const Stream.empty();
}

ContentItem _buildItem() => ContentItem(
  id: 'word_offline_edit',
  kind: ContentKind.word,
  categoryId: 'cat_vocab',
  title: 'Offline Edit',
  blocks: const [],
  order: 1,
  isPublished: true,
  updatedAt: DateTime(2026, 9, 15),
);

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('test_hive_repo_offline');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    CacheService.resetForTesting();
    MutationOutboxService.resetForTesting();
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  setUp(() async {
    CacheService.resetForTesting();
    MutationOutboxService.resetForTesting();
    await MutationOutboxService().clearQueueForUser(
      contentMutationQueueUserId,
    );
  });

  group('ContentRepository.upsert offline behaviour', () {
    test('caches locally and queues a durable mutation when offline', () async {
      final outbox = MutationOutboxService();
      final repo = ContentRepository(
        databases: _MockDatabases(),
        networkInfo: _FakeNetworkInfo(connected: false),
        mutationOutbox: outbox,
      );

      final result = await repo.upsert(_buildItem());

      expect(result.isRight(), isTrue);

      final pending = await outbox.getPendingMutations(
        contentMutationQueueUserId,
      );
      expect(pending, hasLength(1));
      expect(pending.single.operationType, 'content.upsert');
      expect(pending.single.entityId, 'word_offline_edit');
      expect(pending.single.payload['kind'], ContentKind.word.name);
      // The payload must round-trip so the replay service can rebuild the item.
      final rebuilt = ContentItem.fromJson(
        Map<String, dynamic>.from(pending.single.payload['item'] as Map),
        pending.single.entityId,
        ContentKind.word,
      );
      expect(rebuilt.title, 'Offline Edit');
    });

    test('still succeeds when no outbox is wired (default constructor)', () async {
      final repo = ContentRepository(
        databases: _MockDatabases(),
        networkInfo: _FakeNetworkInfo(connected: false),
      );

      final result = await repo.upsert(_buildItem());

      expect(result.isRight(), isTrue);
    });
  });
}
