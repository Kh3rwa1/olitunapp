import 'dart:async';
import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../api/appwrite_databases_pagination.dart';
import '../auth/appwrite_auth_service.dart';
import '../config/appwrite_config.dart';
import '../config/cloudflare_config.dart';

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

/// Default implementation of [ContentRemoteDataSource] backed by Cloudflare Edge API and Appwrite [TablesDB].
class ContentRemoteDataSourceImpl implements ContentRemoteDataSource {
  final TablesDB _tablesDB;
  final http.Client? _httpClient;

  ContentRemoteDataSourceImpl({
    required TablesDB tablesDB,
    http.Client? httpClient,
  }) : _tablesDB = tablesDB,
       _httpClient = httpClient;

  http.Client get _client => _httpClient ?? http.Client();

  String? _cloudflareEndpointFor(String tableId, {String? categoryId}) {
    final queryParam = (categoryId != null && categoryId.isNotEmpty)
        ? '?category=${Uri.encodeComponent(categoryId)}'
        : '';
    switch (tableId.toLowerCase()) {
      case 'categories':
        return CloudflareConfig.categoriesEndpoint;
      case 'words':
      case 'word':
        return '${CloudflareConfig.wordsEndpoint}$queryParam';
      case 'letters':
      case 'letter':
        return CloudflareConfig.lettersEndpoint;
      case 'numbers':
      case 'number':
        return CloudflareConfig.numbersEndpoint;
      case 'sentences':
      case 'sentence':
        return '${CloudflareConfig.sentencesEndpoint}$queryParam';
      case 'lessons':
      case 'lesson':
        return '${CloudflareConfig.lessonsEndpoint}$queryParam';
      default:
        return null;
    }
  }

  String _keyForTable(String tableId) {
    switch (tableId.toLowerCase()) {
      case 'categories':
        return 'categories';
      case 'words':
      case 'word':
        return 'words';
      case 'letters':
      case 'letter':
        return 'letters';
      case 'numbers':
      case 'number':
        return 'numbers';
      case 'sentences':
      case 'sentence':
        return 'sentences';
      case 'lessons':
      case 'lesson':
        return 'lessons';
      default:
        return tableId;
    }
  }

  List<String> _readPermissions(bool allowAnonymousRead) => allowAnonymousRead
      ? [
          Permission.read(Role.any()),
          Permission.read(Role.team(AppwriteConfig.adminTeamId)),
          Permission.update(Role.team(AppwriteConfig.adminTeamId)),
          Permission.delete(Role.team(AppwriteConfig.adminTeamId)),
        ]
      : const [];

  @override
  Future<List<ContentRowData>> listRows({
    required String tableId,
    String? categoryAttribute,
    String? categoryId,
    bool orderAsc = false,
    int limit = 500,
  }) async {
    // 1. Try Cloudflare Edge API first (Sub-20ms global edge cache, zero Appwrite reads)
    try {
      final endpoint = _cloudflareEndpointFor(tableId, categoryId: categoryId);
      if (endpoint != null) {
        final uri = Uri.parse(endpoint);
        final res = await _client.get(uri).timeout(const Duration(seconds: 6));
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          if (body is Map && body['ok'] == true) {
            final key = _keyForTable(tableId);
            final items = body[key];
            if (items is List && items.isNotEmpty) {
              return items
                  .map(
                    (it) => ContentRowData(
                      id: (it as Map)['id']?.toString() ?? '',
                      data: Map<String, dynamic>.from(it),
                    ),
                  )
                  .toList();
            }
          }
        }
      }
    } catch (_) {
      // Fall through to Appwrite on failure
    }

    // 2. Fallback to Appwrite TablesDB
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
    // 1. Try Cloudflare Edge API first
    try {
      final uri = Uri.parse(
        '${CloudflareConfig.categoriesEndpoint}/$categoryId',
      );
      final res = await _client.get(uri).timeout(timeout);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map && body['ok'] == true && body['category'] is Map) {
          return Map<String, dynamic>.from(body['category'] as Map);
        }
      }
    } catch (_) {
      // Fall through to Appwrite
    }

    // 2. Fallback to Appwrite TablesDB
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
