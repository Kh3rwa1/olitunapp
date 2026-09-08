import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:itun/core/auth/appwrite_auth_service.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/core/logging/app_logger.dart';
import 'package:itun/core/network/network_info.dart';
import 'package:itun/core/offline/mutation_outbox_service.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/shared/repositories/content_repository.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  final authService = ref.watch(appwriteAuthServiceProvider);
  final networkInfo = ref.watch(networkInfoProvider);
  return ContentRepository(
    databases: Databases(authService.client),
    networkInfo: networkInfo,
    mutationOutbox: ref.watch(mutationOutboxProvider),
  );
});

/// Bounds initial network loading when there is no usable local catalog.
final contentRequestTimeoutProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 8),
);

Future<List<ContentItem>> _loadFreshContent(
  ContentRepository repo,
  ContentKind kind,
  String? categoryId,
  Duration timeout,
) async {
  try {
    final result = await repo
        .list(kind, categoryId: categoryId)
        .timeout(timeout);
    return result.fold<List<ContentItem>>(
      (failure) => throw FailureException(failure),
      (items) => items,
    );
  } on TimeoutException {
    throw const FailureException(
      NetworkFailure(message: 'Content loading timed out. Please retry.'),
    );
  }
}

/// Cache-first lists with a background refresh, preserving the FutureProvider
/// API so existing consumers, overrides, and explicit retries keep working.
final contentListProvider =
    FutureProvider.family<List<ContentItem>, (ContentKind, String?)>((
      ref,
      arg,
    ) async {
      ref.watch(isAuthenticatedProvider);
      final kind = arg.$1;
      final categoryId = arg.$2;
      final repo = ref.watch(contentRepositoryProvider);
      final timeout = ref.watch(contentRequestTimeoutProvider);
      var active = true;
      Timer? refreshTimer;
      ref.onDispose(() {
        active = false;
        refreshTimer?.cancel();
      });

      List<ContentItem>? cached;
      try {
        final local = await repo.cachedList(kind, categoryId: categoryId);
        cached = local.fold((_) => null, (items) => items);
      } catch (_) {
        // A broken local cache must not prevent a successful network load.
        AppLogger.debug('Local content unavailable; requesting fresh content.');
      }

      if (cached != null) {
        if (active) {
          // The next event turn publishes the initial Future before a fast
          // refresh can update state. Disposal also cancels queued work.
          refreshTimer = Timer(Duration.zero, () async {
            try {
              final fresh = await _loadFreshContent(
                repo,
                kind,
                categoryId,
                timeout,
              );
              if (active) ref.state = AsyncData(fresh);
            } catch (_) {
              // Keep usable learning content on screen during network errors.
              AppLogger.debug('Content refresh failed; retaining local data.');
            }
          });
        }
        return cached;
      }

      return _loadFreshContent(repo, kind, categoryId, timeout);
    });

/// Family Provider for Single Items.
///
/// Failures propagate to the UI's AsyncValue error state (which offers a
/// retry action) instead of being masked with a fabricated fallback item.
final contentDetailProvider =
    FutureProvider.family<ContentItem, (ContentKind, String)>((ref, arg) async {
      final kind = arg.$1;
      final id = arg.$2;
      final repo = ref.watch(contentRepositoryProvider);

      final res = await repo.get(kind, id);
      return res.fold(
        (failure) => throw FailureException(failure),
        (item) => item,
      );
    });

/// Wraps a [Failure] so it can travel through Riverpod's AsyncValue.error
/// channel while preserving the typed failure information.
class FailureException implements Exception {
  final Failure failure;
  const FailureException(this.failure);

  @override
  String toString() => failure.toString();
}
