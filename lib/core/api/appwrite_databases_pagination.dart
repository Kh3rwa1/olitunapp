// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;

import 'appwrite_query_paging.dart';

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
      final result = await _retryWithBackoff(
        () => databases
            .listDocuments(
              databaseId: databaseId,
              collectionId: collectionId,
              queries: AppwriteQueryPaging.queriesWithDefaultLimit(
                queries,
                pageSize,
              ),
            )
            .timeout(timeout),
      );
      return result.documents;
    }

    final baseQueries = AppwriteQueryPaging.withoutPaginationQueries(queries);
    final documents = <models.Document>[];
    var offset = 0;
    var total = 0;

    do {
      final result = await _retryWithBackoff(
        () => databases
            .listDocuments(
              databaseId: databaseId,
              collectionId: collectionId,
              queries: AppwriteQueryPaging.pagedQueries(
                baseQueries,
                limit: pageSize,
                offset: offset,
              ),
            )
            .timeout(timeout),
      );

      total = result.total;
      documents.addAll(result.documents);

      if (result.documents.length < pageSize) break;
      offset += result.documents.length;
    } while (documents.length < total);

    return documents;
  }
}
