import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../api/edge_json_client.dart';
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

  /// One learner-visible row from the Cloudflare Worker.
  Future<ContentRowData> getPublicRow({
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
  static const Duration _listTimeout = Duration(seconds: 6);

  final TablesDB _tablesDB;
  final http.Client _client;

  /// Learner reads ([listRows], [getCategory]) come only from the Cloudflare
  /// Worker; [tablesDB] backs the admin CMS row reads and writes.
  ContentRemoteDataSourceImpl({
    required TablesDB tablesDB,
    http.Client? httpClient,
  }) : _tablesDB = tablesDB,
       _client = httpClient ?? http.Client();

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
      case 'rhymes':
      case 'rhyme':
        return '${CloudflareConfig.rhymesEndpoint}$queryParam';
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
      case 'rhymes':
      case 'rhyme':
        return 'rhymes';
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
    final endpoint = _cloudflareEndpointFor(tableId, categoryId: categoryId);
    if (endpoint == null) {
      throw UnsupportedError('No Cloudflare Worker route for "$tableId"');
    }
    // The Worker returns rows already filtered and ordered; an empty list is
    // a valid result.
    final items = await EdgeJsonClient.getList(
      _client,
      Uri.parse(endpoint),
      _keyForTable(tableId),
      timeout: _listTimeout,
    );
    return items
        .map((it) => ContentRowData(id: it['id']?.toString() ?? '', data: it))
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
  Future<ContentRowData> getPublicRow({
    required String tableId,
    required String rowId,
  }) async {
    final kind = _publicKinds[tableId];
    if (kind == null) {
      throw UnsupportedError('No Cloudflare Worker route for "$tableId"');
    }
    final body = await EdgeJsonClient.getJson(
      _client,
      Uri.parse(
        '${CloudflareConfig.baseUrl}/api/v1/content/$kind/'
        '${Uri.encodeComponent(rowId)}',
      ),
      timeout: _listTimeout,
    );
    final item = body['item'];
    if (item is! Map) throw const FormatException('Missing content item');
    final data = Map<String, dynamic>.from(item);
    return ContentRowData(id: data['id']?.toString() ?? rowId, data: data);
  }

  static const _publicKinds = {
    'letters': 'letter',
    'numbers': 'number',
    'words': 'word',
    'sentences': 'sentence',
    'rhymes': 'rhyme',
    'categories': 'category',
  };

  @override
  Future<Map<String, dynamic>> getCategory({
    required String categoryId,
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final body = await EdgeJsonClient.getJson(
      _client,
      Uri.parse(
        '${CloudflareConfig.categoriesEndpoint}/'
        '${Uri.encodeComponent(categoryId)}',
      ),
      timeout: timeout,
    );
    final category = body['category'];
    if (category is! Map) {
      throw const EdgeApiException('Missing category in response');
    }
    return Map<String, dynamic>.from(category);
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
  return ContentRemoteDataSourceImpl(
    tablesDB: TablesDB(authService.client),
    httpClient: ref.watch(edgeHttpClientProvider),
  );
});
