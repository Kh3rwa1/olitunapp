import 'dart:io';
import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:mocktail/mocktail.dart';
import 'package:itun/core/storage/cache_service.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/core/network/network_info.dart';
import 'package:itun/core/offline/mutation_outbox_service.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/shared/offline/content_mutation_replay.dart';
import 'package:itun/shared/repositories/content_repository.dart';
import 'package:fpdart/fpdart.dart';

class FakeNetworkInfo implements NetworkInfo {
  FakeNetworkInfo({required bool connected}) : _connected = connected;

  final bool _connected;

  @override
  Future<bool> get isConnected async => _connected;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      const Stream.empty();
}

class MockOfflineDatabases extends Mock implements Databases {}

class FailingOutbox extends MutationOutboxService {
  @override
  Future<void> enqueueMutation(PendingMutation mutation) async =>
      throw StateError('disk full');
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('test_hive_outbox_replay');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    MutationOutboxService.resetForTesting();
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  setUp(() async {
    // The outbox box handle is static and shared across tests in this file;
    // clear the queue so each test starts from a clean slate.
    await MutationOutboxService().clearQueueForUser(contentMutationQueueUserId);
  });

  ContentItem buildItem({String id = 'word_johar'}) => ContentItem(
    id: id,
    kind: ContentKind.word,
    categoryId: 'cat_vocab',
    title: 'Johar',
    blocks: const [],
    order: 1,
    isPublished: true,
    updatedAt: DateTime(2026, 9, 15),
  );

  test(
    'offline save fails when its durable queue is absent or unwritable',
    () async {
      for (final outbox in <MutationOutboxService?>[null, FailingOutbox()]) {
        final repository = ContentRepository(
          databases: MockOfflineDatabases(),
          networkInfo: FakeNetworkInfo(connected: false),
          mutationOutbox: outbox,
        );
        final result = await repository.upsert(buildItem());
        expect(result.isLeft(), isTrue);
      }
    },
  );

  test(
    'replay cannot acknowledge an offline re-enqueue as a server success',
    () async {
      final repository = ContentRepository(
        databases: MockOfflineDatabases(),
        networkInfo: FakeNetworkInfo(connected: false),
        mutationOutbox: MutationOutboxService(),
      );
      final result = await repository.upsert(
        buildItem(),
        allowOfflineQueue: false,
      );
      expect(result.isLeft(), isTrue);
      expect(
        await MutationOutboxService().getPendingMutations(
          contentMutationQueueUserId,
        ),
        isEmpty,
      );
    },
  );

  test('durable edit survives Hive close and reopen before replay', () async {
    final outbox = MutationOutboxService();
    final repository = ContentRepository(
      databases: MockOfflineDatabases(),
      networkInfo: FakeNetworkInfo(connected: false),
      mutationOutbox: outbox,
    );
    expect((await repository.upsert(buildItem())).isRight(), isTrue);
    await Hive.close();
    MutationOutboxService.resetForTesting();
    CacheService.resetForTesting();
    final reopened = MutationOutboxService();
    expect(
      await reopened.getPendingMutations(contentMutationQueueUserId),
      hasLength(1),
    );
    var calls = 0;
    final replay = ContentMutationReplay(
      outbox: reopened,
      networkInfo: FakeNetworkInfo(connected: true),
      executeUpsert: (item) async {
        calls++;
        return right(item);
      },
    );
    expect((await replay.replayPending()).replayed, 1);
    expect(calls, 1);
    expect(
      await reopened.getPendingMutations(contentMutationQueueUserId),
      isEmpty,
    );
  });

  test(
    'simultaneous replay triggers share one execution and await persistence',
    () async {
      final outbox = MutationOutboxService();
      final item = buildItem();
      await outbox.enqueueMutation(
        PendingMutation(
          operationId: 'single_flight',
          userId: contentMutationQueueUserId,
          operationType: 'content.upsert',
          entityId: item.id,
          payload: {'kind': item.kind.name, 'item': item.toJson()},
          createdAt: DateTime.now(),
        ),
      );
      final entered = Completer<void>();
      final release = Completer<void>();
      var calls = 0;
      final replay = ContentMutationReplay(
        outbox: outbox,
        networkInfo: FakeNetworkInfo(connected: true),
        executeUpsert: (item) async {
          calls++;
          entered.complete();
          await release.future;
          return right(item);
        },
      );
      final first = replay.replayPending();
      await entered.future.timeout(const Duration(seconds: 5));
      final second = replay.replayPending();
      expect(identical(first, second), isTrue);
      release.complete();
      await Future.wait([first, second]);
      expect(calls, 1);
      expect(
        await outbox.getPendingMutations(contentMutationQueueUserId),
        isEmpty,
      );
    },
  );

  test('a deferred older edit blocks newer edits of the same entity', () async {
    final outbox = MutationOutboxService();
    final item = buildItem();
    for (var i = 0; i < 2; i++) {
      await outbox.enqueueMutation(
        PendingMutation(
          operationId: 'ordered_$i',
          userId: contentMutationQueueUserId,
          operationType: 'content.upsert',
          entityId: item.id,
          payload: {'kind': item.kind.name, 'item': item.toJson()},
          createdAt: DateTime.now().add(Duration(milliseconds: i)),
          nextRetryAt: i == 0
              ? DateTime.now().add(const Duration(hours: 1))
              : DateTime.now(),
        ),
      );
    }
    final replay = ContentMutationReplay(
      outbox: outbox,
      networkInfo: FakeNetworkInfo(connected: true),
      executeUpsert: (_) => throw StateError('must wait for the older edit'),
    );
    final result = await replay.replayPending();
    expect(result.skipped, 2);
    expect(result.replayed, 0);
    expect(
      await outbox.getPendingMutations(contentMutationQueueUserId),
      hasLength(2),
    );
  });

  group('ContentMutationReplay', () {
    test('skips replay when the device is offline', () async {
      final outbox = MutationOutboxService();
      final replay = ContentMutationReplay(
        outbox: outbox,
        networkInfo: FakeNetworkInfo(connected: false),
        executeUpsert: (_) => throw StateError('should not execute'),
      );

      final summary = await replay.replayPending();

      expect(summary.replayed, 0);
      expect(summary.failed, 0);
    });

    test('replays queued upserts and clears them from the outbox', () async {
      final outbox = MutationOutboxService();
      final item = buildItem();
      await outbox.enqueueMutation(
        PendingMutation(
          operationId: 'op_replay_success',
          userId: contentMutationQueueUserId,
          operationType: 'content.upsert',
          entityId: item.id,
          payload: {'kind': item.kind.name, 'item': item.toJson()},
          createdAt: DateTime.now(),
        ),
      );

      final executed = <ContentItem>[];
      final replay = ContentMutationReplay(
        outbox: outbox,
        networkInfo: FakeNetworkInfo(connected: true),
        executeUpsert: (item) async {
          executed.add(item);
          return right(item);
        },
      );

      final summary = await replay.replayPending();

      expect(summary.replayed, 1);
      expect(summary.failed, 0);
      expect(executed.single.id, item.id);
      expect(
        await outbox.getPendingMutations(contentMutationQueueUserId),
        isEmpty,
      );
    });

    test(
      'records failures with retry budget instead of losing the edit',
      () async {
        final outbox = MutationOutboxService();
        final item = buildItem(id: 'word_failcase');
        await outbox.enqueueMutation(
          PendingMutation(
            operationId: 'op_replay_failure',
            userId: contentMutationQueueUserId,
            operationType: 'content.upsert',
            entityId: item.id,
            payload: {'kind': item.kind.name, 'item': item.toJson()},
            createdAt: DateTime.now(),
          ),
        );

        final replay = ContentMutationReplay(
          outbox: outbox,
          networkInfo: FakeNetworkInfo(connected: true),
          executeUpsert: (_) async =>
              left(const ServerFailure(message: 'upstream unavailable')),
        );

        final summary = await replay.replayPending();

        expect(summary.replayed, 0);
        expect(summary.failed, 1);

        final pending = await outbox.getPendingMutations(
          contentMutationQueueUserId,
        );
        expect(pending, hasLength(1));
        expect(pending.single.attemptCount, 1);
        expect(pending.single.status, MutationStatus.failed);
        expect(pending.single.lastError, 'upstream unavailable');
      },
    );

    test('dead-letters permanently unparseable mutations', () async {
      final outbox = MutationOutboxService();
      await outbox.enqueueMutation(
        PendingMutation(
          operationId: 'op_replay_corrupt',
          userId: contentMutationQueueUserId,
          operationType: 'content.upsert',
          entityId: 'whatever',
          payload: {'kind': 'not_a_kind', 'item': {}},
          createdAt: DateTime.now(),
        ),
      );

      final replay = ContentMutationReplay(
        outbox: outbox,
        networkInfo: FakeNetworkInfo(connected: true),
        executeUpsert: (_) => throw StateError('should not execute'),
      );

      final summary = await replay.replayPending();

      expect(summary.failed, 1);
      final pending = await outbox.getPendingMutations(
        contentMutationQueueUserId,
      );
      expect(pending, hasLength(1));
      expect(
        pending.single.status,
        MutationStatus.deadLetter,
        reason: 'unparseable records go straight to dead-letter',
      );
    });

    test('skips already dead-lettered mutations', () async {
      final outbox = MutationOutboxService();
      await outbox.enqueueMutation(
        PendingMutation(
          operationId: 'op_replay_dead',
          userId: contentMutationQueueUserId,
          operationType: 'content.upsert',
          entityId: 'entity_1',
          payload: {'kind': 'word', 'item': buildItem().toJson()},
          createdAt: DateTime.now(),
          attemptCount: MutationOutboxService.maxRetryAttempts,
          status: MutationStatus.deadLetter,
        ),
      );

      final replay = ContentMutationReplay(
        outbox: outbox,
        networkInfo: FakeNetworkInfo(connected: true),
        executeUpsert: (_) => throw StateError('should not execute'),
      );

      final summary = await replay.replayPending();

      expect(summary.skipped, 1);
      expect(summary.replayed, 0);
    });
  });
}
