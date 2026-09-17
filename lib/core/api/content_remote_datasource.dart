import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/appwrite_databases_pagination.dart';
import '../auth/appwrite_auth_service.dart';
import '../config/appwrite_config.dart';

/// Clean-architecture data representation of a row returned by [ContentRemoteDataSource].
class ContentRowData {
  final String id;
  final Map<String, dynamic> data;

  const ContentRowData({required this.id, required this.data});
}

/// Abstract contract for remote content CRUD operations against Appwrite TablesDB.
///
/// Keeps `package:appwrite` behind the core API boundary so domain and repository
/// layers remain backend-agnostic.
abstract class ContentRemoteDataSource {
  Future<List<ContentRowData>> listRows({
    required String tableId,
    String? categoryAttribute,
    String? categoryId,
    bool orderAsc = false,
    int limit = 500,
  });

  Future<ContentRowData> getRow({
    required String tableId,
    required String rowId,
  });

  Future<Map<String, dynamic>> getCategory({
    required String categoryId,
    Duration timeout = const Duration(seconds: 6),
  });

  Future<ContentRowData> upsertRow({
    required String tableId,
    required String rowId,
    required Map<String, dynamic> data,
    required bool allowAnonymousRead,
  });

  Future<void> deleteRow({required String tableId, required String rowId});
}

/// Default implementation of [ContentRemoteDataSource] backed by Appwrite [TablesDB].
class ContentRemoteDataSourceImpl implements ContentRemoteDataSource {
  final TablesDB _tablesDB;

  ContentRemoteDataSourceImpl({required TablesDB tablesDB})
    : _tablesDB = tablesDB;

  List<String> _readPermissions(bool allowAnonymousRead) =>
      allowAnonymousRead ? [Permission.read(Role.any())] : const [];

  @override
  Future<List<ContentRowData>> listRows({
    required String tableId,
    String? categoryAttribute,
    String? categoryId,
    bool orderAsc = false,
    int limit = 500,
  }) async {
    final List<String> queries = [
      if (categoryAttribute != null &&
          categoryId != null &&
          categoryId.isNotEmpty)
        Query.equal(categoryAttribute, categoryId),
      if (orderAsc) Query.orderAsc('order'),
      Query.limit(limit),
    ];

    final response = await AppwriteDatabasesPagination.listRows(
      _tablesDB,
      databaseId: AppwriteConfig.databaseId,
      tableId: tableId,
      queries: queries,
    );

    return response
        .map((row) => ContentRowData(id: row.$id, data: row.data))
        .toList();
  }

  @override
  Future<ContentRowData> getRow({
    required String tableId,
    required String rowId,
  }) async {
    final row = await _tablesDB.getRow(
      databaseId: AppwriteConfig.databaseId,
      tableId: tableId,
      rowId: rowId,
    );
    return ContentRowData(id: row.$id, data: row.data);
  }

  @override
  Future<Map<String, dynamic>> getCategory({
    required String categoryId,
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final category = await _tablesDB
        .getRow(
          databaseId: AppwriteConfig.databaseId,
          tableId: 'categories',
          rowId: categoryId,
        )
        .timeout(timeout);
    return category.data;
  }

  @override
  Future<ContentRowData> upsertRow({
    required String tableId,
    required String rowId,
    required Map<String, dynamic> data,
    required bool allowAnonymousRead,
  }) async {
    final permissions = _readPermissions(allowAnonymousRead);
    try {
      final row = await _tablesDB.createRow(
        databaseId: AppwriteConfig.databaseId,
        tableId: tableId,
        rowId: rowId,
        data: data,
        permissions: permissions,
      );
      return ContentRowData(id: row.$id, data: row.data);
    } on AppwriteException catch (ae) {
      if (ae.code == 409) {
        final row = await _tablesDB.updateRow(
          databaseId: AppwriteConfig.databaseId,
          tableId: tableId,
          rowId: rowId,
          data: data,
          permissions: permissions,
        );
        return ContentRowData(id: row.$id, data: row.data);
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteRow({
    required String tableId,
    required String rowId,
  }) async {
    await _tablesDB.deleteRow(
      databaseId: AppwriteConfig.databaseId,
      tableId: tableId,
      rowId: rowId,
    );
  }
}

/// Helper factory enabling backward compatibility with legacy tests passing `tablesDB`.
class ContentRemoteDataSourceFactory {
  static ContentRemoteDataSource? fromDynamic(dynamic tablesDB) {
    if (tablesDB == null) return null;
    if (tablesDB is TablesDB) {
      return ContentRemoteDataSourceImpl(tablesDB: tablesDB);
    }
    return null;
  }
}

final contentRemoteDataSourceProvider = Provider<ContentRemoteDataSource>((
  ref,
) {
  final authService = ref.watch(appwriteAuthServiceProvider);
  return ContentRemoteDataSourceImpl(tablesDB: TablesDB(authService.client));
});
