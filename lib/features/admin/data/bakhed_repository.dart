import 'package:appwrite/appwrite.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/core/auth/appwrite_auth_service.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/core/logging/app_logger.dart';
import 'package:itun/core/network/network_info.dart';
import 'package:itun/features/admin/data/gamification_cms_api.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/shared/providers/bakhed_content_provider.dart';

/// Bakhed (rhyme) admin data on the Cloudflare Worker: parents live in the D1
/// `rhymes` table, lyrics / vocabulary / cultural notes in D1 `cms_rows`.

class BakhedRepository {
  final GamificationCmsApi _api;
  final Storage _storage;
  final NetworkInfo _networkInfo;

  BakhedRepository({
    required GamificationCmsApi api,
    required Storage storage,
    required NetworkInfo networkInfo,
  }) : _api = api,
       _storage = storage,
       _networkInfo = networkInfo;

  /// List all rhymes/stories (Bakhed parents).
  Future<Either<Failure, List<ContentItem>>> list() async {
    if (!await _networkInfo.isConnected) return left(const NetworkFailure());
    try {
      final response = await _api.listBakhed();
      final items = response.map((data) {
        final id = data['id'] as String;
        return ContentItem.fromJson(data, id, ContentKind.rhyme);
      }).toList();
      return right(items);
    } catch (e) {
      return left(ServerFailure(message: 'Failed to list rhymes: $e'));
    }
  }

  /// Get a single rhyme by its id. A missing Bakhed is a [ServerFailure]
  /// with code 404 (the editor treats it as a new draft).
  Future<Either<Failure, ContentItem>> get(String id) async {
    if (!await _networkInfo.isConnected) return left(const NetworkFailure());
    try {
      final data = await _api.getBakhed(id);
      return right(ContentItem.fromJson(data, id, ContentKind.rhyme));
    } on CmsApiException catch (e) {
      return left(
        ServerFailure(
          message: 'Failed to fetch rhyme $id: ${e.message}',
          code: e.statusCode,
        ),
      );
    } catch (e) {
      return left(ServerFailure(message: 'Failed to fetch rhyme $id: $e'));
    }
  }

  /// Upsert (create or update) a rhyme/story metadata document. The
  /// item's [ContentItem.updatedAt] is stored as the concurrency token.
  Future<Either<Failure, Unit>> upsert(ContentItem item) async {
    if (!await _networkInfo.isConnected) return left(const NetworkFailure());
    try {
      await _api.upsertBakhed(item.id, {
        ...item.toAppwriteAttributes(),
        'updatedAt': item.updatedAt.toUtc().toIso8601String(),
      });
      return right(unit);
    } catch (e) {
      return left(ServerFailure(message: 'Failed to save rhyme metadata: $e'));
    }
  }

  /// Cascade delete a rhyme: the Worker removes its lyrics, vocabulary and
  /// cultural notes together with the parent in one D1 batch. The play-along
  /// audio file is then removed best-effort.
  Future<Either<Failure, Unit>> delete(String id) async {
    if (!await _networkInfo.isConnected) return left(const NetworkFailure());
    final Map<String, dynamic> result;
    try {
      result = await _api.deleteBakhed(id);
    } catch (e) {
      return left(ServerFailure(message: 'Cascade delete failed: $e'));
    }

    final audioFileId = result['audioFileId']?.toString() ?? '';
    if (audioFileId.isNotEmpty) {
      try {
        await _storage.deleteFile(bucketId: 'audio', fileId: audioFileId);
      } catch (e, stack) {
        // The DB cascade already succeeded; a leftover file is only storage.
        AppLogger.warning(
          'BakhedRepository: audio delete failed',
          name: 'BakhedRepository',
          error: e,
          stackTrace: stack,
        );
      }
    }
    return right(unit);
  }

  /// Fetch lyrics lines for a rhyme, ordered by line index.
  Future<Either<Failure, List<BakhedLyricLine>>> getLyrics(
    String bakhedId,
  ) async {
    if (!await _networkInfo.isConnected) return left(const NetworkFailure());
    try {
      final rows = await _api.listRows('bakhed_lyrics', bakhedId: bakhedId);
      final lines = rows.map(BakhedLyricLine.fromJson).toList()
        ..sort((a, b) => a.lineIndex.compareTo(b.lineIndex));
      return right(lines);
    } catch (e) {
      return left(ServerFailure(message: 'Failed to load lyrics: $e'));
    }
  }

  /// Fetch vocabulary words for a rhyme, ordered by sort order.
  Future<Either<Failure, List<BakhedVocabularyItem>>> getVocabulary(
    String bakhedId,
  ) async {
    if (!await _networkInfo.isConnected) return left(const NetworkFailure());
    try {
      final rows = await _api.listRows('bakhed_vocabulary', bakhedId: bakhedId);
      final items = rows.map(BakhedVocabularyItem.fromJson).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return right(items);
    } catch (e) {
      return left(ServerFailure(message: 'Failed to load vocabulary: $e'));
    }
  }

  /// Fetch cultural notes for a rhyme.
  Future<Either<Failure, List<BakhedCulturalNote>>> getCulturalNotes(
    String bakhedId,
  ) async {
    if (!await _networkInfo.isConnected) return left(const NetworkFailure());
    try {
      final rows = await _api.listRows(
        'bakhed_cultural_notes',
        bakhedId: bakhedId,
      );
      final notes = rows.map((data) {
        return BakhedCulturalNote.fromJson({...data, 'noteId': data['id']});
      }).toList();
      return right(notes);
    } catch (e) {
      return left(ServerFailure(message: 'Failed to load cultural notes: $e'));
    }
  }
}

// Provider
final bakhedRepositoryProvider = Provider<BakhedRepository>((ref) {
  final authService = ref.watch(appwriteAuthServiceProvider);
  final networkInfo = ref.watch(networkInfoProvider);
  return BakhedRepository(
    api: ref.watch(gamificationCmsApiProvider),
    // Appwrite Storage only for removing the legacy play-along audio file.
    storage: Storage(authService.client),
    networkInfo: networkInfo,
  );
});
