import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../auth/edge_auth.dart';
import '../config/cloudflare_config.dart';
import 'edge_json_client.dart';

/// Admin CMS writes and full-body reads for curriculum content and app
/// settings, served by the Cloudflare Worker (`/api/v1/admin/...`, D1).
///
/// Every request carries the admin's Appwrite JWT from [EdgeAuth]; the Worker
/// verifies admin-team membership. Failures (transport, non-2xx, malformed
/// body) throw [EdgeApiException] with the HTTP status when there is one.
class AdminContentClient {
  AdminContentClient(
    this._client, {
    Future<Map<String, String>> Function()? authHeaders,
  }) : _authHeaders = authHeaders ?? EdgeAuth.instance.headers;

  static const Duration readTimeout = Duration(seconds: 10);
  static const Duration writeTimeout = Duration(seconds: 15);

  /// Tables the Worker accepts; mirrors `CONTENT_TABLES` in
  /// `cloudflare/backend/src/routes/admin_content.ts`.
  static const Set<String> tables = {
    'categories',
    'lessons',
    'letters',
    'numbers',
    'words',
    'sentences',
    'rhymes',
    'banners',
    'quizzes',
  };

  final http.Client _client;
  final Future<Map<String, String>> Function() _authHeaders;

  static String _table(String table) {
    if (!tables.contains(table)) {
      throw ArgumentError.value(table, 'table', 'Unsupported content table');
    }
    return table;
  }

  static Uri _contentUri(String table, [String? id]) => Uri.parse(
    '${CloudflareConfig.adminContentEndpoint}/${_table(table)}'
    '${id == null ? '' : '/${Uri.encodeComponent(id)}'}',
  );

  static Uri _settingUri([String? key]) => Uri.parse(
    '${CloudflareConfig.adminSettingsEndpoint}'
    '${key == null ? '' : '/${Uri.encodeComponent(key)}'}',
  );

  /// Every row of [table], inactive ones included, uncached.
  Future<List<Map<String, dynamic>>> list(String table) async {
    final body = await _send('GET', _contentUri(table), timeout: readTimeout);
    return _mapList(body, 'items');
  }

  /// One full document from [table].
  Future<Map<String, dynamic>> get(String table, String id) async {
    final body = await _send(
      'GET',
      _contentUri(table, id),
      timeout: readTimeout,
    );
    return _map(body, 'item');
  }

  /// Creates or updates [id] in [table]. Fields are merged onto the stored
  /// document (Appwrite update semantics); returns the stored document.
  /// With [dropNulls], null fields are omitted so they keep their stored
  /// value instead of being cleared.
  Future<Map<String, dynamic>> upsert(
    String table,
    String id,
    Map<String, dynamic> data, {
    bool dropNulls = false,
  }) async {
    final payload = Map<String, dynamic>.from(data)..remove('id');
    if (dropNulls) payload.removeWhere((_, value) => value == null);
    final body = await _send('PUT', _contentUri(table, id), body: payload);
    return _map(body, 'item');
  }

  /// Deletes [id] from [table]; a missing row surfaces as a 404.
  Future<void> delete(String table, String id) async {
    await _send('DELETE', _contentUri(table, id));
  }

  /// All app settings as `{settingKey, settingValue, ...}` documents.
  Future<List<Map<String, dynamic>>> listSettings() async {
    final body = await _send('GET', _settingUri(), timeout: readTimeout);
    return _mapList(body, 'documents');
  }

  Future<void> putSetting(String key, String value) async {
    await _send('PUT', _settingUri(key), body: {'settingValue': value});
  }

  Future<void> deleteSetting(String key) async {
    await _send('DELETE', _settingUri(key));
  }

  Future<Map<String, dynamic>> _send(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
    Duration timeout = writeTimeout,
  }) async {
    final request = http.Request(method, uri)
      ..headers.addAll({
        'Accept': 'application/json',
        if (body != null) 'Content-Type': 'application/json',
        ...await _authHeaders(),
      });
    if (body != null) request.body = jsonEncode(body);

    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _client.send(request).timeout(timeout),
      ).timeout(timeout);
    } on TimeoutException {
      throw EdgeApiException('$method ${uri.path} timed out');
    } catch (e) {
      throw EdgeApiException('$method ${uri.path} failed: $e');
    }

    Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      decoded = null;
    }
    final json = decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = json?['message'] ?? json?['error'];
      throw EdgeApiException(
        '$method ${uri.path} failed'
        '${message == null ? '' : ': $message'}',
        statusCode: response.statusCode,
      );
    }
    if (json == null || json['ok'] != true) {
      throw EdgeApiException('Unexpected response from ${uri.path}');
    }
    return json;
  }

  static Map<String, dynamic> _map(Map<String, dynamic> body, String key) {
    final value = body[key];
    if (value is! Map) throw EdgeApiException('Missing "$key" in response');
    return Map<String, dynamic>.from(value);
  }

  static List<Map<String, dynamic>> _mapList(
    Map<String, dynamic> body,
    String key,
  ) {
    final value = body[key];
    if (value is! List) throw EdgeApiException('Missing "$key" list');
    return value
        .whereType<Map>()
        .map(Map<String, dynamic>.from)
        .toList(growable: false);
  }
}

final adminContentClientProvider = Provider<AdminContentClient>(
  (ref) => AdminContentClient(ref.watch(edgeHttpClientProvider)),
);
