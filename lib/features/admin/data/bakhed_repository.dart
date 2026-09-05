import 'package:appwrite/appwrite.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/core/auth/appwrite_auth_service.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/core/logging/app_logger.dart';
import 'package:itun/core/network/network_info.dart';
import 'package:itun/core/api/appwrite_db_service.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/shared/providers/bakhed_content_provider.dart';

class BakhedRepository {
  final AppwriteDbService _dbService;
  final Storage _storage;
  final NetworkInfo _networkInfo;

  BakhedRepository({
    required AppwriteDbService dbService,
    required Storage storage,
    required NetworkInfo networkInfo,
  }) : _dbService = dbService,
       _storage = storage,
       _networkInfo = networkInfo;

  /// List all rhymes/stories from the rhymes collection
  Future<Either<Failure, List<ContentItem>>> list() async {
    if (await _networkInfo.isConnected) {
      try {
        final response = await _dbService.listDocuments(
          'rhymes',
          queries: [Query.limit(500)],
        );
        final items = response.map((data) {
          final id = data['id'] as String;
          return ContentItem.fromJson(data, id, ContentKind.rhyme);
        }).toList();
        return right(items);
      } catch (e) {
        return left(ServerFailure(message: 'Failed to list rhymes: $e'));
      }
    } else {
      return left(const NetworkFailure());
    }
  }

  /// Get a single rhyme by its document ID
  Future<Either<Failure, ContentItem>> get(String id) async {
    if (await _networkInfo.isConnected) {
      try {
        final data = await _dbService.getDocument('rhymes', id);
        final item = ContentItem.fromJson(data, id, ContentKind.rhyme);
        return right(item);
      } on AppwriteException catch (e) {
        return left(
          ServerFailure(
            message: 'Failed to fetch rhyme $id: ${e.message}',
            code: e.code,
          ),
        );
      } catch (e) {
        return left(ServerFailure(message: 'Failed to fetch rhyme $id: $e'));
      }
    } else {
      return left(const NetworkFailure());
    }
  }

  /// Upsert (create or update) a rhyme/story metadata document
  Future<Either<Failure, Unit>> upsert(ContentItem item) async {
    if (await _networkInfo.isConnected) {
      try {
        final payload = item.toAppwriteAttributes();
        try {
          // Attempt update first
          await _dbService.updateDocument('rhymes', item.id, payload);
        } catch (e) {
          // If update fails (e.g. document not found), attempt create
          await _dbService.createDocument('rhymes', item.id, payload);
        }
        return right(unit);
      } catch (e) {
        return left(
          ServerFailure(message: 'Failed to save rhyme metadata: $e'),
        );
      }
    } else {
      return left(const NetworkFailure());
    }
  }

  /// Cascade delete a rhyme along with its child subcollection records and audio file.
  Future<Either<Failure, Unit>> delete(String id) async {
    if (await _networkInfo.isConnected) {
      try {
        // 1. Fetch document to read audioFileId
        final rhymeRes = await get(id);
        String? audioFileId;
        rhymeRes.fold((_) {}, (item) => audioFileId = item.audioFileId);

        // 2. Delete play-along audio file from storage (if exists)
        if (audioFileId != null && audioFileId!.isNotEmpty) {
          try {
            await _storage.deleteFile(bucketId: 'audio', fileId: audioFileId!);
          } catch (e) {
            // Log and continue — never block the cascade DB cleanup below.
            AppLogger.warning('BakhedRepository: audio delete failed: $e');
          }
        }

        // 3. Cascade delete child documents from subcollections
        await _cleanSubcollectionDocuments('bakhed_lyrics', id);
        await _cleanSubcollectionDocuments('bakhed_vocabulary', id);
        await _cleanSubcollectionDocuments('bakhed_cultural_notes', id);

        // 4. Finally, delete the rhyme metadata document
        await _dbService.deleteDocument('rhymes', id);

        return right(unit);
      } catch (e) {
        return left(ServerFailure(message: 'Cascade delete failed: $e'));
      }
    } else {
      return left(const NetworkFailure());
    }
  }

  /// Helper to delete all documents matching bakhedId in a subcollection
  Future<void> _cleanSubcollectionDocuments(
    String collectionId,
    String bakhedId,
  ) async {
    try {
      final response = await _dbService.listDocuments(
        collectionId,
        queries: [Query.equal('bakhedId', bakhedId), Query.limit(100)],
      );
      for (final doc in response) {
        try {
          await _dbService.deleteDocument(collectionId, doc['id'] as String);
        } catch (e) {
          // Best-effort child delete: continue with the remaining docs, but
          // a missed delete leaves an orphaned doc — surface it in logs.
          AppLogger.warning(
            'BakhedRepository: child delete failed in $collectionId '
            '(doc ${doc['id']}): $e',
            name: 'BakhedRepository',
          );
        }
      }
    } catch (e) {
      // A failed subcollection listing leaves orphaned child docs behind —
      // surface it, but the parent cascade delete still proceeds.
      AppLogger.warning(
        'BakhedRepository: subcollection cleanup failed for $collectionId: $e',
      );
    }
  }

  /// Fetch lyrics lines for a rhyme
  Future<Either<Failure, List<BakhedLyricLine>>> getLyrics(
    String bakhedId,
  ) async {
    if (await _networkInfo.isConnected) {
      try {
        final response = await _dbService.listDocuments(
          'bakhed_lyrics',
          queries: [
            Query.equal('bakhedId', bakhedId),
            Query.orderAsc('lineIndex'),
            Query.limit(100),
          ],
        );
        final lines = response.map((data) {
          return BakhedLyricLine.fromJson(data);
        }).toList();
        return right(lines);
      } catch (e) {
        return left(ServerFailure(message: 'Failed to load lyrics: $e'));
      }
    } else {
      return left(const NetworkFailure());
    }
  }

  /// Fetch vocabulary words for a rhyme
  Future<Either<Failure, List<BakhedVocabularyItem>>> getVocabulary(
    String bakhedId,
  ) async {
    if (await _networkInfo.isConnected) {
      try {
        final response = await _dbService.listDocuments(
          'bakhed_vocabulary',
          queries: [
            Query.equal('bakhedId', bakhedId),
            Query.orderAsc('sortOrder'),
            Query.limit(100),
          ],
        );
        final items = response.map((data) {
          return BakhedVocabularyItem.fromJson(data);
        }).toList();
        return right(items);
      } catch (e) {
        return left(ServerFailure(message: 'Failed to load vocabulary: $e'));
      }
    } else {
      return left(const NetworkFailure());
    }
  }

  /// Fetch cultural notes for a rhyme
  Future<Either<Failure, List<BakhedCulturalNote>>> getCulturalNotes(
    String bakhedId,
  ) async {
    if (await _networkInfo.isConnected) {
      try {
        final response = await _dbService.listDocuments(
          'bakhed_cultural_notes',
          queries: [Query.equal('bakhedId', bakhedId), Query.limit(20)],
        );
        final notes = response.map((data) {
          final map = Map<String, dynamic>.from(data);
          map['noteId'] = data['id'];
          return BakhedCulturalNote.fromJson(map);
        }).toList();
        return right(notes);
      } catch (e) {
        return left(
          ServerFailure(message: 'Failed to load cultural notes: $e'),
        );
      }
    } else {
      return left(const NetworkFailure());
    }
  }
}

// Provider
final bakhedRepositoryProvider = Provider<BakhedRepository>((ref) {
  final authService = ref.watch(appwriteAuthServiceProvider);
  final dbService = ref.watch(appwriteDbServiceProvider);
  final networkInfo = ref.watch(networkInfoProvider);
  return BakhedRepository(
    dbService: dbService,
    storage: Storage(authService.client),
    networkInfo: networkInfo,
  );
});
