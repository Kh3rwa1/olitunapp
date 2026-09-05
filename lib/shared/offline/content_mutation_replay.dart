import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/core/logging/app_logger.dart';
import 'package:itun/core/network/network_info.dart';
import 'package:itun/core/offline/mutation_outbox_service.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/shared/repositories/content_repository.dart';

/// Outcome of one replay pass over the offline content mutation queue.
class ReplaySummary {
  final int replayed;
  final int failed;
  final int skipped;

  const ReplaySummary({
    required this.replayed,
    required this.failed,
    required this.skipped,
  });

  bool get isClean => failed == 0;
}

/// Drains the durable content mutation outbox by re-running queued upserts
/// through [ContentRepository]. Executed when the app boots and whenever
/// connectivity is regained, matching the outage playbook's recovery model.
class ContentMutationReplay {
  final MutationOutboxService _outbox;
  final NetworkInfo _networkInfo;
  final Future<Either<Failure, ContentItem>> Function(ContentItem item)
  _executeUpsert;

  ContentMutationReplay({
    required MutationOutboxService outbox,
    required NetworkInfo networkInfo,
    required Future<Either<Failure, ContentItem>> Function(ContentItem item)
    executeUpsert,
  }) : _outbox = outbox,
       _networkInfo = networkInfo,
       _executeUpsert = executeUpsert;

  Future<ReplaySummary>? _activeReplay;

  Future<ReplaySummary> replayPending() {
    return _activeReplay ??= _replayPending().whenComplete(() {
      _activeReplay = null;
    });
  }

  Future<ReplaySummary> _replayPending() async {
    if (!await _networkInfo.isConnected) {
      return const ReplaySummary(replayed: 0, failed: 0, skipped: 0);
    }

    final pending = await _outbox.getPendingMutations(
      contentMutationQueueUserId,
    );
    var replayed = 0;
    var failed = 0;
    var skipped = 0;
    final blockedEntities = <String>{};

    for (final mutation in pending) {
      final entityKey = '${mutation.payload['kind']}:${mutation.entityId}';
      if (mutation.status == MutationStatus.deadLetter) {
        skipped++;
        continue;
      }
      if (blockedEntities.contains(entityKey) ||
          mutation.nextRetryAt.isAfter(DateTime.now())) {
        blockedEntities.add(entityKey);
        skipped++;
        continue;
      }
      try {
        final item = _deserialize(mutation);
        if (item == null) {
          // Un-parseable payload can never succeed; dead-letter immediately.
          await _outbox.recordAttemptFailed(
            mutation.userId,
            mutation.operationId,
            'Unparseable mutation payload',
            isPermanent: true,
          );
          failed++;
          continue;
        }

        final result = await _executeUpsert(item);
        await result.fold<Future<void>>(
          (failure) async {
            blockedEntities.add(entityKey);
            failed++;
            await _outbox.recordAttemptFailed(
              mutation.userId,
              mutation.operationId,
              failure.message,
            );
          },
          (_) async {
            await _outbox.markCompleted(mutation.userId, mutation.operationId);
            replayed++;
          },
        );
      } catch (e) {
        blockedEntities.add(entityKey);
        failed++;
        await _outbox.recordAttemptFailed(
          mutation.userId,
          mutation.operationId,
          e.toString(),
        );
      }
    }

    if (replayed > 0 || failed > 0) {
      AppLogger.debug(
        '[ContentReplay] Replayed $replayed queued edits, $failed failed, $skipped dead-lettered.',
      );
    }
    return ReplaySummary(replayed: replayed, failed: failed, skipped: skipped);
  }

  ContentItem? _deserialize(PendingMutation mutation) {
    try {
      final payload = mutation.payload;
      final kind = ContentKind.values.firstWhere(
        (k) => k.name == payload['kind'],
      );
      final itemJson = Map<String, dynamic>.from(payload['item'] as Map);
      return ContentItem.fromJson(itemJson, mutation.entityId, kind);
    } catch (e) {
      // The caller dead-letters un-parseable payloads; surface why.
      AppLogger.debug(
        '[ContentReplay] Failed to deserialize ${mutation.operationId}: $e',
      );
      return null;
    }
  }
}

final contentMutationReplayProvider = Provider<ContentMutationReplay>((ref) {
  final repo = ref.watch(contentRepositoryProvider);
  return ContentMutationReplay(
    outbox: ref.watch(mutationOutboxProvider),
    networkInfo: ref.watch(networkInfoProvider),
    executeUpsert: (item) => repo.upsert(item, allowOfflineQueue: false),
  );
});

/// Keeps a connectivity listener alive for the app's lifetime: replays queued
/// offline edits once at startup and every time connectivity is regained.
/// Watch this provider from the app root.
final mutationReplayInitProvider = Provider<void>((ref) {
  final replay = ref.watch(contentMutationReplayProvider);

  var disposed = false;
  ref.onDispose(() => disposed = true);
  Future<void> safeReplay() async {
    if (disposed) return;
    try {
      await replay.replayPending();
    } catch (e) {
      AppLogger.debug('[ContentReplay] Replay pass failed: $e');
    }
  }

  // Startup pass: drain anything queued during a previous offline session.
  Future<void>.microtask(safeReplay);
  final retryTimer = Timer.periodic(const Duration(seconds: 30), (_) {
    unawaited(safeReplay());
  });
  ref.onDispose(retryTimer.cancel);
  ref.listen(connectivityStreamProvider, (previous, next) {
    next.whenData((results) {
      if (!results.contains(ConnectivityResult.none)) {
        Future<void>.microtask(safeReplay);
      }
    });
  });
});
