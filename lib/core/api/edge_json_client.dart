import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// One shared HTTP client for Cloudflare Worker reads, so content providers
/// stop opening a fresh connection pool per request. Feature-level client
/// providers default to this one and remain overridable in tests.
final edgeHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

/// Raised when a Worker read fails: transport error, non-2xx status, or a
/// body that is not the `{ok: true, ...}` envelope the Worker returns.
class EdgeApiException implements Exception {
  final String message;
  final int? statusCode;

  const EdgeApiException(this.message, {this.statusCode});

  @override
  String toString() => statusCode == null
      ? 'EdgeApiException: $message'
      : 'EdgeApiException($statusCode): $message';
}

/// Small JSON helpers for Cloudflare Worker GET routes.
///
/// Every content route answers `{ok: true, <key>: [...]}`. An empty list is a
/// valid result; only transport/HTTP/shape problems throw [EdgeApiException].
class EdgeJsonClient {
  EdgeJsonClient._();

  static const Duration defaultTimeout = Duration(seconds: 8);

  /// GETs [uri] and returns the decoded `{ok: true}` envelope.
  static Future<Map<String, dynamic>> getJson(
    http.Client client,
    Uri uri, {
    Map<String, String> headers = const {},
    Duration timeout = defaultTimeout,
  }) async {
    final http.Response response;
    try {
      response = await client
          .get(uri, headers: {'Accept': 'application/json', ...headers})
          .timeout(timeout);
    } on TimeoutException {
      throw EdgeApiException('Request to ${uri.path} timed out');
    } catch (e) {
      throw EdgeApiException('Request to ${uri.path} failed: $e');
    }
    if (response.statusCode != 200) {
      throw EdgeApiException(
        'Request to ${uri.path} failed',
        statusCode: response.statusCode,
      );
    }
    final Object? body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw EdgeApiException('Malformed JSON from ${uri.path}');
    }
    if (body is! Map || body['ok'] != true) {
      throw EdgeApiException('Unexpected response from ${uri.path}');
    }
    return Map<String, dynamic>.from(body);
  }

  /// GETs [uri] and returns `body[key]` as a list of maps (non-map entries
  /// are dropped). Throws when `body[key]` is missing or not a list.
  static Future<List<Map<String, dynamic>>> getList(
    http.Client client,
    Uri uri,
    String key, {
    Map<String, String> headers = const {},
    Duration timeout = defaultTimeout,
  }) async {
    final body = await getJson(client, uri, headers: headers, timeout: timeout);
    final items = body[key];
    if (items is! List) {
      throw EdgeApiException('Missing "$key" list from ${uri.path}');
    }
    return items
        .whereType<Map>()
        .map(Map<String, dynamic>.from)
        .toList(growable: false);
  }
}
