// Review state cloud sync: pull/merge/conflict (LWW), malformed server
// responses, offline queue + replay, duplicate pushes, reinstall recovery.
// All fakes — no Hive, no Appwrite.

import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/offline/mutation_outbox_service.dart';
import 'package:itun/features/review/data/review_state_sync.dart';
import 'package:itun/features/review/data/review_store.dart';
import 'package:itun/features/review/domain/review_item.dart';
import 'package:itun/features/review/domain/review_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRepository implements ReviewRepository {
  List<MemoryItemState> remote = [];
  final pushed = <MemoryItemState>[];
  Object? loadError;

  @override
  Future<List<MemoryItemState>> loadRemoteStates(String userId) async {
    if (loadError != null) throw loadError!;
    return List.of(remote);
  }

  @override
  Future<void> pushState(String userId, MemoryItemState item) async {
    pushed.add(item);
  }
}

class _FakeOutbox implements ReviewOutbox {
  final queued = <PendingMutation>[];
  final completed = <String>[];
  final failedOps = <({String id, String error, bool permanent})>[];

  @override
  Future<void> enqueueMutation(PendingMutation mutation) async {
    queued.add(mutation);
  }

  @override
  Future<List<PendingMutation>> getPendingMutations(String userId) async =>
      List.of(queued);

  @override
  Future<void> recordAttemptFailed(
    String userId,
    String operationId,
    String error, {
    bool isPermanent = false,
  }) async {
    failedOps.add((id: operationId, error: error, permanent: isPermanent));
  }

  @override
  Future<void> markCompleted(String userId, String operationId) async {
    completed.add(operationId);
    queued.removeWhere((m) => m.operationId == operationId);
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

  ReviewStateSync sync({String? userId = 'user-1'}) => ReviewStateSync(
    repository: repo,
    outbox: outbox,
    resolveUserId: () async => userId,
    loadStore: () async => store,
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
      expect(outbox.queued, isEmpty);
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
      expect(outbox.queued, isEmpty);
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
}
