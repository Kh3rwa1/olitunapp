// ignore_for_file: deprecated_member_use
import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:fpdart/fpdart.dart';
import 'package:itun/core/api/appwrite_databases_pagination.dart';
import 'package:itun/core/config/appwrite_config.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/core/logging/app_logger.dart';
import 'package:itun/core/network/network_info.dart';
import 'package:itun/core/observability/crash_reporting.dart';
import 'package:itun/core/offline/mutation_outbox_service.dart';
import 'package:itun/core/storage/cache_service.dart';
import 'package:itun/features/lessons/data/models/lesson_model.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/shared/models/content_item_extensions.dart';

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

  static List<ContentItem>? _cachedBundledSentenceLessons;
  static List<ContentItem>? _cachedBundledVocabLessons;
  static List<ContentItem>? _cachedBundledSentences;
  static List<ContentItem>? _cachedBundledWords;

  static Future<List<ContentItem>> _loadBundledSeedItems(
    ContentKind kind,
    String? categoryId,
  ) async {
    try {
      if (kind == ContentKind.lesson) {
        final List<ContentItem> allLessons = [];

        // 1. Sentence & Grammar & Folktale Lessons (23 lessons)
        if (_cachedBundledSentenceLessons == null) {
          try {
            final jsonStr = await rootBundle.loadString(
              'assets/seed/sentence_lessons.json',
            );
            final raw = jsonDecode(jsonStr) as List<dynamic>;
            _cachedBundledSentenceLessons = raw
                .cast<Map<String, dynamic>>()
                .map((map) {
                  final lesson = LessonModel.fromJson(map);
                  return ContentItem(
                    id: lesson.id,
                    kind: ContentKind.lesson,
                    categoryId: lesson.categoryId.isNotEmpty
                        ? lesson.categoryId
                        : 'cat_sentences',
                    title: lesson.titleLatin,
                    titleOlChiki: lesson.titleOlChiki.isNotEmpty
                        ? lesson.titleOlChiki
                        : null,
                    subtitle: lesson.description,
                    order: lesson.order,
                    durationSeconds: lesson.estimatedMinutes * 60,
                    blocks: lesson.blocks
                        .asMap()
                        .entries
                        .map((e) => e.value.toContentBlock(e.key))
                        .toList(),
                    isPublished: true,
                    updatedAt: DateTime(2026, 8, 30),
                  );
                })
                .toList();
          } catch (_) {
            _cachedBundledSentenceLessons = [];
          }
        }

        // 2. Vocab Lessons (14 lessons)
        if (_cachedBundledVocabLessons == null) {
          try {
            final jsonStr = await rootBundle.loadString(
              'assets/seed/vocab_lessons.json',
            );
            final raw = jsonDecode(jsonStr) as List<dynamic>;
            _cachedBundledVocabLessons = raw.cast<Map<String, dynamic>>().map((
              map,
            ) {
              final lesson = LessonModel.fromJson(map);
              return ContentItem(
                id: lesson.id,
                kind: ContentKind.lesson,
                categoryId: lesson.categoryId.isNotEmpty
                    ? lesson.categoryId
                    : 'cat_vocab',
                title: lesson.titleLatin,
                titleOlChiki: lesson.titleOlChiki.isNotEmpty
                    ? lesson.titleOlChiki
                    : null,
                subtitle: lesson.description,
                order: lesson.order,
                durationSeconds: lesson.estimatedMinutes * 60,
                blocks: lesson.blocks
                    .asMap()
                    .entries
                    .map((e) => e.value.toContentBlock(e.key))
                    .toList(),
                isPublished: true,
                updatedAt: DateTime(2026, 8, 30),
              );
            }).toList();
          } catch (e, stack) {
            _cachedBundledVocabLessons = [];
            _logSeedLoadFailure('lessons', e, stack);
          }
        }

        allLessons.addAll(_cachedBundledSentenceLessons ?? []);
        allLessons.addAll(_cachedBundledVocabLessons ?? []);

        if (categoryId != null && categoryId.isNotEmpty) {
          return allLessons.where((l) {
            if (categoryId == 'cat_sentences' ||
                categoryId == 'seed_sentences' ||
                categoryId.contains('sentence')) {
              return l.categoryId == 'cat_sentences' ||
                  l.categoryId == 'seed_sentences' ||
                  l.id.contains('sentence') ||
                  l.id.contains('grammar') ||
                  l.id.contains('story');
            }
            if (categoryId == 'cat_vocab' ||
                categoryId == 'cat_words' ||
                categoryId == 'seed_words' ||
                categoryId.contains('vocab') ||
                categoryId.contains('word')) {
              return l.categoryId == 'cat_vocab' ||
                  l.categoryId == 'cat_words' ||
                  l.categoryId == 'seed_words' ||
                  l.id.contains('vocab');
            }
            return l.categoryId == categoryId;
          }).toList();
        }
        return allLessons;
      }

      if (kind == ContentKind.sentence) {
        if (_cachedBundledSentences == null) {
          try {
            final jsonStr = await rootBundle.loadString(
              'assets/seed/sentences.json',
            );
            final raw = jsonDecode(jsonStr) as List<dynamic>;
            _cachedBundledSentences = raw.cast<Map<String, dynamic>>().map((s) {
              return ContentItem(
                id: s['id'] as String? ?? '',
                kind: ContentKind.sentence,
                categoryId: s['category'] as String? ?? 'cat_sentences',
                category: s['category'] as String? ?? 'General',
                title: s['sentenceLatin'] as String? ?? '',
                titleOlChiki: s['sentenceOlChiki'] as String?,
                olChiki: s['sentenceOlChiki'] as String?,
                subtitle: s['meaning'] as String?,
                order: s['order'] as int? ?? 1,
                audioUrl: s['audioUrl'] as String? ?? s['audio_url'] as String?,
                blocks: const [],
                tags: [
                  if (s['usage'] != null) s['usage'] as String,
                  if (s['pronunciation'] != null)
                    'pronunciation:${s['pronunciation']}',
                ],
                isPublished: s['isActive'] as bool? ?? true,
                updatedAt: DateTime(2026, 8, 30),
              );
            }).toList();
          } catch (e, stack) {
            _cachedBundledSentences = [];
            _logSeedLoadFailure('sentences', e, stack);
          }
        }
        return _cachedBundledSentences ?? [];
      }

      if (kind == ContentKind.word) {
        if (_cachedBundledWords == null) {
          try {
            final jsonStr = await rootBundle.loadString(
              'assets/seed/words.json',
            );
            final raw = jsonDecode(jsonStr) as List<dynamic>;
            _cachedBundledWords = raw.cast<Map<String, dynamic>>().map((w) {
              return ContentItem(
                id: w['id'] as String? ?? '',
                kind: ContentKind.word,
                categoryId: w['category'] as String? ?? 'cat_vocab',
                category: w['category'] as String? ?? 'General',
                title: w['wordLatin'] as String? ?? '',
                titleOlChiki: w['wordOlChiki'] as String?,
                olChiki: w['wordOlChiki'] as String?,
                subtitle: w['meaning'] as String?,
                order: w['order'] as int? ?? 1,
                audioUrl: w['audioUrl'] as String? ?? w['audio_url'] as String?,
                blocks: const [],
                tags: [
                  if (w['pronunciation'] != null)
                    'pronunciation:${w['pronunciation']}',
                ],
                isPublished: w['isActive'] as bool? ?? true,
                updatedAt: DateTime(2026, 8, 30),
              );
            }).toList();
          } catch (e, stack) {
            _cachedBundledWords = [];
            _logSeedLoadFailure('words', e, stack);
          }
        }
        return _cachedBundledWords ?? [];
      }
    } catch (e, stack) {
      _logSeedLoadFailure('bundled seed', e, stack);
    }
    return [];
  }

  /// Seed loading failure is data-critical: the app loses its offline-first
  /// fallback dataset, so surface it to logs AND crash reporting.
  static void _logSeedLoadFailure(String what, Object e, StackTrace stack) {
    AppLogger.error(
      'ContentRepository: failed to load bundled seed $what: $e',
      name: 'ContentRepository',
    );
    CrashReporting.recordError(e, stack);
  }

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

  String? _categoryAttribute(ContentKind kind) {
    switch (kind) {
      case ContentKind.lesson:
      case ContentKind.rhyme:
        return 'categoryId';
      case ContentKind.word:
      case ContentKind.sentence:
        return 'category';
      case ContentKind.letter:
      case ContentKind.number:
        return null;
    }
  }

  bool _hasOrderAttribute(ContentKind kind) => kind != ContentKind.rhyme;

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
            permissions: [Permission.read(Role.any())],
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
      try {
        await CacheService.set(itemCacheKey, item.toJson());
        await CacheService.delete(_cacheListKey(item.kind, item.categoryId));
        await CacheService.delete(_cacheListKey(item.kind, null));
        await _enqueueOfflineMutation(item);
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
    if (outbox == null) return;
    try {
      await outbox.enqueueMutation(
        PendingMutation(
          operationId:
              'upsert_${item.kind.name}_${item.id}_${DateTime.now().millisecondsSinceEpoch}',
          userId: contentMutationQueueUserId,
          operationType: 'content.upsert',
          entityId: item.id,
          payload: {'kind': item.kind.name, 'item': item.toJson()},
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      // Queueing is best-effort: the local cache already holds the edit.
      AppLogger.debug('[Content] Failed to queue offline mutation: $e');
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
