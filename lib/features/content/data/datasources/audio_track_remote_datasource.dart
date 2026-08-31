import 'package:appwrite/appwrite.dart';
import 'package:itun/core/api/appwrite_databases_pagination.dart';
import 'package:itun/core/config/appwrite_config.dart';
import 'package:itun/core/error/exceptions.dart';

import '../models/audio_track_model.dart';

/// Read-only access to the `audio_tracks` collection.
///
/// Mobile clients never create, update, or delete tracks — Santali
/// audio is uploaded via the admin CMS and teaching-language audio is
/// generated server-side (Phase 4). This datasource only lists rows.
abstract class AudioTrackRemoteDataSource {
  /// Every track row for [contentKind]:[contentId], including
  /// unplayable ones so the UI can show "audio unavailable" states.
  Future<List<AudioTrackModel>> getAllTracks({
    required String contentKind,
    required String contentId,
  });

  /// Track rows filtered server-side by trackType and languageCode.
  Future<List<AudioTrackModel>> getTracksByType({
    required String contentKind,
    required String contentId,
    required String trackType,
    required String languageCode,
  });

  /// Every track row for many items at once (batch read so lesson and
  /// vocabulary screens stay at one query per screen).
  Future<List<AudioTrackModel>> getTracksForItems({
    required String contentKind,
    required List<String> contentIds,
  });
}

class AudioTrackRemoteDataSourceImpl implements AudioTrackRemoteDataSource {
  static const Duration _readTimeout = Duration(seconds: 8);

  final Databases databases;

  AudioTrackRemoteDataSourceImpl(this.databases);

  @override
  Future<List<AudioTrackModel>> getAllTracks({
    required String contentKind,
    required String contentId,
  }) {
    return _list(
      () => [
        Query.equal('contentKind', contentKind),
        Query.equal('contentId', contentId),
        Query.limit(500),
      ],
    );
  }

  @override
  Future<List<AudioTrackModel>> getTracksByType({
    required String contentKind,
    required String contentId,
    required String trackType,
    required String languageCode,
  }) {
    return _list(
      () => [
        Query.equal('contentKind', contentKind),
        Query.equal('contentId', contentId),
        Query.equal('trackType', trackType),
        Query.equal('languageCode', languageCode),
        Query.limit(100),
      ],
    );
  }

  @override
  Future<List<AudioTrackModel>> getTracksForItems({
    required String contentKind,
    required List<String> contentIds,
  }) async {
    if (contentIds.isEmpty) return const <AudioTrackModel>[];
    // Query.equal supports up to 100 values; chunk larger batches.
    final results = <AudioTrackModel>[];
    for (var i = 0; i < contentIds.length; i += 100) {
      final chunk = contentIds.skip(i).take(100).toList();
      results.addAll(
        await _list(
          () => [
            Query.equal('contentKind', contentKind),
            Query.equal('contentId', chunk),
            Query.limit(500),
          ],
        ),
      );
    }
    return results;
  }

  Future<List<AudioTrackModel>> _list(List<String> Function() queries) async {
    try {
      final documents = await AppwriteDatabasesPagination.listDocuments(
        databases,
        databaseId: AppwriteConfig.databaseId,
        collectionId: 'audio_tracks',
        queries: queries(),
      ).timeout(_readTimeout);
      return documents
          .map((doc) => AudioTrackModel.fromJson(doc.data, doc.$id))
          .toList();
    } on AppwriteException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to load audio tracks',
        code: e.code,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
