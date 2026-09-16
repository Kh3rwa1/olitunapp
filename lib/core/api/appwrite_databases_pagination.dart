import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;

import 'appwrite_query_paging.dart';

/// Pagination helper for Appwrite's TablesDB row API.
///
/// Uses `TablesDB.listRows` (the `/tablesdb/.../rows` endpoints) rather than
/// the deprecated `Databases.listDocuments` API, which Appwrite deprecated in
/// 1.8.0. `total: true` must be requested explicitly — the rows endpoint does
/// not return a total by default, and without it the pagination loop below
/// would stop after a single page.
class AppwriteDatabasesPagination {
  const AppwriteDatabasesPagination._();

  static Future<T> _retryWithBackoff<T>(
    Future<T> Function() action, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
  }) async {
    int attempt = 0;
    while (true) {
      try {
        return await action();
      } catch (e) {
        attempt++;
        final isTransient =
            e is TimeoutException ||
            (e is AppwriteException &&
                (e.code == 0 ||
                    e.type == 'network_failure' ||
                    e.code == 502 ||
                    e.code == 503 ||
                    e.code == 504)) ||
            e.toString().contains('SocketException') ||
            e.toString().contains('TimeoutException') ||
            e.toString().contains('ClientException');

        if (!isTransient || attempt >= maxRetries) {
          rethrow;
        }

        final delay = initialDelay * (attempt * attempt);
        await Future.delayed(delay);
      }
    }
  }

  static Future<List<models.Row>> listRows(
    TablesDB tablesDB, {
    required String databaseId,
    required String tableId,
    List<String>? queries,
    bool paginate = true,
    int pageSize = AppwriteQueryPaging.defaultPageSize,
    Duration timeout = const Duration(seconds: 6),
  }) async {
    AppwriteQueryPaging.validatePageSize(pageSize);

    if (!paginate || AppwriteQueryPaging.containsManualPagination(queries)) {
      final result = await _retryWithBackoff(
        () => tablesDB
            .listRows(
              databaseId: databaseId,
              tableId: tableId,
              queries: AppwriteQueryPaging.queriesWithDefaultLimit(
                queries,
                pageSize,
              ),
            )
            .timeout(timeout),
      );
      return result.rows;
    }

    final baseQueries = AppwriteQueryPaging.withoutPaginationQueries(queries);
    final rows = <models.Row>[];
    var offset = 0;
    var total = 0;

    do {
      final result = await _retryWithBackoff(
        () => tablesDB
            .listRows(
              databaseId: databaseId,
              tableId: tableId,
              queries: AppwriteQueryPaging.pagedQueries(
                baseQueries,
                limit: pageSize,
                offset: offset,
              ),
              total: true,
            )
            .timeout(timeout),
      );

      total = result.total;
      rows.addAll(result.rows);

      if (result.rows.length < pageSize) break;
      offset += result.rows.length;
    } while (rows.length < total);

    return rows;
  }
}
