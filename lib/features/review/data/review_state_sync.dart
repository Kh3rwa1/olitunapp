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
//    and merges per item via [ReviewStateMergePolicy] (deterministic
//    evidence combination — NOT last-writer-wins: concurrent recalls from
//    multiple devices are preserved, not clobbered). Server-newer wins for
//    display fields only; local-newer is re-enqueued for push. No full
//    history fetch on Home.
//
// Failure handling: malformed rows skipped, network failures keep the
// outbox entry for retry, pull failures leave the local state untouched.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/offline/mutation_outbox_service.dart';
import '../domain/review_corpus_identity.dart';
import '../domain/review_item.dart';
import '../domain/review_repository.dart';
import '../domain/review_state_merge_policy.dart';
import 'review_recall_operation.dart';
import 'review_store.dart';
import 'review_sync_outbox.dart';

class ReviewStateSync {
  final ReviewRepository repository;
  final ReviewOutbox outbox;
  final Future<String?> Function() resolveUserId;
  final Future<ReviewStore> Function() loadStore;
  final ReviewCorpusIdentityMap? corpusMap;
  final void Function()? onStoreUpdated;

  String? _cachedUserId;
  Future<void>? _activeSync;
  Future<void>? _activeReplay;

  /// Observable sync health (WS7). Mutated in place by sync/replay.
  final ReviewSyncMetrics metrics = ReviewSyncMetrics();

  ReviewStateSync({
    required this.repository,
    required this.outbox,
    required this.resolveUserId,
    required this.loadStore,
    this.corpusMap,
    this.onStoreUpdated,
  });

  String? get cachedUserId => _cachedUserId;

  void clearCachedUserId() {
    _cachedUserId = null;
  }

  /// Queues one stable recall operation for durable cloud apply. The
  /// operation's own [ReviewRecallOperation.operationId] is the outbox key,
  /// so retries/replays after timeout or process death never double-apply.
  /// Returns the operationId on success, null for guests/offline-queued
  /// failures (the entry simply stays queued). No-op when validation fails.
  Future<String?> enqueueRecallOperation(ReviewRecallOperation op) async {
    try {
      final reason = op.validate();
      if (reason != null) {
        AppLogger.debug('ReviewStateSync: invalid recall op dropped: $reason');
        return null;
      }
      final userId = _cachedUserId ?? await resolveUserId();
      _cachedUserId = userId;
      if (userId == null || userId.isEmpty) return null;
      if (op.userId.isNotEmpty && op.userId != userId) {
        AppLogger.debug('ReviewStateSync: recall op user mismatch; dropped.');
        return null;
      }
      await outbox.enqueueMutation(
        PendingMutation(
          operationId: op.operationId,
          userId: userId,
          operationType: reviewRecallOperationType,
          entityId: op.itemId,
          payload: op.toMap(),
          createdAt: DateTime.now(),
        ),
      );
      metrics.totalRecallOperations++;
      return op.operationId;
    } catch (e) {
      // Cloud sync must never break learning.
      AppLogger.debug('ReviewStateSync: recall enqueue failed: $e');
      return null;
    }
  }

  /// Queues one local mutation for durable cloud push. Local Hive write —
  /// cheap enough to call after every learning event. No-ops for guests
  /// (local-only until the first sync resolves the user) and when offline
  /// (the entry simply stays queued). Returns the generated operationId on success.
  ///
  /// Compatibility path: snapshot upsert coalesced by userId + canonical
  /// itemId. Callers answering questions should prefer
  /// [enqueueRecallOperation] (exactly one stable op per answer).
  Future<String?> enqueueLocalMutation(MemoryItemState item) async {
    try {
      final userId = _cachedUserId ?? await resolveUserId();
      _cachedUserId = userId;
      if (userId == null || userId.isEmpty) return null;
      final opId =
          'review_${item.itemId}_${item.lastReviewedAt?.millisecondsSinceEpoch ?? 0}';
      await outbox.enqueueMutation(
        PendingMutation(
          operationId: opId,
          userId: userId,
          operationType: reviewStateOperationType,
          entityId: item.itemId,
          payload: item.toMap(),
          createdAt: DateTime.now(),
        ),
      );
      return opId;
    } catch (e) {
      // Cloud sync must never break learning.
      AppLogger.debug('ReviewStateSync: enqueue failed (kept local): $e');
      return null;
    }
  }

  /// Queues an obsolete or tombstoned item for durable cloud deletion.
  /// Replayed via the outbox on connectivity.
  /// If [dependsOnOperationId] or [dependsOnEntityId] is specified, the deletion is blocked during replay
  /// until the prerequisite upsert operation has succeeded.
  Future<void> enqueueRemoteDeletion(
    String itemId, {
    String? dependsOnOperationId,
    String? dependsOnEntityId,
  }) async {
    try {
      final userId = _cachedUserId ?? await resolveUserId();
      _cachedUserId = userId;
      if (userId == null || userId.isEmpty || itemId.isEmpty) return;
      await outbox.enqueueMutation(
        PendingMutation(
          operationId:
              'review_del_${itemId}_${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          operationType: reviewStateDeleteOperationType,
          entityId: itemId,
          payload: {
            if (dependsOnOperationId != null && dependsOnOperationId.isNotEmpty)
              'dependsOnOperationId': dependsOnOperationId,
            if (dependsOnEntityId != null && dependsOnEntityId.isNotEmpty)
              'dependsOn': dependsOnEntityId,
          },
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      AppLogger.debug(
        'ReviewStateSync: enqueue delete failed (kept local): $e',
      );
    }
  }

  /// Startup/login/connectivity sync: pull server rows, merge per item
  /// (deterministic evidence merge), then drain the outbox. Single-flight: a
  /// sync already in progress is awaited, never duplicated.
  Future<ReviewSyncResult> syncNow() async {
    final existing = _activeSync;
    if (existing != null) {
      await existing;
      return ReviewSyncResult.empty;
    }
    final stopwatch = Stopwatch()..start();
    final pending = _pullAndMerge();
    _activeSync = pending;
    try {
      final result = await pending;
      await replayQueued();
      stopwatch.stop();
      metrics.lastSyncDuration = stopwatch.elapsed;
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
      // Single durable write for the whole pull adoption batch (never N
      // full-map writes for N adopted rows).
      if (merged.result.adopted > 0) {
        final ok = await store.persist();
        if (!ok) {
          AppLogger.debug(
            'ReviewStateSync: pull adoption persist failed; local state '
            'kept in memory and will be retried on next mutation.',
          );
        }
      }

      // Canonical items must be persisted/enqueued FIRST before old rows are deleted
      final canonicalOpIds = <String, String>{};
      for (final item in merged.localNewer) {
        final opId = await enqueueLocalMutation(item);
        if (opId != null) {
          canonicalOpIds[item.itemId] = opId;
        }
      }
      for (final obsoleteId in merged.toDelete) {
        final canonicalDep = merged.aliasDependencies[obsoleteId];
        final canonicalOpId = canonicalDep != null
            ? canonicalOpIds[canonicalDep]
            : null;
        await enqueueRemoteDeletion(
          obsoleteId,
          dependsOnOperationId: canonicalOpId,
          dependsOnEntityId: canonicalDep,
        );
      }
      if (merged.result.adopted > 0) {
        onStoreUpdated?.call();
      }
      return merged.result;
    } catch (e) {
      // Pull failure leaves the local state untouched; outbox retries later.
      AppLogger.debug('ReviewStateSync: pull failed (local untouched): $e');
      return ReviewSyncResult.empty;
    }
  }

  /// Conflict resolution: per-item deterministic merge (see
  /// [ReviewStateMergePolicy]; NOT last-writer-wins) with
  /// [ReviewStateSync.mergeRemote]'s never-reviewed fallback on
  /// introducedAt. Reconciles against [corpusMap] when available:
  /// - Tombstoned remote items are queued for deletion without being adopted.
  /// - Renamed remote items are migrated to the canonical ID, collisions resolved
  ///   by effective timestamp, canonical state saved/enqueued, and old row queued for delete.
  /// - Unknown remote orphans are skipped (not adopted into active queue, not deleted).
  @visibleForTesting
  ({
    ReviewSyncResult result,
    List<MemoryItemState> localNewer,
    List<String> toDelete,
    Map<String, String> aliasDependencies,
  })
  mergeRemote(
    ReviewStore store,
    List<MemoryItemState> remote, {
    ReviewCorpusIdentityMap? corpusMapOverride,
  }) {
    final activeMap = corpusMapOverride ?? corpusMap;
    var adopted = 0, keptLocal = 0;
    final newer = <MemoryItemState>[];
    final toDelete = <String>[];
    final aliasDeps = <String, String>{};
    final seen = <String>{};

    for (final item in remote) {
      if (item.itemId.isEmpty || !seen.add(item.itemId)) continue;

      if (activeMap != null) {
        // 1. Tombstoned: do not adopt, queue obsolete cloud row for deletion
        if (activeMap.isTombstoned(item.itemId)) {
          toDelete.add(item.itemId);
          continue;
        }

        // 2. Renamed: alias target
        final canonicalId = activeMap.resolveCanonicalId(
          item.itemId,
          expectedType: item.itemType,
        );
        if (canonicalId != null) {
          aliasDeps[item.itemId] = canonicalId;
          final candidate = item.copyWith(itemId: canonicalId);
          final local = store.get(canonicalId);
          if (local == null) {
            store.adoptRemote(candidate);
            adopted++;
            newer.add(candidate);
            toDelete.add(item.itemId);
          } else {
            final merged = ReviewStateMergePolicy.merge(local, candidate);
            final localNeedsUpdate = merged != local;
            if (localNeedsUpdate) {
              store.adoptRemote(merged);
              adopted++;
            } else {
              keptLocal++;
            }
            newer.add(merged);
            toDelete.add(item.itemId);
          }
          continue;
        }

        // 3. Unknown remote orphan: do not adopt into active queue, do not delete
        if (!activeMap.isActive(item.itemId)) {
          AppLogger.warning(
            'ReviewStateSync: unknown remote orphan skipped: ${item.itemId}',
          );
          continue;
        }
      }

      // Active item: deterministic merge preserving concurrent learning evidence
      final local = store.get(item.itemId);
      if (local == null) {
        store.adoptRemote(item);
        adopted++;
        continue;
      }
      final merged = ReviewStateMergePolicy.merge(local, item);
      final localNeedsUpdate = merged != local;
      final remoteNeedsUpdate = merged != item;
      if (localNeedsUpdate) {
        store.adoptRemote(merged);
        adopted++;
      }
      if (remoteNeedsUpdate) {
        newer.add(merged);
      }
      if (!localNeedsUpdate && !remoteNeedsUpdate) {
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
      toDelete: toDelete,
      aliasDependencies: aliasDeps,
    );
  }

  /// Drains queued review-state writes and deletions. Single-flight; each entry is
  /// pushed/deleted once and completed on success, retried on failure with backoff.
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
    var bytesWritten = 0;
    try {
      final userId = _cachedUserId ?? await resolveUserId();
      _cachedUserId = userId;
      if (userId == null || userId.isEmpty) return ReviewSyncResult.empty;

      final pending = await outbox.getPendingMutations(userId);
      // Refresh metrics snapshot (no learning text included).
      metrics.pendingOperations = pending.length;
      DateTime? oldest;
      for (final m in pending) {
        if (oldest == null || m.createdAt.isBefore(oldest)) {
          oldest = m.createdAt;
        }
        if (m.status == MutationStatus.deadLetter) metrics.deadLetterCount++;
      }
      if (oldest != null) {
        metrics.oldestPendingAge = DateTime.now().difference(oldest);
      }
      final store = await loadStore();
      final now = DateTime.now();
      final seenOpIds = <String>{};
      for (final mutation in pending) {
        if (mutation.operationType != reviewStateOperationType &&
            mutation.operationType != reviewStateDeleteOperationType &&
            mutation.operationType != reviewRecallOperationType) {
          continue;
        }
        if (mutation.status == MutationStatus.deadLetter) {
          skipped++;
          continue;
        }
        // Coalescing guard: the same stable operationId MUST appear at
        // most once per replay pass. A duplicate entry is counted and
        // completed without re-applying (idempotent, never double-counts).
        if (!seenOpIds.add(mutation.operationId)) {
          metrics.duplicateOperationCount++;
          await outbox.markCompleted(userId, mutation.operationId);
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
          if (mutation.operationType == reviewRecallOperationType) {
            final op = ReviewRecallOperation.fromMap(
              Map<String, dynamic>.from(mutation.payload),
            );
            final reason = op.validate();
            if (reason != null) {
              await outbox.recordAttemptFailed(
                userId,
                mutation.operationId,
                'invalid recall op: $reason',
                isPermanent: true,
              );
              skipped++;
              continue;
            }
            if (op.userId.isNotEmpty && op.userId != userId) {
              await outbox.recordAttemptFailed(
                userId,
                mutation.operationId,
                'recall op owner mismatch',
                isPermanent: true,
              );
              skipped++;
              continue;
            }
            final opRepo = repository is ReviewOperationRepository
                ? repository as ReviewOperationRepository
                : null;
            if (opRepo != null) {
              // Idempotent server apply by operationId.
              final applied = await opRepo.applyRecallOperation(
                userId,
                ReviewRecallOperationPayload(
                  operationId: op.operationId,
                  userId: userId,
                  itemId: op.itemId,
                  itemType: op.itemType,
                  exerciseType: op.exerciseType,
                  correct: op.correct,
                  responseTimeMs: op.responseTimeMs,
                  occurredAt: op.occurredAt,
                  deviceId: op.deviceId,
                  localSequence: op.localSequence,
                  schemaVersion: op.schemaVersion,
                ),
              );
              if (!applied) metrics.duplicateOperationCount++;
            } else {
              // Compatibility fallback: push the LIVE snapshot once.
              final live = store.get(op.itemId);
              if (live != null) {
                await repository.pushState(userId, live);
              }
            }
            await outbox.markCompleted(userId, mutation.operationId);
            replayed++;
            continue;
          }
          if (mutation.operationType == reviewStateDeleteOperationType) {
            final itemId = mutation.entityId;
            if (itemId.isEmpty) {
              await outbox.recordAttemptFailed(
                userId,
                mutation.operationId,
                'empty itemId for delete',
                isPermanent: true,
              );
              skipped++;
              continue;
            }

            // Dependency gate: if this deletion depends on a canonical upsert,
            // ensure that exact prerequisite operation has a durable completed result.
            final dependsOnOpId =
                mutation.payload['dependsOnOperationId'] as String?;
            if (dependsOnOpId != null && dependsOnOpId.isNotEmpty) {
              final status = await outbox.getMutationStatus(
                userId,
                dependsOnOpId,
              );
              if (status == MutationStatus.completed) {
                // Prerequisite has durably succeeded. Proceed with deletion.
              } else if (status == MutationStatus.pending ||
                  status == MutationStatus.syncing ||
                  status == MutationStatus.failed) {
                // Prerequisite is still pending or retrying. Deletion waits.
                AppLogger.debug(
                  'ReviewStateSync: deletion of "$itemId" waiting for prerequisite '
                  '"$dependsOnOpId" (status: $status).',
                );
                skipped++;
                continue;
              } else {
                // Prerequisite is deadLetter, cancelled, missing, or malformed.
                // Dependent legacy deletion must never execute.
                AppLogger.warning(
                  'ReviewStateSync: deletion of "$itemId" blocked: prerequisite '
                  '"$dependsOnOpId" status is $status. Deletion will not execute.',
                );
                skipped++;
                continue;
              }
            } else {
              final dependsOn = mutation.payload['dependsOn'] as String?;
              if (dependsOn != null && dependsOn.isNotEmpty) {
                // Missing exact operationId: malformed dependency payload
                AppLogger.warning(
                  'ReviewStateSync: deletion of "$itemId" has entity dependency '
                  '"$dependsOn" but lacks dependsOnOperationId. Deletion will not execute.',
                );
                skipped++;
                continue;
              }
            }

            await repository.deleteState(userId, itemId);
            await outbox.markCompleted(userId, mutation.operationId);
            replayed++;
            continue;
          }

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
          bytesWritten += mutation.payload.length;
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
      metrics.replaySuccess += replayed;
      metrics.replayFailure += failed;
      metrics.lastBytesWritten = bytesWritten;
      metrics.pendingOperations = 0;
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
