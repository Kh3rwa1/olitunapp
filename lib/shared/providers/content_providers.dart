import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:itun/core/auth/appwrite_auth_service.dart';
import 'package:itun/core/error/failures.dart';
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

/// Family Provider for Lists.
///
/// An empty successful catalog is distinct from an unavailable catalog.
/// Preserve repository failures so consumers can display their error/retry
/// state. Cached or bundled fallback data remains a successful repository
/// result and is not converted into an error here.
final contentListProvider =
    FutureProvider.family<List<ContentItem>, (ContentKind, String?)>((
      ref,
      arg,
    ) async {
      ref.watch(isAuthenticatedProvider);
      final kind = arg.$1;
      final categoryId = arg.$2;
      final repo = ref.watch(contentRepositoryProvider);

      final res = await repo.list(kind, categoryId: categoryId);
      return res.fold(
        (failure) => throw FailureException(failure),
        (list) => list,
      );
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
