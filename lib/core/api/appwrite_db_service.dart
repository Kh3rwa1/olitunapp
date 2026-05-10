import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/appwrite_config.dart';
import '../auth/appwrite_auth_service.dart';
import '../observability/crash_reporting.dart';
import 'appwrite_query_paging.dart';

class AppwriteDbService {
  static const Duration _readTimeout = Duration(seconds: 6);
  static const Duration _writeTimeout = Duration(seconds: 15);

  final TablesDB _tablesDB;
  final Storage storage;
  final Client _client;

  AppwriteDbService(this._client)
    : _tablesDB = TablesDB(_client),
      storage = Storage(_client);

  // ─── Generic CRUD ───

  /// List rows with optional queries.
  ///
  /// By default this fetches every matching page, preventing larger content
  /// collections from being silently truncated at Appwrite's page limit. Pass
  /// [paginate] as false for intentionally capped reads such as dashboard
  /// widgets or previews.
  Future<List<Map<String, dynamic>>> listDocuments(
    String collectionId, {
    List<String>? queries,
    bool paginate = true,
    int pageSize = AppwriteQueryPaging.defaultPageSize,
  }) async {
    AppwriteQueryPaging.validatePageSize(pageSize);

    if (!paginate || AppwriteQueryPaging.containsManualPagination(queries)) {
      return _listSinglePage(
        collectionId,
        queries: AppwriteQueryPaging.queriesWithDefaultLimit(queries, pageSize),
      );
    }

    final baseQueries = AppwriteQueryPaging.withoutPaginationQueries(queries);
    final rows = <Map<String, dynamic>>[];
    var offset = 0;
    var total = 0;

    do {
      final result = await _tablesDB
          .listRows(
            databaseId: AppwriteConfig.databaseId,
            tableId: collectionId,
            queries: AppwriteQueryPaging.pagedQueries(
              baseQueries,
              limit: pageSize,
              offset: offset,
            ),
            total: true,
          )
          .timeout(_readTimeout);

      total = result.total;
      rows.addAll(result.rows.map(_rowToMap));

      if (result.rows.length < pageSize) break;
      offset += result.rows.length;
    } while (rows.length < total);

    return rows;
  }

  Future<List<Map<String, dynamic>>> _listSinglePage(
    String collectionId, {
    required List<String> queries,
  }) async {
    final result = await _tablesDB
        .listRows(
          databaseId: AppwriteConfig.databaseId,
          tableId: collectionId,
          queries: queries,
        )
        .timeout(_readTimeout);
    return result.rows.map(_rowToMap).toList();
  }

  static Map<String, dynamic> _rowToMap(row) {
    final data = Map<String, dynamic>.from(row.data);
    data['id'] = row.$id;
    // Preserve Appwrite system timestamps for downstream consumers
    // (e.g. admin dashboard activity feed / engagement chart).
    data[r'$createdAt'] = row.$createdAt;
    data[r'$updatedAt'] = row.$updatedAt;
    return data;
  }

  /// Get a single document by ID
  Future<Map<String, dynamic>> getDocument(
    String collectionId,
    String documentId,
  ) async {
    final row = await _tablesDB
        .getRow(
          databaseId: AppwriteConfig.databaseId,
          tableId: collectionId,
          rowId: documentId,
        )
        .timeout(_readTimeout);
    final data = Map<String, dynamic>.from(row.data);
    data['id'] = row.$id;
    return data;
  }

  /// Create a document
  Future<void> createDocument(
    String collectionId,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    // Remove 'id' from data payload — Appwrite uses documentId separately
    final payload = Map<String, dynamic>.from(data)..remove('id');
    // Remove null values
    payload.removeWhere((key, value) => value == null);

    try {
      await _tablesDB
          .createRow(
            databaseId: AppwriteConfig.databaseId,
            tableId: collectionId,
            rowId: documentId,
            data: payload,
          )
          .timeout(_writeTimeout);
      CrashReporting.addAppwriteBreadcrumb(
        operation: 'create',
        collection: collectionId,
        documentId: documentId,
      );
    } catch (e) {
      CrashReporting.addAppwriteBreadcrumb(
        operation: 'create',
        collection: collectionId,
        documentId: documentId,
        success: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Update a document
  Future<void> updateDocument(
    String collectionId,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    final payload = Map<String, dynamic>.from(data)..remove('id');
    payload.removeWhere((key, value) => value == null);

    try {
      await _tablesDB
          .updateRow(
            databaseId: AppwriteConfig.databaseId,
            tableId: collectionId,
            rowId: documentId,
            data: payload,
          )
          .timeout(_writeTimeout);
      CrashReporting.addAppwriteBreadcrumb(
        operation: 'update',
        collection: collectionId,
        documentId: documentId,
      );
    } catch (e) {
      CrashReporting.addAppwriteBreadcrumb(
        operation: 'update',
        collection: collectionId,
        documentId: documentId,
        success: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Delete a document
  Future<void> deleteDocument(String collectionId, String documentId) async {
    try {
      await _tablesDB
          .deleteRow(
            databaseId: AppwriteConfig.databaseId,
            tableId: collectionId,
            rowId: documentId,
          )
          .timeout(_writeTimeout);
      CrashReporting.addAppwriteBreadcrumb(
        operation: 'delete',
        collection: collectionId,
        documentId: documentId,
      );
    } catch (e) {
      CrashReporting.addAppwriteBreadcrumb(
        operation: 'delete',
        collection: collectionId,
        documentId: documentId,
        success: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // ─── Storage Helpers ───

  /// Get file view URL (publicly accessible)
  String getFileViewUrl(String bucketId, String fileId) {
    final endpoint = _client.endPoint;
    return '$endpoint/storage/buckets/$bucketId/files/$fileId/view?project=${AppwriteConfig.projectId}';
  }

  /// Get file preview URL (for images with transformations)
  String getFilePreviewUrl(
    String bucketId,
    String fileId, {
    int? width,
    int? height,
  }) {
    final endpoint = _client.endPoint;
    var url =
        '$endpoint/storage/buckets/$bucketId/files/$fileId/preview?project=${AppwriteConfig.projectId}';
    if (width != null) url += '&width=$width';
    if (height != null) url += '&height=$height';
    return url;
  }
}

// Provider
final appwriteDbServiceProvider = Provider<AppwriteDbService>((ref) {
  final authService = ref.watch(appwriteAuthServiceProvider);
  return AppwriteDbService(authService.client);
});
