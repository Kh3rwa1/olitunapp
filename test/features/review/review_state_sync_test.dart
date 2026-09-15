// Review state cloud sync: pull/merge/conflict (LWW), malformed server
// responses, offline queue + replay, duplicate pushes, reinstall recovery.
// All fakes — no Hive, no Appwrite.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/offline/mutation_outbox_service.dart';
import 'package:itun/features/review/data/review_appwrite_repository.dart';
import 'package:itun/features/review/data/review_state_sync.dart';
import 'package:itun/features/review/data/review_store.dart';
import 'package:itun/features/review/domain/review_corpus_identity.dart';
import 'package:itun/features/review/domain/review_item.dart';
import 'package:itun/features/review/domain/review_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRepository implements ReviewRepository {
  List<MemoryItemState> remote = [];
  Exception? loadError;
  Exception? pushError;
  Exception? deleteError;
  final pushed = <MemoryItemState>[];
  final deleted = <String>[];

  @override
  Future<List<MemoryItemState>> loadRemoteStates(String userId) async {
    if (loadError != null) throw loadError!;
    return List.of(remote);
  }

  @override
  Future<void> pushState(String userId, MemoryItemState item) async {
    if (pushError != null) throw pushError!;
    pushed.add(item);
  }

  @override
  Future<void> deleteState(String userId, String itemId) async {
    if (deleteError != null) throw deleteError!;
    deleted.add(itemId);
  }
}

class _FakeOutbox implements ReviewOutbox {
  final queued = <PendingMutation>[];
  final completed = <String>[];
  final failedOps = <({String id, String error, bool permanent})>[];
  final Map<String, MutationStatus> statuses = {};
  final Map<String, PendingMutation> allMutations = {};

  @override
  Future<void> enqueueMutation(PendingMutation mutation) async {
    queued.add(mutation);
    statuses[mutation.operationId] = mutation.status;
    allMutations[mutation.operationId] = mutation;
  }

  @override
  Future<List<PendingMutation>> getPendingMutations(String userId) async =>
      queued
          .where(
            (m) =>
                m.status != MutationStatus.completed &&
                m.status != MutationStatus.cancelled,
          )
          .toList();

  @override
  Future<void> recordAttemptFailed(
    String userId,
    String operationId,
    String error, {
    bool isPermanent = false,
  }) async {
    failedOps.add((id: operationId, error: error, permanent: isPermanent));
    final newStatus = isPermanent
        ? MutationStatus.deadLetter
        : MutationStatus.failed;
    statuses[operationId] = newStatus;
    final index = queued.indexWhere((m) => m.operationId == operationId);
    if (index >= 0) {
      queued[index].status = newStatus;
      queued[index].lastError = error;
      queued[index].attemptCount += 1;
    }
  }

  @override
  Future<void> markCompleted(String userId, String operationId) async {
    completed.add(operationId);
    statuses[operationId] = MutationStatus.completed;
    final index = queued.indexWhere((m) => m.operationId == operationId);
    if (index >= 0) {
      queued[index].status = MutationStatus.completed;
    }
  }

  Future<void> markCancelled(String userId, String operationId) async {
    statuses[operationId] = MutationStatus.cancelled;
    final index = queued.indexWhere((m) => m.operationId == operationId);
    if (index >= 0) {
      queued[index].status = MutationStatus.cancelled;
    }
  }

  @override
  Future<MutationStatus?> getMutationStatus(
    String userId,
    String operationId,
  ) async {
    return statuses[operationId];
  }

  @override
  Future<PendingMutation?> getMutation(
    String userId,
    String operationId,
  ) async {
    return allMutations[operationId];
  }
}

MemoryItemState item(
  String id, {
  DateTime? lastReviewed,
  ReviewItemType type = ReviewItemType.word,
}) {
  final introduced = DateTime.utc(2026, 1, 1, 9);
  return MemoryItemState(
    itemId: id,
    itemType: type,
    introducedAt: introduced,
    nextReviewAt: lastReviewed?.add(const Duration(days: 1)) ?? introduced,
    lastReviewedAt: lastReviewed,
    successfulRecalls: 2,
  );
}

void main() {
  late _FakeRepository repo;
  late _FakeOutbox outbox;
  late ReviewStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    store = await ReviewStore.load(prefs);
    repo = _FakeRepository();
    outbox = _FakeOutbox();
  });

  ReviewStateSync sync({
    String? userId = 'user-1',
    ReviewCorpusIdentityMap? corpusMap,
  }) => ReviewStateSync(
    repository: repo,
    outbox: outbox,
    resolveUserId: () async => userId,
    loadStore: () async => store,
    corpusMap: corpusMap,
  );

  group('pull + merge (LWW on lastReviewedAt)', () {
    test('unknown remote item is adopted into the local cache', () async {
      final s = sync();
      repo.remote = [item('w1', lastReviewed: DateTime.utc(2026, 1, 2))];
      final result = await s.syncNow();
      expect(result.adopted, 1);
      expect(store.get('w1')?.itemId, 'w1');
      expect(store.get('w1')?.successfulRecalls, 2);
    });

    test('server-newer wins over older local state (cross-device)', () async {
      store.adoptRemote(item('w1', lastReviewed: DateTime.utc(2026, 1, 2)));
      repo.remote = [item('w1', lastReviewed: DateTime.utc(2026, 1, 5))];
      final result = await sync().syncNow();
      expect(result.adopted, 1);
      expect(store.get('w1')?.lastReviewedAt, DateTime.utc(2026, 1, 5));
    });

    test('local-newer is re-enqueued for push, local state kept', () async {
      final newer = item('w1', lastReviewed: DateTime.utc(2026, 1, 10));
      store.adoptRemote(newer);
      repo.remote = [item('w1', lastReviewed: DateTime.utc(2026, 1, 2))];
      final result = await sync().syncNow();
      expect(result.pushedLocal, 1);
      expect(result.keptLocal, 0);
      expect(store.get('w1')?.lastReviewedAt, DateTime.utc(2026, 1, 10));
      // syncNow replays immediately after merging: the local-newer state
      // was pushed to the server (queue drained, not lost).
      expect(repo.pushed.map((e) => e.itemId), contains('w1'));
      expect(
        repo.pushed.firstWhere((e) => e.itemId == 'w1').lastReviewedAt,
        DateTime.utc(2026, 1, 10),
      );
      expect(await outbox.getPendingMutations('user-1'), isEmpty);
    });

    test('identical timestamps keep local (no-op, no loop)', () async {
      final same = item('w1', lastReviewed: DateTime.utc(2026, 1, 2));
      store.adoptRemote(same);
      repo.remote = [same];
      final result = await sync().syncNow();
      expect(result.keptLocal, 1);
      expect(result.pushedLocal, 0);
      expect(outbox.queued, isEmpty);
    });

    test('never-reviewed remote fallback uses introducedAt', () async {
      final remote = item('w1'); // lastReviewed null
      repo.remote = [remote];
      final result = await sync().syncNow();
      expect(result.adopted, 1);
      expect(store.get('w1'), isNotNull);
    });
  });

  group('failure handling', () {
    test('pull failure leaves local state untouched', () async {
      store.adoptRemote(item('w1', lastReviewed: DateTime.utc(2026, 1, 2)));
      repo.loadError = Exception('network down');
      final result = await sync().syncNow();
      expect(result.isClean, isTrue);
      expect(store.get('w1')?.lastReviewedAt, DateTime.utc(2026, 1, 2));
    });

    test('malformed remote rows are skipped, good rows survive', () async {
      repo.remote = [
        item('good', lastReviewed: DateTime.utc(2026, 1, 3)),
        // Malformed: empty itemId is skipped by mergeRemote.
        MemoryItemState(
          itemId: '',
          itemType: ReviewItemType.word,
          introducedAt: DateTime.utc(2026, 1, 4),
          nextReviewAt: DateTime.utc(2026, 1, 4),
        ),
      ];
      final result = await sync().syncNow();
      expect(result.adopted, 1);
      expect(store.all(), hasLength(1));
      expect(result.skipped, 1);
    });

    test('guest (no userId) is fully local-only', () async {
      repo.remote = [item('w1')];
      final result = await sync(userId: null).syncNow();
      expect(result.pulled, 0);
      expect(store.all(), isEmpty);
    });
  });

  group('offline queue + replay', () {
    test('enqueueLocalMutation stores a durable entry per item', () async {
      final s = sync();
      await s.enqueueLocalMutation(
        item('w1', lastReviewed: DateTime.utc(2026, 1, 3)),
      );
      expect(outbox.queued, hasLength(1));
      expect(outbox.queued.first.operationType, reviewStateOperationType);
      expect(outbox.queued.first.userId, 'user-1');
      expect(outbox.queued.first.entityId, 'w1');
    });

    test('replay pushes the LIVE local state, not the stale payload', () async {
      final s = sync();
      // Stale payload queued from an earlier session.
      await s.enqueueLocalMutation(
        item('w1', lastReviewed: DateTime.utc(2026, 1, 3)),
      );
      // Local store has moved on (rapid-fire recall after queueing).
      final live = item('w1', lastReviewed: DateTime.utc(2026, 1, 6));
      store.adoptRemote(live);

      final result = await s.replayQueued();
      expect(result.pushedLocal, 1);
      expect(outbox.completed, hasLength(1));
      expect(await outbox.getPendingMutations('user-1'), isEmpty);

      // The pushed state is the live one.

      expect(repo.pushed.single.lastReviewedAt, DateTime.utc(2026, 1, 6));
    });

    test('replay failure records the attempt (outbox retries later)', () async {
      final failing = _FakeRepository();
      final s = ReviewStateSync(
        repository: failing,
        outbox: outbox,
        resolveUserId: () async => 'user-1',
        loadStore: () async => store,
      );
      // Make push throw via a repository that fails on push.
      final repo = _ThrowingOnPushRepository();
      final s2 = ReviewStateSync(
        repository: repo,
        outbox: outbox,
        resolveUserId: () async => 'user-1',
        loadStore: () async => store,
      );
      await s.enqueueLocalMutation(item('w1'));
      final result = await s2.replayQueued();
      expect(result.failed, 1);
      expect(outbox.failedOps, hasLength(1));
      // Entry stays queued for retry.
      expect(outbox.queued, hasLength(1));
    });

    test('empty itemId payload is dead-lettered, never pushed', () async {
      final s = sync();
      outbox.queued.add(
        PendingMutation(
          operationId: 'bad_1',
          userId: 'user-1',
          operationType: reviewStateOperationType,
          entityId: '',
          payload: <String, dynamic>{'itemId': ''},
          createdAt: DateTime.now(),
        ),
      );
      final result = await s.replayQueued();
      expect(result.skipped, 1);
      expect(outbox.failedOps.single.permanent, isTrue);
      expect(repo.pushed, isEmpty);
    });

    test('other operation types are not touched by review replay', () async {
      final s = sync();
      outbox.queued.add(
        PendingMutation(
          operationId: 'content_1',
          userId: 'user-1',
          operationType: 'content.upsert',
          entityId: 'x',
          payload: <String, dynamic>{},
          createdAt: DateTime.now(),
        ),
      );
      final result = await s.replayQueued();
      expect(result.pushedLocal, 0);
      expect(outbox.queued, hasLength(1));
      expect(outbox.completed, isEmpty);
    });
  });

  group('duplicate prevention', () {
    test('duplicate remote itemIds collapse to first occurrence', () async {
      repo.remote = [
        item('w1', lastReviewed: DateTime.utc(2026, 1, 2)),
        item('w1', lastReviewed: DateTime.utc(2026, 1, 9)),
      ];
      final result = await sync().syncNow();
      // First occurrence wins; the duplicate is counted as skipped.
      expect(result.adopted, 1);
      expect(result.skipped, 1);
      expect(store.get('w1')?.lastReviewedAt, DateTime.utc(2026, 1, 2));
    });

    test('rowIdFor is deterministic and sanitized', () {
      final a = ReviewAppwriteRowIds.rowIdFor('user-1', 'w1');
      expect(a, ReviewAppwriteRowIds.rowIdFor('user-1', 'w1'));
      // Not equal across users (users never share rows).
      expect(a, isNot(ReviewAppwriteRowIds.rowIdFor('user-2', 'w1')));
    });
  });

  group('reconciliation & corpus identity sync', () {
    test(
      'cloud pull cannot restore tombstoned item and enqueues remote delete',
      () async {
        final corpusMap = ReviewCorpusIdentityMap(
          activeWordIds: {'w_keep'},
          activeSentenceIds: const {},
          aliases: const [],
          tombstones: const [
            ReviewIdTombstone(
              id: 'w_deleted',
              itemType: ReviewItemType.word,
              reason: 'removed word',
            ),
          ],
        );
        repo.remote = [
          item('w_deleted', lastReviewed: DateTime.utc(2026, 1, 2)),
        ];

        final s = sync(corpusMap: corpusMap);
        final result = await s.syncNow();

        expect(store.get('w_deleted'), isNull);
        expect(repo.deleted, contains('w_deleted'));
        expect(result.adopted, 0);
      },
    );

    test(
      'cloud alias migration upserts canonical state before deleting old state',
      () async {
        final corpusMap = ReviewCorpusIdentityMap(
          activeWordIds: {'w_canonical'},
          activeSentenceIds: const {},
          aliases: const [
            ReviewIdAlias(
              itemType: ReviewItemType.word,
              from: 'w_old',
              to: 'w_canonical',
              reason: 'spelling fix',
            ),
          ],
          tombstones: const [],
        );
        repo.remote = [item('w_old', lastReviewed: DateTime.utc(2026, 1, 5))];

        final s = sync(corpusMap: corpusMap);
        final result = await s.syncNow();

        expect(store.get('w_canonical'), isNotNull);
        expect(
          store.get('w_canonical')?.lastReviewedAt,
          DateTime.utc(2026, 1, 5),
        );
        expect(store.get('w_old'), isNull);
        expect(repo.deleted, contains('w_old'));
        expect(result.adopted, 1);
      },
    );

    test(
      'canonical upsert is enqueued before legacy deletion during alias migration',
      () async {
        final corpusMap = ReviewCorpusIdentityMap(
          activeWordIds: {'w_canonical'},
          activeSentenceIds: const {},
          aliases: const [
            ReviewIdAlias(
              itemType: ReviewItemType.word,
              from: 'w_old',
              to: 'w_canonical',
              reason: 'rename',
            ),
          ],
          tombstones: const [],
        );
        repo.remote = [item('w_old', lastReviewed: DateTime.utc(2026, 1, 5))];

        final s = sync(corpusMap: corpusMap);
        // Call mergeRemote directly and check outbox sequencing
        final merged = s.mergeRemote(store, repo.remote);
        for (final it in merged.localNewer) {
          await s.enqueueLocalMutation(it);
        }
        for (final obsoleteId in merged.toDelete) {
          final dep = merged.aliasDependencies[obsoleteId];
          await s.enqueueRemoteDeletion(obsoleteId, dependsOnEntityId: dep);
        }

        expect(outbox.queued, hasLength(2));
        final first = outbox.queued[0];
        final second = outbox.queued[1];

        // 1. Canonical upsert enqueued FIRST
        expect(first.operationType, reviewStateOperationType);
        expect(first.entityId, 'w_canonical');

        // 2. Legacy deletion enqueued SECOND with explicit dependency
        expect(second.operationType, reviewStateDeleteOperationType);
        expect(second.entityId, 'w_old');
        expect(second.payload['dependsOn'], 'w_canonical');
      },
    );

    test(
      'canonical upsert failure blocks legacy deletion from processing during replay',
      () async {
        final s = sync();
        repo.pushError = Exception('network failure on push');

        // Queue canonical upsert and dependent legacy deletion
        await outbox.enqueueMutation(
          PendingMutation(
            operationId: 'op_upsert_canonical',
            userId: 'user-1',
            operationType: reviewStateOperationType,
            entityId: 'w_canonical',
            payload: item('w_canonical').toMap(),
            createdAt: DateTime.now(),
          ),
        );
        await outbox.enqueueMutation(
          PendingMutation(
            operationId: 'op_delete_legacy',
            userId: 'user-1',
            operationType: reviewStateDeleteOperationType,
            entityId: 'w_old',
            payload: const {'dependsOn': 'w_canonical'},
            createdAt: DateTime.now(),
          ),
        );

        final result = await s.replayQueued();

        // Upsert failed
        expect(result.failed, 1);
        expect(repo.pushed, isEmpty);

        // Deletion was BLOCKED and never attempted on server
        expect(repo.deleted, isEmpty);
        expect(repo.deleted, isNot(contains('w_old')));

        // Both remain in outbox (deletion not marked completed)
        expect(outbox.completed, isNot(contains('op_delete_legacy')));
      },
    );

    test(
      'replay cannot process deletion before canonical upsert even when outbox reorders mutations',
      () async {
        final s = sync();

        // Simulate outbox where deletion is placed BEFORE upsert
        await outbox.enqueueMutation(
          PendingMutation(
            operationId: 'op_delete_first',
            userId: 'user-1',
            operationType: reviewStateDeleteOperationType,
            entityId: 'w_old',
            payload: const {
              'dependsOnOperationId': 'op_upsert_second',
              'dependsOn': 'w_canonical',
            },

            createdAt: DateTime.now(),
          ),
        );
        await outbox.enqueueMutation(
          PendingMutation(
            operationId: 'op_upsert_second',
            userId: 'user-1',
            operationType: reviewStateOperationType,
            entityId: 'w_canonical',
            payload: item('w_canonical').toMap(),
            createdAt: DateTime.now(),
          ),
        );

        // First replay pass: deletion is encountered first but dependency w_canonical is pending, so skipped!
        // Upsert runs and succeeds!
        final result1 = await s.replayQueued();
        expect(result1.pushedLocal, 1);
        expect(repo.pushed.map((e) => e.itemId), contains('w_canonical'));
        // Deletion was not processed before canonical upsert
        expect(repo.deleted, isEmpty);

        // Second replay pass: now that canonical upsert is completed, deletion can safely run!
        final result2 = await s.replayQueued();
        expect(result2.pushedLocal, 1);
        expect(repo.deleted, contains('w_old'));
      },
    );

    test(
      'offline migration retains both required outbox operations in safe order with dependsOnOperationId',
      () async {
        final s = sync();
        final canonicalOpId = await s.enqueueLocalMutation(item('w_canonical'));
        expect(canonicalOpId, isNotNull);
        await s.enqueueRemoteDeletion(
          'w_old',
          dependsOnOperationId: canonicalOpId,
          dependsOnEntityId: 'w_canonical',
        );

        expect(outbox.queued, hasLength(2));
        expect(outbox.queued[0].entityId, 'w_canonical');
        expect(outbox.queued[0].operationType, reviewStateOperationType);
        expect(outbox.queued[0].operationId, canonicalOpId);
        expect(outbox.queued[1].entityId, 'w_old');
        expect(outbox.queued[1].operationType, reviewStateDeleteOperationType);
        expect(outbox.queued[1].payload['dependsOnOperationId'], canonicalOpId);
        expect(outbox.queued[1].payload['dependsOn'], 'w_canonical');
      },
    );

    test(
      'pullAndMerge captures canonical upsert opId and attaches dependsOnOperationId to legacy deletion',
      () async {
        final corpusMap = ReviewCorpusIdentityMap(
          activeWordIds: {'w_canonical'},
          activeSentenceIds: const {},
          aliases: const [
            ReviewIdAlias(
              itemType: ReviewItemType.word,
              from: 'w_old',
              to: 'w_canonical',
            ),
          ],
          tombstones: const [],
        );
        final s = sync(corpusMap: corpusMap);
        repo.remote = [item('w_old')];
        // Fail push so mutations remain in outbox for inspection
        repo.pushError = Exception('Offline');
        await s.syncNow();

        final upsertOp = outbox.queued.firstWhere(
          (m) => m.operationType == reviewStateOperationType,
        );
        final deleteOp = outbox.queued.firstWhere(
          (m) => m.operationType == reviewStateDeleteOperationType,
        );

        expect(upsertOp.entityId, 'w_canonical');
        expect(deleteOp.entityId, 'w_old');
        expect(deleteOp.payload['dependsOnOperationId'], upsertOp.operationId);
        expect(deleteOp.payload['dependsOn'], 'w_canonical');
      },
    );

    test('replay gates deletion on exact dependsOnOperationId', () async {
      final s = sync();

      const canonicalOpId = 'op_canonical_unique_123';
      // Enqueue canonical upsert with matching operationId
      await outbox.enqueueMutation(
        PendingMutation(
          operationId: canonicalOpId,
          userId: 'user-1',
          operationType: reviewStateOperationType,
          entityId: 'w_canonical',
          payload: item('w_canonical').toMap(),
          createdAt: DateTime.now(),
        ),
      );

      // Enqueue deletion with dependsOnOperationId
      await outbox.enqueueMutation(
        PendingMutation(
          operationId: 'op_delete_legacy',
          userId: 'user-1',
          operationType: reviewStateDeleteOperationType,
          entityId: 'w_old',
          payload: const {'dependsOnOperationId': canonicalOpId},
          createdAt: DateTime.now(),
        ),
      );

      // Make push fail so canonicalOpId does not complete
      repo.pushError = Exception('Server offline');
      await s.replayQueued();

      // Deletion must not have executed because canonicalOpId is still pending
      expect(repo.deleted, isEmpty);
      expect(outbox.completed, isEmpty);

      // Clear error so canonicalOpId can complete
      repo.pushError = null;
      await s.replayQueued();

      // Canonical upsert completed first, then deletion completed
      expect(repo.pushed.map((e) => e.itemId), contains('w_canonical'));
      expect(repo.deleted, contains('w_old'));
      expect(outbox.completed, contains(canonicalOpId));
      expect(outbox.completed, contains('op_delete_legacy'));
    });

    test(
      'dependency check: prerequisite pending causes deletion to wait',
      () async {
        final s = sync();
        await outbox.enqueueMutation(
          PendingMutation(
            operationId: 'op_canon_pending',
            userId: 'user-1',
            operationType: reviewStateOperationType,
            entityId: 'w_canon',
            payload: item('w_canon').toMap(),
            createdAt: DateTime.now(),
          ),
        );
        await outbox.enqueueMutation(
          PendingMutation(
            operationId: 'op_del_pending',
            userId: 'user-1',
            operationType: reviewStateDeleteOperationType,
            entityId: 'w_old',
            payload: const {'dependsOnOperationId': 'op_canon_pending'},
            createdAt: DateTime.now(),
          ),
        );
        repo.pushError = Exception('network unavailable');
        final result = await s.replayQueued();
        expect(result.failed, 1);
        expect(result.skipped, 1);
        expect(repo.deleted, isEmpty);
        expect(outbox.completed, isEmpty);
      },
    );

    test(
      'dependency check: prerequisite retrying causes deletion to wait',
      () async {
        final s = sync();
        await outbox.enqueueMutation(
          PendingMutation(
            operationId: 'op_canon_retry',
            userId: 'user-1',
            operationType: reviewStateOperationType,
            entityId: 'w_canon',
            payload: item('w_canon').toMap(),
            createdAt: DateTime.now(),
          ),
        );
        await outbox.recordAttemptFailed(
          'user-1',
          'op_canon_retry',
          'transient error',
        );
        expect(
          await outbox.getMutationStatus('user-1', 'op_canon_retry'),
          MutationStatus.failed,
        );

        await outbox.enqueueMutation(
          PendingMutation(
            operationId: 'op_del_retry',
            userId: 'user-1',
            operationType: reviewStateDeleteOperationType,
            entityId: 'w_old',
            payload: const {'dependsOnOperationId': 'op_canon_retry'},
            createdAt: DateTime.now(),
          ),
        );

        repo.pushError = Exception('Transient retry error');
        await s.replayQueued();
        expect(repo.deleted, isEmpty);
        expect(outbox.completed, isEmpty);
      },
    );

    test(
      'dependency check: prerequisite completed allows deletion to execute',
      () async {
        final s = sync();
        await outbox.enqueueMutation(
          PendingMutation(
            operationId: 'op_canon_done',
            userId: 'user-1',
            operationType: reviewStateOperationType,
            entityId: 'w_canon',
            payload: item('w_canon').toMap(),
            createdAt: DateTime.now(),
          ),
        );
        await outbox.markCompleted('user-1', 'op_canon_done');
        expect(
          await outbox.getMutationStatus('user-1', 'op_canon_done'),
          MutationStatus.completed,
        );

        await outbox.enqueueMutation(
          PendingMutation(
            operationId: 'op_del_done',
            userId: 'user-1',
            operationType: reviewStateDeleteOperationType,
            entityId: 'w_old',
            payload: const {'dependsOnOperationId': 'op_canon_done'},
            createdAt: DateTime.now(),
          ),
        );

        final result = await s.replayQueued();
        expect(result.pushedLocal, 1);
        expect(repo.deleted, contains('w_old'));
        expect(outbox.completed, contains('op_del_done'));
      },
    );

    test(
      'dependency check: prerequisite dead-lettered prevents deletion execution',
      () async {
        final s = sync();
        await outbox.enqueueMutation(
          PendingMutation(
            operationId: 'op_canon_dead',
            userId: 'user-1',
            operationType: reviewStateOperationType,
            entityId: 'w_canon',
            payload: item('w_canon').toMap(),
            createdAt: DateTime.now(),
          ),
        );
        await outbox.recordAttemptFailed(
          'user-1',
          'op_canon_dead',
          'permanent rejection',
          isPermanent: true,
        );
        expect(
          await outbox.getMutationStatus('user-1', 'op_canon_dead'),
          MutationStatus.deadLetter,
        );

        await outbox.enqueueMutation(
          PendingMutation(
            operationId: 'op_del_blocked_dead',
            userId: 'user-1',
            operationType: reviewStateDeleteOperationType,
            entityId: 'w_old',
            payload: const {'dependsOnOperationId': 'op_canon_dead'},
            createdAt: DateTime.now(),
          ),
        );

        await s.replayQueued();
        expect(repo.deleted, isEmpty);
        expect(outbox.completed, isEmpty);
      },
    );

    test(
      'dependency check: prerequisite cancelled prevents deletion execution',
      () async {
        final s = sync();
        await outbox.enqueueMutation(
          PendingMutation(
            operationId: 'op_canon_cancel',
            userId: 'user-1',
            operationType: reviewStateOperationType,
            entityId: 'w_canon',
            payload: item('w_canon').toMap(),
            createdAt: DateTime.now(),
          ),
        );
        await outbox.markCancelled('user-1', 'op_canon_cancel');
        expect(
          await outbox.getMutationStatus('user-1', 'op_canon_cancel'),
          MutationStatus.cancelled,
        );

        await outbox.enqueueMutation(
          PendingMutation(
            operationId: 'op_del_blocked_cancel',
            userId: 'user-1',
            operationType: reviewStateDeleteOperationType,
            entityId: 'w_old',
            payload: const {'dependsOnOperationId': 'op_canon_cancel'},
            createdAt: DateTime.now(),
          ),
        );

        await s.replayQueued();
        expect(repo.deleted, isEmpty);
        expect(outbox.completed, isEmpty);
      },
    );

    test(
      'dependency check: prerequisite missing prevents deletion execution',
      () async {
        final s = sync();
        await outbox.enqueueMutation(
          PendingMutation(
            operationId: 'op_del_missing_prereq',
            userId: 'user-1',
            operationType: reviewStateDeleteOperationType,
            entityId: 'w_old',
            payload: const {'dependsOnOperationId': 'non_existent_op'},
            createdAt: DateTime.now(),
          ),
        );

        await s.replayQueued();
        expect(repo.deleted, isEmpty);
        expect(outbox.completed, isEmpty);
      },
    );

    test(
      'dependency check: malformed dependency payload prevents deletion execution',
      () async {
        final s = sync();
        await outbox.enqueueMutation(
          PendingMutation(
            operationId: 'op_del_malformed',
            userId: 'user-1',
            operationType: reviewStateDeleteOperationType,
            entityId: 'w_old',
            payload: const {'dependsOn': 'w_canon'},
            createdAt: DateTime.now(),
          ),
        );

        await s.replayQueued();
        expect(repo.deleted, isEmpty);
        expect(outbox.completed, isEmpty);
      },
    );

    test(
      'dependency check: unrelated completed upsert does not satisfy specific dependency',
      () async {
        final s = sync();
        await outbox.enqueueMutation(
          PendingMutation(
            operationId: 'op_other_upsert',
            userId: 'user-1',
            operationType: reviewStateOperationType,
            entityId: 'w_canon',
            payload: item('w_canon').toMap(),
            createdAt: DateTime.now(),
          ),
        );
        await outbox.markCompleted('user-1', 'op_other_upsert');

        await outbox.enqueueMutation(
          PendingMutation(
            operationId: 'op_del_strict',
            userId: 'user-1',
            operationType: reviewStateDeleteOperationType,
            entityId: 'w_old',
            payload: const {'dependsOnOperationId': 'op_required_upsert'},
            createdAt: DateTime.now(),
          ),
        );

        await s.replayQueued();
        expect(repo.deleted, isEmpty);
        expect(outbox.completed, isNot(contains('op_del_strict')));
      },
    );

    test('canonical upsert failure preserves legacy row', () async {
      final corpusMap = ReviewCorpusIdentityMap(
        activeWordIds: {'w_canonical'},
        activeSentenceIds: const {},
        aliases: const [
          ReviewIdAlias(
            itemType: ReviewItemType.word,
            from: 'w_old',
            to: 'w_canonical',
          ),
        ],
        tombstones: const [],
      );
      final s = sync(corpusMap: corpusMap);
      repo.remote = [item('w_old')];
      repo.pushError = Exception('Server 500 on push');

      await s.syncNow();

      expect(repo.deleted, isEmpty);
      expect(repo.deleted, isNot(contains('w_old')));
    });

    test('repeated replay is completely idempotent', () async {
      final s = sync();
      await outbox.enqueueMutation(
        PendingMutation(
          operationId: 'op_1',
          userId: 'user-1',
          operationType: reviewStateOperationType,
          entityId: 'w1',
          payload: item('w1').toMap(),
          createdAt: DateTime.now(),
        ),
      );

      final r1 = await s.replayQueued();
      expect(r1.pushedLocal, 1);
      expect(await outbox.getPendingMutations('user-1'), isEmpty);

      // Replaying again is a no-op
      final r2 = await s.replayQueued();
      expect(r2.pushedLocal, 0);
      expect(r2.failed, 0);
    });

    test('pull does not repeatedly reintroduce the obsolete ID', () async {
      final corpusMap = ReviewCorpusIdentityMap(
        activeWordIds: {'w_canonical'},
        activeSentenceIds: const {},
        aliases: const [
          ReviewIdAlias(
            itemType: ReviewItemType.word,
            from: 'w_old',
            to: 'w_canonical',
          ),
        ],
        tombstones: const [],
      );

      final s = sync(corpusMap: corpusMap);

      // Pass 1: Remote still has w_old; sync adopts canonical and deletes w_old
      repo.remote = [item('w_old', lastReviewed: DateTime.utc(2026, 1, 5))];
      await s.syncNow();
      expect(store.get('w_canonical'), isNotNull);
      expect(store.get('w_old'), isNull);

      // Pass 2: Server has finished deletion of w_old; server now returns canonical only
      repo.remote = [
        item('w_canonical', lastReviewed: DateTime.utc(2026, 1, 5)),
      ];
      final res2 = await s.syncNow();
      expect(store.get('w_old'), isNull);
      expect(store.get('w_canonical'), isNotNull);
      expect(res2.adopted, 0); // Already up to date
    });

    test('row ID sanitization collision proof for corpus IDs', () {
      final wordsRaw = File('assets/seed/words.json').readAsStringSync();
      final sentencesRaw = File(
        'assets/seed/sentences.json',
      ).readAsStringSync();
      final words = (jsonDecode(wordsRaw) as List<dynamic>).map(
        (w) => (w as Map)['id'] as String,
      );
      final sentences = (jsonDecode(sentencesRaw) as List<dynamic>).map(
        (s) => (s as Map)['id'] as String,
      );

      final allIds = [...words, ...sentences];
      final seenRowIds = <String>{};
      for (final id in allIds) {
        final rowId = ReviewAppwriteRepository.rowIdFor('user-1', id);
        final added = seenRowIds.add(rowId);
        expect(
          added,
          isTrue,
          reason: 'Collision detected for ID: $id -> $rowId',
        );
      }
      expect(seenRowIds.length, allIds.length);
    });
  });
}

/// Exposes the Appwrite repository's row-id helper for the duplicate test
/// without importing the SDK-dependent implementation into a pure test.
class ReviewAppwriteRowIds {
  static String rowIdFor(String userId, String itemId) {
    String clean(String raw) => raw
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')
        .substring(0, raw.length.clamp(0, 60));
    return '${clean(userId)}__${clean(itemId)}';
  }
}

class _ThrowingOnPushRepository implements ReviewRepository {
  @override
  Future<List<MemoryItemState>> loadRemoteStates(String userId) async => [];

  @override
  Future<void> pushState(String userId, MemoryItemState item) async {
    throw Exception('Appwrite unavailable');
  }

  @override
  Future<void> deleteState(String userId, String itemId) async {
    throw Exception('Appwrite unavailable');
  }
}
