import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:itun/core/auth/appwrite_auth_service.dart';
import 'package:itun/core/network/network_info.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/shared/repositories/content_repository.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  final authService = ref.watch(appwriteAuthServiceProvider);
  final networkInfo = ref.watch(networkInfoProvider);
  return ContentRepository(
    databases: Databases(authService.client),
    networkInfo: networkInfo,
  );
});

/// Family Provider for Lists
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
      return res.fold((failure) => <ContentItem>[], (list) => list);
    });

/// Family Provider for Single Items
final contentDetailProvider =
    FutureProvider.family<ContentItem, (ContentKind, String)>((ref, arg) async {
      final kind = arg.$1;
      final id = arg.$2;
      final repo = ref.watch(contentRepositoryProvider);

      final res = await repo.get(kind, id);
      return res.fold(
        (failure) => ContentRepository.synthesizeFallbackItem(kind, id),
        (item) => item,
      );
    });
