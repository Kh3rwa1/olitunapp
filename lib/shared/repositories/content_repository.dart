// ignore_for_file: deprecated_member_use
import 'package:appwrite/appwrite.dart';
import 'package:fpdart/fpdart.dart';
import 'package:itun/core/api/appwrite_databases_pagination.dart';
import 'package:itun/core/config/appwrite_config.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/core/logging/app_logger.dart';
import 'package:itun/core/network/network_info.dart';
import 'package:itun/core/offline/mutation_outbox_service.dart';
import 'package:itun/core/storage/cache_service.dart';
import 'content_seed_loader.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/shared/security/premium_content_policy.dart';

// Provider-level API lives in ../providers/content_providers.dart;
// re-exported here for compatibility.
export '../providers/content_providers.dart';

/// Queue namespace for offline content edits. Content mutations are
/// device-local team edits (not personal data), so they share one queue that
/// is drained by the content mutation replay service when connectivity
/// returns, regardless of which admin account is signed in.
const String contentMutationQueueUserId = 'content_admin';

class ContentRepository {
  final Databases _databases;
  final NetworkInfo _networkInfo;
  final MutationOutboxService? _mutationOutbox;

  ContentRepository({
    required Databases databases,
    required NetworkInfo networkInfo,
    MutationOutboxService? mutationOutbox,
  }) : _databases = databases,
       _networkInfo = networkInfo,
       _mutationOutbox = mutationOutbox;

  static Future<List<ContentItem>> _loadBundledSeedItems(
    ContentKind kind,
    String? categoryId,
  ) => ContentSeedLoader.loadBundledSeedItems(kind, categoryId);

  static List<ContentItem> _mergeContentItems(
    List<ContentItem> bundled,
    List<ContentItem> remote,
  ) {
    final Map<String, ContentItem> byId = {};
    for (final item in bundled) {
      byId[item.id] = item;
    }
    for (final item in remote) {
      byId[item.id] = item;
    }
    final list = byId.values.toList();
    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  String _getCollectionId(ContentKind kind) => switch (kind) {
    ContentKind.letter => 'letters',
    ContentKind.number => 'numbers',
    ContentKind.word => 'words',
    ContentKind.sentence => 'sentences',
    ContentKind.lesson => 'lessons',
    ContentKind.rhyme => 'rhymes',
  };

  String? _categoryAttribute(ContentKind kind) => switch (kind) {
    ContentKind.lesson || ContentKind.rhyme => 'categoryId',
    ContentKind.word || ContentKind.sentence => 'category',
    ContentKind.letter || ContentKind.number => null,
  };

  bool _hasOrderAttribute(ContentKind kind) => kind != ContentKind.rhyme;

  String _cacheListKey(ContentKind kind, String? categoryId) {
    return 'content_list_${kind.name}_${categoryId ?? 'all'}';
  }

  String _cacheItemKey(ContentKind kind, String id) {
    return 'content_item_${kind.name}_$id';
  }

  /// Reads bundled/cached content without checking connectivity or contacting
  /// Appwrite. Missing content remains a failure, not a fabricated empty list.
  Future<Either<Failure, List<ContentItem>>> cachedList(
    ContentKind kind, {
    String? categoryId,
  }) => _getCachedList(kind, categoryId);

  /// Refreshes content from the network, with the existing offline fallback.
  Future<Either<Failure, List<ContentItem>>> list(
    ContentKind kind, {
    String? categoryId,
  }) async {
    final collectionId = _getCollectionId(kind);
    final cacheKey = _cacheListKey(kind, categoryId);

    // 1. Always retrieve full bundled seed dataset
    final bundledItems = await _loadBundledSeedItems(kind, categoryId);

    if (await _networkInfo.isConnected) {
      try {
        final categoryAttribute = _categoryAttribute(kind);
        final List<String> queries = [
          if (categoryAttribute != null &&
              categoryId != null &&
              categoryId.isNotEmpty)
            Query.equal(categoryAttribute, categoryId),
          if (_hasOrderAttribute(kind)) Query.orderAsc('order'),
          Query.limit(500),
        ];

        final response = await AppwriteDatabasesPagination.listDocuments(
          _databases,
          databaseId: AppwriteConfig.databaseId,
          collectionId: collectionId,
          queries: queries,
        );

        final remoteItems = response.map((doc) {
          return ContentItem.fromJson(doc.data, doc.$id, kind);
        }).toList();

        // Merge remote items with full bundled catalog (bundled seed content always available)
        final mergedItems = _mergeContentItems(bundledItems, remoteItems);

        // Update local cache
        final cachedData = mergedItems.map((e) => e.toJson()).toList();
        await CacheService.set(cacheKey, cachedData);

        // Also cache individual items
        for (final item in mergedItems) {
          await CacheService.set(_cacheItemKey(kind, item.id), item.toJson());
        }

        return right(mergedItems);
      } catch (e) {
        // Fallback to cache or bundled seeds on error
        return _getCachedList(kind, categoryId, fallback: bundledItems);
      }
    } else {
      return _getCachedList(kind, categoryId, fallback: bundledItems);
    }
  }

  Future<Either<Failure, List<ContentItem>>> _getCachedList(
    ContentKind kind,
    String? categoryId, {
    List<ContentItem>? fallback,
  }) async {
    try {
      final cacheKey = _cacheListKey(kind, categoryId);
      final cached = await CacheService.getList<ContentItem>(
        cacheKey,
        (data) => ContentItem.fromJson(data, null, kind),
      );

      final bundled = fallback ?? await _loadBundledSeedItems(kind, categoryId);

      if (cached != null && cached.isNotEmpty) {
        final merged = _mergeContentItems(bundled, cached);
        return right(merged);
      }

      if (bundled.isNotEmpty) {
        return right(bundled);
      }

      // No cached, bundled, or remotely fetched data is available: surface the
      // failure so the UI can show its error state instead of fabricated items.
      return left(
        CacheFailure(message: 'No offline content available for ${kind.name}.'),
      );
    } catch (e) {
      final bundled = fallback ?? await _loadBundledSeedItems(kind, categoryId);
      if (bundled.isNotEmpty) {
        return right(bundled);
      }
      return left(
        CacheFailure(
          message: 'Offline content unavailable for ${kind.name}: $e',
        ),
      );
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

        final item = ContentItem.fromJson(doc.data, doc.$id, kind);
        await CacheService.set(cacheKey, item.toJson());

        return right(item);
      } catch (e) {
        return _getCachedItem(kind, id);
      }
    } else {
      return _getCachedItem(kind, id);
    }
  }

  Future<Either<Failure, ContentItem>> _getCachedItem(
    ContentKind kind,
    String id,
  ) async {
    try {
      final cacheKey = _cacheItemKey(kind, id);
      final cached = await CacheService.get<ContentItem>(
        cacheKey,
        (data) => ContentItem.fromJson(data, null, kind),
      );

      if (cached != null) {
        return right(cached);
      }

      // Check bundled seed items
      final bundled = await _loadBundledSeedItems(kind, null);
      final bundledItem = bundled.cast<ContentItem?>().firstWhere(
        (item) => item?.id == id,
        orElse: () => null,
      );

      if (bundledItem != null) {
        return right(bundledItem);
      }

      // Nothing cached or bundled: surface the failure instead of returning a
      // fabricated item, so the UI can show its error and retry state.
      return left(
        CacheFailure(message: 'Content "$id" is not available offline.'),
      );
    } catch (e) {
      return left(
        CacheFailure(message: 'Offline content lookup failed for "$id": $e'),
      );
    }
  }

  Future<PublicationDecision> _publicationDecisionFor(ContentItem item) async {
    if (item.kind != ContentKind.lesson) {
      if (item.isPremium) {
        return const PublicationDecision.protected('item-marked-premium');
      }
      return const PublicationDecision.public('non-lesson-content');
    }

    if (item.categoryId.trim().isEmpty) {
      return PremiumContentPolicy.forContentItem(
        isPremium: item.isPremium,
        categoryResolved: false,
      );
    }

    try {
      final category = await _databases
          .getDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: 'categories',
            documentId: item.id,
          )
          .timeout(const Duration(seconds: 6));
      return PremiumContentPolicy.forContentItem(
        isPremium: item.isPremium,
        categoryUnlockMode: category.data['unlockMode'] as String?,
        lessonOrder: item.order,
        previewLessonCount: category.data['previewLessonCount'] as int? ?? 0,
      );
    } catch (_) {
      return PremiumContentPolicy.forContentItem(
        isPremium: item.isPremium,
        categoryResolved: false,
      );
    }
  }

  List<String> _readPermissions(PublicationDecision decision) =>
      decision.allowAnonymousRead ? [Permission.read(Role.any())] : const [];

  /// Upserts a content item to Appwrite and updates the local cache.
  Future<Either<Failure, ContentItem>>> upsert(
    ContentItem item, {
    bool allowOfflineQueue = true,
  }) async {
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
        final decision = await _publicationDecisionFor(item);
        final permissions = _readPermissions(decision);
        final appwritePayload = item.toAppwriteAttributes();

        ContentItem? resultItem;
        try {
          // Attempt to create document first
          final doc = await _databases.createDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: collectionId,
            documentId: item.id,
            data: appwritePayload,
            permissions: permissions,
          );
          resultItem = ContentItem.fromJson(doc.data, doc.$id, item.kind);
        } on AppwriteException catch (ae) {
          if (ae.code == 409) {
            // Document already exists, perform update
            final doc = await _databases.updateDocument(
              databaseId: AppwriteConfig.databaseId,
              collectionId: collectionId,
              documentId: item.id,
              data: appwritePayload,
              permissions: permissions,
            );
            resultItem = ContentItem.fromJson(doc.data, doc.$id, item.kind);
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
      // Offline support: cache locally and queue a durable mutation so the
      // edit replays to Appwrite automatically when connectivity returns.
      if (!allowOfflineQueue) {
        return left(
          const NetworkFailure(message: 'Connection lost during replay.'),
        );
      }
      try {
        // The outbox is authoritative. Cache writes are only an optimistic view.
        await _enqueueOfflineMutation(item);
        await CacheService.set(itemCacheKey, item.toJson());
        await CacheService.delete(_cacheListKey(item.kind, item.categoryId));
        await CacheService.delete(_cacheListKey(item.kind, null));
        return right(item);
      } catch (e) {
        return left(CacheFailure(message: 'Offline caching failed: $e'));
      }
    }
  }

  /// Queues an offline content edit in the durable mutation outbox so it is
  /// replayed (with retries and dead-lettering) once the device is back online.
  Future<void> _enqueueOfflineMutation(ContentItem item) async {
    final outbox = _mutationOutbox;
    if (outbox == null) throw StateError('Durable offline storage unavailable');
    try {
      await outbox.enqueueMutation(
        PendingMutation(
          operationId: 'upsert_${item.kind.name}_${item.id}_${ID.unique()}',
          userId: contentMutationQueueUserId,
          operationType: 'content.upsert',
          entityId: item.id,
          payload: {'kind': item.kind.name, 'item': item.toJson()},
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      AppLogger.debug('[Content] Failed to queue offline mutation: $e');
      rethrow;
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
