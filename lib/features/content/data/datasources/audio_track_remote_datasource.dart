import 'package:http/http.dart' as http;
import 'package:itun/core/api/edge_json_client.dart';
import 'package:itun/core/config/cloudflare_config.dart';
import 'package:itun/core/error/exceptions.dart';

import '../models/audio_track_model.dart';

/// Read-only access to learner audio tracks via the Cloudflare Worker
/// (`GET /api/v1/audio-tracks`, backed by D1 `content_audio_tracks`).
///
/// Mobile clients never create, update, or delete tracks — Santali
/// audio is uploaded via the admin CMS and teaching-language audio is
/// generated server-side (Phase 4). This datasource only lists rows. The
/// Worker strips media from rows that are not yet playable.
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
  /// The Worker accepts at most this many `contentId` values per request.
  static const int maxIdsPerRequest = 100;

  final http.Client _client;

  AudioTrackRemoteDataSourceImpl(this._client);

  @override
  Future<List<AudioTrackModel>> getAllTracks({
    required String contentKind,
    required String contentId,
  }) {
    return _list({
      'contentKind': contentKind,
      'contentId': [contentId],
    });
  }

  @override
  Future<List<AudioTrackModel>> getTracksByType({
    required String contentKind,
    required String contentId,
    required String trackType,
    required String languageCode,
  }) {
    return _list({
      'contentKind': contentKind,
      'contentId': [contentId],
      'trackType': trackType,
      'languageCode': languageCode,
    });
  }

  @override
  Future<List<AudioTrackModel>> getTracksForItems({
    required String contentKind,
    required List<String> contentIds,
  }) async {
    if (contentIds.isEmpty) return const <AudioTrackModel>[];
    final results = <AudioTrackModel>[];
    for (var i = 0; i < contentIds.length; i += maxIdsPerRequest) {
      final chunk = contentIds.skip(i).take(maxIdsPerRequest).toList();
      results.addAll(
        await _list({'contentKind': contentKind, 'contentId': chunk}),
      );
    }
    return results;
  }

  Future<List<AudioTrackModel>> _list(Map<String, dynamic> query) async {
    try {
      final uri = Uri.parse(
        CloudflareConfig.audioTracksEndpoint,
      ).replace(queryParameters: query);
      final rows = await EdgeJsonClient.getList(_client, uri, 'tracks');
      return rows
          .map((row) => AudioTrackModel.fromJson(row, '${row['id'] ?? ''}'))
          .toList();
    } on EdgeApiException catch (e) {
      throw ServerException(
        message: 'Failed to load audio tracks: ${e.message}',
        code: e.statusCode,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
