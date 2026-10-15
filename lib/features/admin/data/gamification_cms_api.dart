import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:itun/core/api/edge_json_client.dart';
import 'package:itun/core/auth/edge_auth.dart';
import 'package:itun/core/config/cloudflare_config.dart';

/// Raised when a CMS request fails. [message] is safe to show to admins
/// (it carries the Worker's validation errors when there are any).
class CmsApiException implements Exception {
  final String message;
  final int? statusCode;

  const CmsApiException(this.message, {this.statusCode});

  bool get isNotFound => statusCode == 404;

  @override
  String toString() => message;
}

/// Admin client for the gamification + Bakhed CMS on the Cloudflare Worker
/// (D1 `cms_rows` and the Bakhed parents in `rhymes`). Admin-team membership
/// is enforced by the Worker from the session JWT.
class GamificationCmsApi {
  GamificationCmsApi({http.Client? httpClient, EdgeAuth? edgeAuth})
    : _http = httpClient ?? http.Client(),
      _edgeAuth = edgeAuth ?? EdgeAuth.instance;

  static const Duration _timeout = Duration(seconds: 15);

  final http.Client _http;
  final EdgeAuth _edgeAuth;

  /// Rows of [collection], in display order. Bakhed child collections can be
  /// scoped to one Bakhed with [bakhedId].
  Future<List<Map<String, dynamic>>> listRows(
    String collection, {
    String? bakhedId,
  }) async {
    final uri =
        Uri.parse(
          '${CloudflareConfig.adminCmsRowsEndpoint}/'
          '${Uri.encodeComponent(collection)}',
        ).replace(
          queryParameters: bakhedId == null || bakhedId.isEmpty
              ? null
              : {'bakhedId': bakhedId},
        );
    final body = await _send('GET', uri);
    return _maps(body['rows']);
  }

  /// Creates or updates one row. Fields absent from [data] keep their stored
  /// value. With [createOnly] the Worker refuses to overwrite an existing row.
  Future<Map<String, dynamic>> upsertRow(
    String collection,
    String id,
    Map<String, dynamic> data, {
    bool createOnly = false,
  }) async {
    final body = await _send(
      'PUT',
      _rowUri(collection, id),
      body: {'data': data, if (createOnly) 'createOnly': true},
    );
    final row = body['row'];
    return row is Map ? Map<String, dynamic>.from(row) : <String, dynamic>{};
  }

  Future<void> deleteRow(String collection, String id) async {
    await _send('DELETE', _rowUri(collection, id));
  }

  /// Every Bakhed (rhyme) document.
  Future<List<Map<String, dynamic>>> listBakhed() async {
    final body = await _send(
      'GET',
      Uri.parse(CloudflareConfig.adminCmsBakhedEndpoint),
    );
    return _maps(body['items']);
  }

  /// One Bakhed document; throws [CmsApiException] with status 404 when the
  /// Bakhed does not exist yet.
  Future<Map<String, dynamic>> getBakhed(String id) async {
    final body = await _send('GET', _bakhedUri(id));
    final item = body['item'];
    if (item is! Map) {
      throw const CmsApiException('Malformed Bakhed response');
    }
    return Map<String, dynamic>.from(item);
  }

  Future<void> upsertBakhed(String id, Map<String, dynamic> data) async {
    await _send('PUT', _bakhedUri(id), body: {'data': data});
  }

  /// Deletes the Bakhed and, in the same D1 batch, its lyrics, vocabulary and
  /// cultural notes. Returns the Worker summary (`deleted` counts and the
  /// parent's `audioFileId`).
  Future<Map<String, dynamic>> deleteBakhed(String id) =>
      _send('DELETE', _bakhedUri(id));

  Uri _rowUri(String collection, String id) => Uri.parse(
    '${CloudflareConfig.adminCmsRowsEndpoint}/'
    '${Uri.encodeComponent(collection)}/${Uri.encodeComponent(id)}',
  );

  Uri _bakhedUri(String id) => Uri.parse(
    '${CloudflareConfig.adminCmsBakhedEndpoint}/${Uri.encodeComponent(id)}',
  );

  Future<Map<String, dynamic>> _send(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    final request = http.Request(method, uri)
      ..headers.addAll({
        'Accept': 'application/json',
        if (body != null) 'Content-Type': 'application/json',
        ...await _edgeAuth.headers(),
      });
    if (body != null) request.body = jsonEncode(body);

    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _http.send(request).timeout(_timeout),
      );
    } on TimeoutException {
      throw CmsApiException('Request to ${uri.path} timed out');
    } catch (e) {
      throw CmsApiException('Request to ${uri.path} failed: $e');
    }

    if (response.statusCode == 401) _edgeAuth.clear();
    final decoded = _decode(response.body);
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        decoded?['ok'] != true) {
      final errors = decoded?['errors'];
      final detail = errors is List && errors.isNotEmpty
          ? ' ${errors.join(' ')}'
          : '';
      throw CmsApiException(
        '${decoded?['message'] ?? 'CMS request failed'} '
                '(${response.statusCode}).$detail'
            .trim(),
        statusCode: response.statusCode,
      );
    }
    return decoded!;
  }

  static Map<String, dynamic>? _decode(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  static List<Map<String, dynamic>> _maps(Object? raw) {
    if (raw is! List) {
      throw const CmsApiException('Malformed CMS list response');
    }
    return raw
        .whereType<Map>()
        .map(Map<String, dynamic>.from)
        .toList(growable: false);
  }
}

final gamificationCmsApiProvider = Provider<GamificationCmsApi>(
  (ref) => GamificationCmsApi(
    httpClient: ref.watch(edgeHttpClientProvider),
    edgeAuth: EdgeAuth.instance,
  ),
);
