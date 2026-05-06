// ignore_for_file: deprecated_member_use

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;

import 'appwrite_query_paging.dart';

class AppwriteDatabasesPagination {
  const AppwriteDatabasesPagination._();

  static Future<List<models.Document>> listDocuments(
    Databases databases, {
    required String databaseId,
    required String collectionId,
    List<String>? queries,
    bool paginate = true,
    int pageSize = AppwriteQueryPaging.defaultPageSize,
    Duration timeout = const Duration(seconds: 6),
  }) async {
    AppwriteQueryPaging.validatePageSize(pageSize);

    if (!paginate || AppwriteQueryPaging.containsManualPagination(queries)) {
      final result = await databases
          .listDocuments(
            databaseId: databaseId,
            collectionId: collectionId,
            queries: AppwriteQueryPaging.queriesWithDefaultLimit(
              queries,
              pageSize,
            ),
          )
          .timeout(timeout);
      return result.documents;
    }

    final baseQueries = AppwriteQueryPaging.withoutPaginationQueries(queries);
    final documents = <models.Document>[];
    var offset = 0;
    var total = 0;

    do {
      final result = await databases
          .listDocuments(
            databaseId: databaseId,
            collectionId: collectionId,
            queries: AppwriteQueryPaging.pagedQueries(
              baseQueries,
              limit: pageSize,
              offset: offset,
            ),
          )
          .timeout(timeout);

      total = result.total;
      documents.addAll(result.documents);

      if (result.documents.length < pageSize) break;
      offset += result.documents.length;
    } while (documents.length < total);

    return documents;
  }
}
