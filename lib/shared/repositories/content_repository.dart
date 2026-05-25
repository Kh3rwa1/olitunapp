// ignore_for_file: deprecated_member_use
import 'package:appwrite/appwrite.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/core/api/appwrite_databases_pagination.dart';
import 'package:itun/core/auth/appwrite_auth_service.dart';
import 'package:itun/core/config/appwrite_config.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/core/network/network_info.dart';
import 'package:itun/core/storage/cache_service.dart';
import 'package:itun/shared/models/content_item.dart';

class ContentRepository {
  final Databases _databases;
  final NetworkInfo _networkInfo;

  ContentRepository({
    required Databases databases,
    required NetworkInfo networkInfo,
  }) : _databases = databases,
       _networkInfo = networkInfo;

  String _getCollectionId(ContentKind kind) {
    switch (kind) {
      case ContentKind.letter:
        return 'letters';
      case ContentKind.number:
        return 'numbers';
      case ContentKind.word:
        return 'words';
      case ContentKind.sentence:
        return 'sentences';
      case ContentKind.lesson:
        return 'lessons';
      case ContentKind.rhyme:
        return 'rhymes';
    }
  }

  String _cacheListKey(ContentKind kind, String? categoryId) {
    return 'content_list_${kind.name}_${categoryId ?? 'all'}';
  }

  String _cacheItemKey(ContentKind kind, String id) {
    return 'content_item_${kind.name}_$id';
  }

  /// Lists all content items of a specific kind, optionally filtered by category.
  Future<Either<Failure, List<ContentItem>>> list(
    ContentKind kind, {
    String? categoryId,
  }) async {
    final collectionId = _getCollectionId(kind);
    final cacheKey = _cacheListKey(kind, categoryId);

    if (await _networkInfo.isConnected) {
      try {
        final List<String> queries = [
          if (categoryId != null && categoryId.isNotEmpty)
            Query.equal('category_id', categoryId),
          Query.orderAsc('order'),
          Query.limit(500),
        ];

        final response = await AppwriteDatabasesPagination.listDocuments(
          _databases,
          databaseId: AppwriteConfig.databaseId,
          collectionId: collectionId,
          queries: queries,
        );

        final items = response.map((doc) {
          return ContentItem.fromJson(doc.data, doc.$id);
        }).toList();

        // Update local cache
        final cachedData = items.map((e) => e.toJson()).toList();
        await CacheService.set(cacheKey, cachedData);

        // Also cache individual items
        for (final item in items) {
          await CacheService.set(_cacheItemKey(kind, item.id), item.toJson());
        }

        return right(items);
      } catch (e) {
        // Fallback to cache on error
        return _getCachedList(kind, categoryId, e.toString());
      }
    } else {
      return _getCachedList(kind, categoryId, 'No internet connection');
    }
  }

  Future<Either<Failure, List<ContentItem>>> _getCachedList(
    ContentKind kind,
    String? categoryId,
    String originalError,
  ) async {
    try {
      final cacheKey = _cacheListKey(kind, categoryId);
      final cached = await CacheService.getList<ContentItem>(
        cacheKey,
        ContentItem.fromJson,
      );

      if (cached != null && cached.isNotEmpty) {
        return right(cached);
      }
      return left(ServerFailure(message: originalError));
    } catch (e) {
      return left(CacheFailure(message: 'Failed to read cached content: $e'));
    }
  }

  /// Gets a single content item by ID.
  Future<Either<Failure, ContentItem>> get(ContentKind kind, String id) async {
    final collectionId = _getCollectionId(kind);
    final cacheKey = _cacheItemKey(kind, id);

    if (await _networkInfo.isConnected) {
      try {
        final doc = await _databases.getDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: collectionId,
          documentId: id,
        );

        final item = ContentItem.fromJson(doc.data, doc.$id);
        await CacheService.set(cacheKey, item.toJson());

        return right(item);
      } catch (e) {
        return _getCachedItem(kind, id, e.toString());
      }
    } else {
      return _getCachedItem(kind, id, 'No internet connection');
    }
  }

  Future<Either<Failure, ContentItem>> _getCachedItem(
    ContentKind kind,
    String id,
    String originalError,
  ) async {
    try {
      final cacheKey = _cacheItemKey(kind, id);
      final cached = await CacheService.get<ContentItem>(
        cacheKey,
        ContentItem.fromJson,
      );

      if (cached != null) {
        return right(cached);
      }
      return left(ServerFailure(message: originalError));
    } catch (e) {
      return left(CacheFailure(message: 'Failed to read cached item: $e'));
    }
  }

  /// Upserts a content item to Appwrite and updates the local cache.
  Future<Either<Failure, ContentItem>> upsert(ContentItem item) async {
    try {
      // 1. Validate the model layers
      ContentItem.validate(item.kind, item.tracing);
    } on ContentValidationException catch (e) {
      return left(TracingRequiredFailure(message: e.message));
    }

    final collectionId = _getCollectionId(item.kind);
    final itemCacheKey = _cacheItemKey(item.kind, item.id);

    if (await _networkInfo.isConnected) {
      try {
        final appwritePayload = item.toAppwrite();

        ContentItem? resultItem;
        try {
          // Attempt to create document first
          final doc = await _databases.createDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: collectionId,
            documentId: item.id,
            data: appwritePayload,
            permissions: [Permission.read(Role.users())],
          );
          resultItem = ContentItem.fromJson(doc.data, doc.$id);
        } on AppwriteException catch (ae) {
          if (ae.code == 409) {
            // Document already exists, perform update
            final doc = await _databases.updateDocument(
              databaseId: AppwriteConfig.databaseId,
              collectionId: collectionId,
              documentId: item.id,
              data: appwritePayload,
              permissions: [Permission.read(Role.users())],
            );
            resultItem = ContentItem.fromJson(doc.data, doc.$id);
          } else {
            rethrow;
          }
        }

        await CacheService.set(itemCacheKey, resultItem.toJson());
        // Evict the cached list to force refresh
        await CacheService.delete(_cacheListKey(item.kind, item.categoryId));
        await CacheService.delete(_cacheListKey(item.kind, null));
        return right(resultItem);
      } catch (e) {
        return left(ServerFailure(message: 'Upsert failed: $e'));
      }
    } else {
      // Local caching offline support
      try {
        await CacheService.set(itemCacheKey, item.toJson());
        await CacheService.delete(_cacheListKey(item.kind, item.categoryId));
        await CacheService.delete(_cacheListKey(item.kind, null));
        return right(item);
      } catch (e) {
        return left(CacheFailure(message: 'Offline caching failed: $e'));
      }
    }
  }

  /// Deletes a content item.
  Future<Either<Failure, Unit>> delete(ContentKind kind, String id) async {
    final collectionId = _getCollectionId(kind);
    final itemCacheKey = _cacheItemKey(kind, id);

    if (await _networkInfo.isConnected) {
      try {
        // Read item to know categoryId before deletion for cache clear
        final itemRes = await get(kind, id);
        String? categoryId;
        itemRes.fold((_) {}, (item) => categoryId = item.categoryId);

        await _databases.deleteDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: collectionId,
          documentId: id,
        );

        await CacheService.delete(itemCacheKey);
        if (categoryId != null) {
          await CacheService.delete(_cacheListKey(kind, categoryId));
        }
        await CacheService.delete(_cacheListKey(kind, null));

        return right(unit);
      } catch (e) {
        return left(ServerFailure(message: 'Deletion failed: $e'));
      }
    } else {
      return left(
        const NetworkFailure(
          message: 'Internet connection is required to delete content',
        ),
      );
    }
  }
}

// Providers
final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  final authService = ref.watch(appwriteAuthServiceProvider);
  final networkInfo = ref.watch(networkInfoProvider);
  return ContentRepository(
    databases: Databases(authService.client),
    networkInfo: networkInfo,
  );
});

// Family Provider for Lists
final contentListProvider =
    FutureProvider.family<List<ContentItem>, (ContentKind, String?)>((
      ref,
      arg,
    ) async {
      final kind = arg.$1;
      final categoryId = arg.$2;
      final repo = ref.watch(contentRepositoryProvider);

      final res = await repo.list(kind, categoryId: categoryId);
      return res.fold((failure) => throw failure, (list) => list);
    });

// Family Provider for Single Items
final contentDetailProvider =
    FutureProvider.family<ContentItem, (ContentKind, String)>((ref, arg) async {
      final kind = arg.$1;
      final id = arg.$2;
      final repo = ref.watch(contentRepositoryProvider);

      final res = await repo.get(kind, id);
      return res.fold((failure) => throw failure, (item) => item);
    });
