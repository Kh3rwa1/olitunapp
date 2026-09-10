import 'dart:async';
import 'dart:math';

import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/appwrite_auth_service.dart';
import '../config/appwrite_config.dart';
import '../observability/crash_reporting.dart';
import 'appwrite_query_paging.dart';

class AppwriteDbService {
  static const Duration _readTimeout = Duration(seconds: 3);
  static const Duration _writeTimeout = Duration(seconds: 15);

  final TablesDB _tablesDB;
  final Storage storage;
  final Client _client;
  final bool _backendConfigured;

  AppwriteDbService(this._client, {bool? backendConfigured})
    : _backendConfigured =
          backendConfigured ?? AppwriteConfig.isBackendConfigured,
      _tablesDB = TablesDB(_client),
      storage = Storage(_client);

  void _ensureBackendConfigured() {
    if (_backendConfigured) return;
    throw StateError(
      'Appwrite backend is not configured. Provide APPWRITE_ENDPOINT and '
      'APPWRITE_PROJECT_ID before making remote requests.',
    );
  }

  // Link-state APIs report whether a network interface exists, not whether the
  // backend is reachable. Requests therefore execute directly and their real
  // timeout/SDK errors drive retry and offline-fallback behavior.
  Future<T> _retryWithBackoff<T>(
    Future<T> Function() action, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
  }) async {
    var attempt = 0;
    while (true) {
      try {
        return await action();
      } catch (error) {
        attempt++;
        final isTransient =
            error is TimeoutException ||
            (error is AppwriteException &&
                (error.code == 0 ||
                    error.type == 'network_failure' ||
                    error.code == 502 ||
                    error.code == 503 ||
                    error.code == 504)) ||
            error.toString().contains('SocketException') ||
            error.toString().contains('TimeoutException') ||
            error.toString().contains('ClientException');

        if (!isTransient || attempt >= maxRetries) rethrow;

        final exponentialFactor = 1 << (attempt - 1);
        final jitter = Random().nextDouble() * 0.2 + 0.9;
        final delayMs =
            (initialDelay.inMilliseconds * exponentialFactor * jitter).round();
        await Future<void>.delayed(Duration(milliseconds: delayMs));
      }
    }
  }

  /// Lists rows with optional queries.
  ///
  /// By default this fetches every matching page, preventing larger content
  /// collections from being silently truncated at Appwrite's page limit. Pass
  /// [paginate] as false for intentionally capped reads.
  Future<List<Map<String, dynamic>>> listDocuments(
    String collectionId, {
    List<String>? queries,
    bool paginate = true,
    int pageSize = AppwriteQueryPaging.defaultPageSize,
  }) async {
    AppwriteQueryPaging.validatePageSize(pageSize);
    _ensureBackendConfigured();

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
      final result = await _retryWithBackoff(
        () => _tablesDB
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
            .timeout(_readTimeout),
      );

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
    final result = await _retryWithBackoff(
      () => _tablesDB
          .listRows(
            databaseId: AppwriteConfig.databaseId,
            tableId: collectionId,
            queries: queries,
          )
          .timeout(_readTimeout),
    );
    return result.rows.map(_rowToMap).toList();
  }

  static Map<String, dynamic> _rowToMap(dynamic row) {
    final data = Map<String, dynamic>.from(row.data);
    data['id'] = row.$id;
    data[r'$createdAt'] = row.$createdAt;
    data[r'$updatedAt'] = row.$updatedAt;
    return data;
  }

  Future<Map<String, dynamic>> getDocument(
    String collectionId,
    String documentId,
  ) async {
    _ensureBackendConfigured();
    final row = await _retryWithBackoff(
      () => _tablesDB
          .getRow(
            databaseId: AppwriteConfig.databaseId,
            tableId: collectionId,
            rowId: documentId,
          )
          .timeout(_readTimeout),
    );
    final data = Map<String, dynamic>.from(row.data);
    data['id'] = row.$id;
    return data;
  }

  /// Creates a row with explicit permissions. When [permissions] is null,
  /// collection-level defaults apply.
  Future<void> createDocument(
    String collectionId,
    String documentId,
    Map<String, dynamic> data, {
    List<String>? permissions,
  }) async {
    _ensureBackendConfigured();
    final payload = Map<String, dynamic>.from(data)..remove('id');
    payload.removeWhere((key, value) => value == null);

    try {
      await _tablesDB
          .createRow(
            databaseId: AppwriteConfig.databaseId,
            tableId: collectionId,
            rowId: documentId,
            data: payload,
            permissions: permissions,
          )
          .timeout(_writeTimeout);
      CrashReporting.addAppwriteBreadcrumb(
        operation: 'create',
        collection: collectionId,
        documentId: documentId,
      );
    } catch (error) {
      CrashReporting.addAppwriteBreadcrumb(
        operation: 'create',
        collection: collectionId,
        documentId: documentId,
        success: false,
        error: error.toString(),
      );
      rethrow;
    }
  }

  Future<void> createPublicContent(
    String collectionId,
    String documentId,
    Map<String, dynamic> data,
  ) => createDocument(
    collectionId,
    documentId,
    data,
    permissions: [Permission.read(Role.any())],
  );

  Future<void> createOwnerPrivateRow(
    String collectionId,
    String documentId,
    Map<String, dynamic> data,
    String userId,
  ) => createDocument(
    collectionId,
    documentId,
    data,
    permissions: [
      Permission.read(Role.user(userId)),
      Permission.write(Role.user(userId)),
    ],
  );

  static List<String> adminOnlyPermissions() => [
    Permission.read(Role.team(AppwriteConfig.adminTeamId)),
    Permission.write(Role.team(AppwriteConfig.adminTeamId)),
  ];

  Future<void> createAdminOnlyRow(
    String collectionId,
    String documentId,
    Map<String, dynamic> data,
  ) => createDocument(
    collectionId,
    documentId,
    data,
    permissions: adminOnlyPermissions(),
  );

  Future<void> createFunctionManagedRow(
    String collectionId,
    String documentId,
    Map<String, dynamic> data,
  ) => createDocument(collectionId, documentId, data, permissions: const []);

  /// Updates row data. When [permissions] is null, existing permissions are
  /// preserved by Appwrite.
  Future<void> updateDocument(
    String collectionId,
    String documentId,
    Map<String, dynamic> data, {
    List<String>? permissions,
  }) async {
    _ensureBackendConfigured();
    final payload = Map<String, dynamic>.from(data)..remove('id');
    payload.removeWhere((key, value) => value == null);

    try {
      await _tablesDB
          .updateRow(
            databaseId: AppwriteConfig.databaseId,
            tableId: collectionId,
            rowId: documentId,
            data: payload,
            permissions: permissions,
          )
          .timeout(_writeTimeout);
      CrashReporting.addAppwriteBreadcrumb(
        operation: 'update',
        collection: collectionId,
        documentId: documentId,
      );
    } catch (error) {
      CrashReporting.addAppwriteBreadcrumb(
        operation: 'update',
        collection: collectionId,
        documentId: documentId,
        success: false,
        error: error.toString(),
      );
      rethrow;
    }
  }

  Future<void> updateDataPreservingPermissions(
    String collectionId,
    String documentId,
    Map<String, dynamic> data,
  ) => updateDocument(collectionId, documentId, data);

  Future<void> updatePermissionsExplicitly(
    String collectionId,
    String documentId,
    List<String> permissions,
  ) => updateDocument(collectionId, documentId, {}, permissions: permissions);

  Future<void> deleteDocument(String collectionId, String documentId) async {
    _ensureBackendConfigured();
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
    } catch (error) {
      CrashReporting.addAppwriteBreadcrumb(
        operation: 'delete',
        collection: collectionId,
        documentId: documentId,
        success: false,
        error: error.toString(),
      );
      rethrow;
    }
  }

  String getFileViewUrl(String bucketId, String fileId) {
    final endpoint = _client.endPoint;
    return '$endpoint/storage/buckets/$bucketId/files/$fileId/view?project=${AppwriteConfig.projectId}';
  }

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

final appwriteDbServiceProvider = Provider<AppwriteDbService>((ref) {
  final authService = ref.watch(appwriteAuthServiceProvider);
  return AppwriteDbService(authService.client);
});
