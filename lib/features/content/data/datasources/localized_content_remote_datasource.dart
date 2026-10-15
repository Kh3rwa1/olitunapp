import 'package:http/http.dart' as http;
import 'package:itun/core/api/edge_json_client.dart';
import 'package:itun/core/config/cloudflare_config.dart';
import 'package:itun/core/error/exceptions.dart';

import '../models/localized_content_model.dart';

/// Read-only access to learner localizations via the Cloudflare Worker
/// (`GET /api/v1/localized-contents`, backed by D1 `content_localizations`).
///
/// The Worker only returns approved rows; the repository still filters by
/// reviewStatus as a second line of defence. Mobile clients never write
/// localizations.
abstract class LocalizedContentRemoteDataSource {
  /// Approved rows for [contentKind]:[contentId], any language.
  Future<List<LocalizedContentModel>> getLocalizations({
    required String contentKind,
    required String contentId,
  });

  /// Approved rows for one item + one language.
  Future<List<LocalizedContentModel>> getLocalizationsForLanguage({
    required String contentKind,
    required String contentId,
    required String languageCode,
  });

  /// Batch read: rows for many items in one teaching language, so
  /// lesson/vocabulary screens stay at a single query per language.
  Future<List<LocalizedContentModel>> getLocalizationsForIds({
    required String contentKind,
    required List<String> contentIds,
    required String languageCode,
  });
}

class LocalizedContentRemoteDataSourceImpl
    implements LocalizedContentRemoteDataSource {
  /// The Worker accepts at most this many `contentId` values per request.
  static const int maxIdsPerRequest = 100;

  final http.Client _client;

  LocalizedContentRemoteDataSourceImpl(this._client);

  @override
  Future<List<LocalizedContentModel>> getLocalizations({
    required String contentKind,
    required String contentId,
  }) {
    return _list({
      'contentKind': contentKind,
      'contentId': [contentId],
    });
  }

  @override
  Future<List<LocalizedContentModel>> getLocalizationsForLanguage({
    required String contentKind,
    required String contentId,
    required String languageCode,
  }) {
    return _list({
      'contentKind': contentKind,
      'contentId': [contentId],
      'languageCode': languageCode,
    });
  }

  @override
  Future<List<LocalizedContentModel>> getLocalizationsForIds({
    required String contentKind,
    required List<String> contentIds,
    required String languageCode,
  }) async {
    if (contentIds.isEmpty) return const <LocalizedContentModel>[];
    final results = <LocalizedContentModel>[];
    for (var i = 0; i < contentIds.length; i += maxIdsPerRequest) {
      final chunk = contentIds.skip(i).take(maxIdsPerRequest).toList();
      results.addAll(
        await _list({
          'contentKind': contentKind,
          'contentId': chunk,
          'languageCode': languageCode,
        }),
      );
    }
    return results;
  }

  Future<List<LocalizedContentModel>> _list(Map<String, dynamic> query) async {
    try {
      final uri = Uri.parse(
        CloudflareConfig.localizedContentsEndpoint,
      ).replace(queryParameters: query);
      final rows = await EdgeJsonClient.getList(_client, uri, 'localizations');
      return rows
          .map(
            (row) => LocalizedContentModel.fromJson(row, '${row['id'] ?? ''}'),
          )
          .toList();
    } on EdgeApiException catch (e) {
      throw ServerException(
        message: 'Failed to load localizations: ${e.message}',
        code: e.statusCode,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
