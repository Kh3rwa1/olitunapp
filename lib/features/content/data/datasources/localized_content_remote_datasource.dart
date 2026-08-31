import 'package:appwrite/appwrite.dart';
import 'package:itun/core/api/appwrite_databases_pagination.dart';
import 'package:itun/core/config/appwrite_config.dart';
import 'package:itun/core/error/exceptions.dart';

import '../models/localized_content_model.dart';

/// Read-only access to the `localized_contents` collection.
///
/// Learner queries must only surface approved rows; this datasource
/// returns every row and the repository filters by reviewStatus so
/// admin tooling (Phase 5) can still read drafts. Mobile clients
/// never write localizations.
abstract class LocalizedContentRemoteDataSource {
  /// All rows for [contentKind]:[contentId], any language, any status.
  Future<List<LocalizedContentModel>> getLocalizations({
    required String contentKind,
    required String contentId,
  });

  /// Rows for one item + one language, any status.
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
  static const Duration _readTimeout = Duration(seconds: 8);

  final Databases databases;

  LocalizedContentRemoteDataSourceImpl(this.databases);

  @override
  Future<List<LocalizedContentModel>> getLocalizations({
    required String contentKind,
    required String contentId,
  }) {
    return _list(
      () => [
        Query.equal('contentKind', contentKind),
        Query.equal('contentId', contentId),
        Query.limit(20),
      ],
    );
  }

  @override
  Future<List<LocalizedContentModel>> getLocalizationsForLanguage({
    required String contentKind,
    required String contentId,
    required String languageCode,
  }) {
    return _list(
      () => [
        Query.equal('contentKind', contentKind),
        Query.equal('contentId', contentId),
        Query.equal('languageCode', languageCode),
        Query.limit(5),
      ],
    );
  }

  @override
  Future<List<LocalizedContentModel>> getLocalizationsForIds({
    required String contentKind,
    required List<String> contentIds,
    required String languageCode,
  }) async {
    if (contentIds.isEmpty) return const <LocalizedContentModel>[];
    // Query.equal supports up to 100 values; chunk larger batches.
    final results = <LocalizedContentModel>[];
    for (var i = 0; i < contentIds.length; i += 100) {
      final chunk = contentIds.skip(i).take(100).toList();
      results.addAll(
        await _list(
          () => [
            Query.equal('contentKind', contentKind),
            Query.equal('contentId', chunk),
            Query.equal('languageCode', languageCode),
            Query.limit(500),
          ],
        ),
      );
    }
    return results;
  }

  Future<List<LocalizedContentModel>> _list(
    List<String> Function() queries,
  ) async {
    try {
      final documents = await AppwriteDatabasesPagination.listDocuments(
        databases,
        databaseId: AppwriteConfig.databaseId,
        collectionId: 'localized_contents',
        queries: queries(),
      ).timeout(_readTimeout);
      return documents
          .map((doc) => LocalizedContentModel.fromJson(doc.data, doc.$id))
          .toList();
    } on AppwriteException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to load localizations',
        code: e.code,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
