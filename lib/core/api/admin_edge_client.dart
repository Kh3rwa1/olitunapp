import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../auth/edge_auth.dart';
import '../config/cloudflare_config.dart';
import 'edge_json_client.dart';

/// Status code plus decoded JSON object of one Worker response.
class AdminEdgeResponse {
  const AdminEdgeResponse(this.statusCode, this.body);

  final int statusCode;

  /// Decoded JSON object, or null for an empty/non-object body.
  final Map<String, dynamic>? body;

  bool get isSuccess =>
      statusCode >= 200 && statusCode < 300 && body?['ok'] != false;

  String? get message {
    final value = body?['message'];
    return value is String && value.isNotEmpty ? value : null;
  }
}

/// Authenticated JSON calls to the Worker's `/api/v1/admin/*` routes.
///
/// The Worker authorizes admin-team members from the Appwrite JWT in the
/// `Authorization` header ([EdgeAuth]); a 401 retries once with a fresh JWT.
class AdminEdgeClient {
  AdminEdgeClient({http.Client? httpClient, EdgeAuth? edgeAuth})
    : _http = httpClient ?? http.Client(),
      _edgeAuth = edgeAuth ?? EdgeAuth.instance;

  static const Duration timeout = Duration(seconds: 20);

  final http.Client _http;
  final EdgeAuth _edgeAuth;

  static Uri adminUri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('${CloudflareConfig.baseUrl}/api/v1/admin/$path');
    return query == null || query.isEmpty
        ? uri
        : uri.replace(queryParameters: query);
  }

  /// Sends the request and returns the response whatever its status.
  /// Transport failures and timeouts throw [EdgeApiException].
  Future<AdminEdgeResponse> send(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    Future<http.Response> attempt() async {
      final headers = <String, String>{
        'Accept': 'application/json',
        if (body != null) 'Content-Type': 'application/json',
        ...await _edgeAuth.headers(),
      };
      final request = method == 'GET'
          ? _http.get(uri, headers: headers)
          : _http.post(uri, headers: headers, body: jsonEncode(body ?? {}));
      return request.timeout(timeout);
    }

    http.Response res;
    try {
      res = await attempt();
      if (res.statusCode == 401) {
        _edgeAuth.clear();
        res = await attempt();
      }
    } on TimeoutException {
      throw EdgeApiException('Request to ${uri.path} timed out');
    } catch (e) {
      throw EdgeApiException('Request to ${uri.path} failed: $e');
    }
    return AdminEdgeResponse(res.statusCode, _decode(res.bodyBytes));
  }

  /// GET that must succeed: non-2xx or `ok != true` throws
  /// [EdgeApiException] carrying the status and the Worker's message.
  Future<Map<String, dynamic>> getOk(Uri uri) async {
    final res = await send('GET', uri);
    return _requireOk(uri, res);
  }

  /// POST that must succeed (same rules as [getOk]).
  Future<Map<String, dynamic>> postOk(
    Uri uri,
    Map<String, dynamic> body,
  ) async {
    final res = await send('POST', uri, body: body);
    return _requireOk(uri, res);
  }

  Map<String, dynamic> _requireOk(Uri uri, AdminEdgeResponse res) {
    final body = res.body;
    if (!res.isSuccess || body == null) {
      throw EdgeApiException(
        res.message ?? 'Request to ${uri.path} failed',
        statusCode: res.statusCode,
      );
    }
    return body;
  }

  static Map<String, dynamic>? _decode(List<int> bytes) {
    if (bytes.isEmpty) return null;
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } on FormatException {
      return null;
    }
  }
}

final adminEdgeClientProvider = Provider<AdminEdgeClient>(
  (ref) => AdminEdgeClient(httpClient: ref.watch(edgeHttpClientProvider)),
);
