import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/cloudflare_config.dart';
import 'admin_content_client.dart';
import 'edge_json_client.dart';

/// Clean-architecture data representation of a row returned by [ContentRemoteDataSource].
class ContentRowData {
  final String id;
  final Map<String, dynamic> data;

  const ContentRowData({required this.id, required this.data});
}

/// Abstract contract for remote content reads and admin CRUD, all served by
/// the Cloudflare Worker (D1). Keeps transport details behind the core API
/// boundary so domain and repository layers remain backend-agnostic.
abstract class ContentRemoteDataSource {
  Future<List<ContentRowData>> listRows({
    required String tableId,
    String? categoryAttribute,
    String? categoryId,
    bool orderAsc = false,
    int limit = 500,
  });

  /// Full-body admin read (inactive and premium rows included).
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
  });

  Future<void> deleteRow({required String tableId, required String rowId});
}

/// Default implementation of [ContentRemoteDataSource]: learner reads from
/// the public Worker routes, admin reads/writes through [AdminContentClient].
class ContentRemoteDataSourceImpl implements ContentRemoteDataSource {
  static const Duration _listTimeout = Duration(seconds: 6);

  final http.Client _client;
  final AdminContentClient _admin;

  ContentRemoteDataSourceImpl({
    http.Client? httpClient,
    AdminContentClient? adminClient,
  }) : _client = httpClient ?? http.Client(),
       _admin = adminClient ?? AdminContentClient(httpClient ?? http.Client());

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
    final data = await _admin.get(tableId, rowId);
    return ContentRowData(id: data['id']?.toString() ?? rowId, data: data);
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
  }) async {
    final stored = await _admin.upsert(tableId, rowId, data);
    return ContentRowData(id: stored['id']?.toString() ?? rowId, data: stored);
  }

  @override
  Future<void> deleteRow({required String tableId, required String rowId}) =>
      _admin.delete(tableId, rowId);
}

final contentRemoteDataSourceProvider = Provider<ContentRemoteDataSource>((
  ref,
) {
  return ContentRemoteDataSourceImpl(
    httpClient: ref.watch(edgeHttpClientProvider),
    adminClient: ref.watch(adminContentClientProvider),
  );
});
