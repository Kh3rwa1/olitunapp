// Review state sync orchestrator: local cache <-> Appwrite.
//
// Architecture (offline-first):
//  - READ path: Home/Today's Review reads the local ReviewStore only —
//    zero network on home open. Cloud sync never blocks learning.
//  - WRITE path: every local mutation enqueues a durable outbox mutation
//    (MutationOutboxService, backoff + dead-letter). A replay loop pushes
//    queued writes to Appwrite — online it drains in seconds; offline it
//    stays queued and drains on reconnect.
//  - PULL path: startup/login/connectivity pulls the user's server rows
//    and merges per item (LWW on lastReviewedAt). Server-newer wins;
//    local-newer is re-enqueued for push. No full history fetch on Home.
//
// Failure handling: malformed rows skipped, network failures keep the
// outbox entry for retry, pull failures leave the local state untouched.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/offline/mutation_outbox_service.dart';
import '../domain/review_item.dart';
import '../domain/review_repository.dart';
import 'review_store.dart';

/// Outbox operation type for review-state upserts (one replay handler).
const reviewStateOperationType = 'review_state.upsert';

/// Minimal outbox contract needed by review sync. MutationOutboxService
/// satisfies it in production (adapter in review_sync_init.dart); tests
/// use an in-memory fake — no Hive, no Appwrite.
abstract class ReviewOutbox {
  Future<void> enqueueMutation(PendingMutation mutation);
  Future<List<PendingMutation>> getPendingMutations(String userId);
  Future<void> recordAttemptFailed(
    String userId,
    String operationId,
    String error, {
    bool isPermanent = false,
  });
  Future<void> markCompleted(String userId, String operationId);
}

class MutationOutboxAdapter implements ReviewOutbox {
  final MutationOutboxService _service;
  const MutationOutboxAdapter(this._service);

  @override
  Future<void> enqueueMutation(PendingMutation mutation) =>
      _service.enqueueMutation(mutation);

  @override
  Future<List<PendingMutation>> getPendingMutations(String userId) =>
      _service.getPendingMutations(userId);

  @override
  Future<void> recordAttemptFailed(
    String userId,
    String operationId,
    String error, {
    bool isPermanent = false,
  }) => _service.recordAttemptFailed(
    userId,
    operationId,
    error,
    isPermanent: isPermanent,
  );

  @override
  Future<void> markCompleted(String userId, String operationId) =>
      _service.markCompleted(userId, operationId);
}

class ReviewStateSync {
  final ReviewRepository repository;
  final ReviewOutbox outbox;
  final Future<String?> Function() resolveUserId;
  final Future<ReviewStore> Function() loadStore;

  String? _cachedUserId;
  Future<void>? _activeSync;
  Future<void>? _activeReplay;

  ReviewStateSync({
    required this.repository,
    required this.outbox,
    required this.resolveUserId,
    required this.loadStore,
  });

  String? get cachedUserId => _cachedUserId;

  /// Queues one local mutation for durable cloud push. Local Hive write —
  /// cheap enough to call after every learning event. No-ops for guests
  /// (local-only until the first sync resolves the user) and when offline
  /// (the entry simply stays queued).
  Future<void> enqueueLocalMutation(MemoryItemState item) async {
    try {
      final userId = _cachedUserId ?? await resolveUserId();
      _cachedUserId = userId;
      if (userId == null || userId.isEmpty) return;
      await outbox.enqueueMutation(
        PendingMutation(
          operationId:
              'review_${item.itemId}_${item.lastReviewedAt?.millisecondsSinceEpoch ?? 0}',
          userId: userId,
          operationType: reviewStateOperationType,
          entityId: item.itemId,
          payload: item.toMap(),
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      // Cloud sync must never break learning.
      AppLogger.debug('ReviewStateSync: enqueue failed (kept local): $e');
    }
  }

  /// Startup/login/connectivity sync: pull server rows, merge per item
  /// (LWW on lastReviewedAt), then drain the outbox. Single-flight: a
  /// sync already in progress is awaited, never duplicated.
  Future<ReviewSyncResult> syncNow() async {
    final existing = _activeSync;
    if (existing != null) {
      await existing;
      return ReviewSyncResult.empty;
    }
    final pending = _pullAndMerge();
    _activeSync = pending;
    try {
      final result = await pending;
      await replayQueued();
      return result;
    } finally {
      _activeSync = null;
    }
  }

  Future<ReviewSyncResult> _pullAndMerge() async {
    try {
      final userId = _cachedUserId ?? await resolveUserId();
      _cachedUserId = userId;
      if (userId == null || userId.isEmpty) return ReviewSyncResult.empty;

      final store = await loadStore();
      final remote = await repository.loadRemoteStates(userId);
      final merged = mergeRemote(store, remote);
      // Push local-newer items after merge (deterministic: completes
      // before syncNow returns; queue entries retry on failure).
      for (final item in merged.localNewer) {
        await enqueueLocalMutation(item);
      }
      return merged.result;
    } catch (e) {
      // Pull failure leaves the local state untouched; outbox retries later.
      AppLogger.debug('ReviewStateSync: pull failed (local untouched): $e');
      return ReviewSyncResult.empty;
    }
  }

  /// Conflict resolution: per-item LWW on lastReviewedAt (introducedAt as
  /// the never-reviewed fallback). Server-newer adopts; local-newer is
  /// reported for push (the caller enqueues — kept synchronous and pure
  /// so merge is deterministic and testable); identical timestamps keep
  /// local (no-op).
  @visibleForTesting
  ({ReviewSyncResult result, List<MemoryItemState> localNewer}) mergeRemote(
    ReviewStore store,
    List<MemoryItemState> remote,
  ) {
    var adopted = 0, keptLocal = 0;
    final newer = <MemoryItemState>[];
    final seen = <String>{};
    for (final item in remote) {
      if (item.itemId.isEmpty || !seen.add(item.itemId)) continue;
      final local = store.get(item.itemId);
      final remoteTs = item.lastReviewedAt ?? item.introducedAt;
      if (local == null) {
        store.adoptRemote(item);
        adopted++;
        continue;
      }
      final localTs = local.lastReviewedAt ?? local.introducedAt;
      if (remoteTs.isAfter(localTs)) {
        store.adoptRemote(item);
        adopted++;
      } else if (localTs.isAfter(remoteTs)) {
        // Local is newer (edited on another device offline, or pulled
        // before this push landed): caller re-enqueues for push.
        newer.add(local);
      } else {
        keptLocal++;
      }
    }
    return (
      result: ReviewSyncResult(
        pulled: remote.length,
        adopted: adopted,
        keptLocal: keptLocal,
        pushedLocal: newer.length,
        failed: 0,
        skipped: remote.length - adopted - keptLocal - newer.length,
      ),
      localNewer: newer,
    );
  }

  /// Drains queued review-state writes. Single-flight; each entry is
  /// pushed once and deleted on success (markCompleted), retried on
  /// failure with the outbox's backoff, dead-lettered after 5 attempts.
  Future<ReviewSyncResult> replayQueued() async {
    final existing = _activeReplay;
    if (existing != null) {
      await existing;
      return ReviewSyncResult.empty;
    }
    final pending = _replayQueued();
    _activeReplay = pending;
    try {
      return await pending;
    } finally {
      _activeReplay = null;
    }
  }

  Future<ReviewSyncResult> _replayQueued() async {
    var replayed = 0, failed = 0, skipped = 0;
    try {
      final userId = _cachedUserId ?? await resolveUserId();
      _cachedUserId = userId;
      if (userId == null || userId.isEmpty) return ReviewSyncResult.empty;

      final pending = await outbox.getPendingMutations(userId);
      final store = await loadStore();
      final now = DateTime.now();
      for (final mutation in pending) {
        if (mutation.operationType != reviewStateOperationType) continue;
        if (mutation.status == MutationStatus.deadLetter) {
          skipped++;
          continue;
        }
        // Respect backoff: entries whose retry window hasn't elapsed wait
        // for a later trigger (mutation, connectivity, restart).
        if (mutation.nextRetryAt.isAfter(now)) {
          skipped++;
          continue;
        }
        try {
          final item = MemoryItemState.fromMap(mutation.payload);
          if (item.itemId.isEmpty) {
            await outbox.recordAttemptFailed(
              userId,
              mutation.operationId,
              'empty itemId payload',
              isPermanent: true,
            );
            skipped++;
            continue;
          }
          // Push the LIVE local state (not the stale payload) so a
          // rapid-fire sequence of recalls converges to the latest.
          final live = store.get(item.itemId) ?? item;
          await repository.pushState(userId, live);
          await outbox.markCompleted(userId, mutation.operationId);
          replayed++;
        } catch (e) {
          failed++;
          await outbox.recordAttemptFailed(
            userId,
            mutation.operationId,
            e.toString(),
          );
        }
      }
    } catch (e) {
      AppLogger.debug('ReviewStateSync: replay failed: $e');
    }
    return ReviewSyncResult(
      pulled: 0,
      adopted: 0,
      keptLocal: 0,
      pushedLocal: replayed,
      failed: failed,
      skipped: skipped,
    );
  }
}
