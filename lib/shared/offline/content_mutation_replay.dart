import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../../core/network/network_info.dart';
import '../../core/offline/mutation_outbox_service.dart';
import '../models/content_item.dart';
import '../providers/content_providers.dart';
import '../repositories/content_repository.dart';

/// Starts the content mutation replay engine for the application's lifetime.
///
/// Replay is triggered on startup, connectivity recovery, outbox changes, and
/// a bounded periodic timer. Transient failures use durable capped backoff;
/// only malformed or explicitly permanent mutations become dead letters.
final contentMutationReplayProvider = Provider<void>((ref) {
  final service = _ContentMutationReplayService(
    outbox: ref.watch(mutationOutboxProvider),
    repository: ref.watch(contentRepositoryProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
  unawaited(service.start());
  ref.onDispose(service.dispose);
});

class _ContentMutationReplayService {
  _ContentMutationReplayService({
    required MutationOutboxService outbox,
    required ContentRepository repository,
    required NetworkInfo networkInfo,
  }) : _outbox = outbox,
       _repository = repository,
       _networkInfo = networkInfo;

  final MutationOutboxService _outbox;
  final ContentRepository _repository;
  final NetworkInfo _networkInfo;
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<String>? _outboxSubscription;
  Timer? _periodicReplay;
  bool _disposed = false;
  bool _running = false;
  bool _rerunRequested = false;

  Future<void> start() async {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      results,
    ) {
      if (!results.contains(ConnectivityResult.none)) {
        unawaited(_replay());
      }
    });
    _outboxSubscription = _outbox.changes.listen((userId) {
      if (userId == contentMutationQueueUserId) unawaited(_replay());
    });
    _periodicReplay = Timer.periodic(const Duration(seconds: 30), (_) {
      unawaited(_replay());
    });
    await _replay();
  }

  Future<void> _replay() async {
    if (_disposed) return;
    if (_running) {
      _rerunRequested = true;
      return;
    }
    _running = true;
    try {
      do {
        _rerunRequested = false;
        if (!await _networkInfo.isConnected) return;
        final report = await _outbox.replayPendingMutations(
          userId: contentMutationQueueUserId,
          handler: _handleMutation,
        );
        if (report.failed > 0) {
          AppLogger.debug(
            '[ContentOutbox] Replay deferred ${report.failed} failed mutations',
          );
        }
        if (report.skipped > 0) {
          AppLogger.debug(
            '[ContentOutbox] Replay skipped or deferred ${report.skipped} mutations',
          );
        }
        await _outbox.removeTerminalMutations(
          userId: contentMutationQueueUserId,
        );
      } while (_rerunRequested && !_disposed);
    } finally {
      _running = false;
    }
  }

  Future<void> _handleMutation(PendingMutation mutation) async {
    if (mutation.operationType != 'content.upsert') {
      throw FormatException(
        'Unsupported operation type: ${mutation.operationType}',
      );
    }
    final kindName = mutation.payload['kind'];
    final itemJson = mutation.payload['item'];
    if (kindName is! String || itemJson is! Map) {
      throw const FormatException('Invalid payload for content mutation.');
    }
    final kind = ContentKind.values.firstWhere(
      (value) => value.name == kindName,
      orElse: () => throw FormatException('Unsupported content kind: $kindName'),
    );
    final item = ContentItem.fromJson(
      Map<String, dynamic>.from(itemJson),
      mutation.entityId,
      kind,
    );
    final result = await _repository.upsert(item, allowOfflineQueue: false);
    result.fold(
      (failure) => throw StateError(failure.message),
      (_) => null,
    );
  }

  void dispose() {
    _disposed = true;
    _periodicReplay?.cancel();
    unawaited(_connectivitySubscription?.cancel());
    unawaited(_outboxSubscription?.cancel());
  }
}
