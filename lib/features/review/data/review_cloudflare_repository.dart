// Cloudflare Worker-backed review state repository (production).
//
// The Worker (`cloudflare/backend/src/routes/review.ts`) stores one D1 row
// per user+item and derives the user only from the verified Appwrite JWT
// sent by [EdgeAuth] — a user can never read or modify another user's
// review state. Appwrite is used for authentication only.
//
//  - Reads: `GET /api/v1/review/states`, paginated by row id.
//  - Writes: `POST /api/v1/review/mutate` with action upsert | applyRecall |
//    delete. applyRecall is idempotent by operationId (`duplicate: true` on
//    repeats).

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/auth/edge_auth.dart';
import '../../../core/config/cloudflare_config.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/review_item.dart';
import '../domain/review_repository.dart';
import 'review_store.dart';

/// A review sync request the Worker rejected or could not serve.
class ReviewSyncException implements Exception {
  ReviewSyncException(this.message, this.statusCode, this.code);

  final String message;
  final int statusCode;
  final String code;

  @override
  String toString() => 'ReviewSyncException($statusCode, $code): $message';
}

class ReviewCloudflareRepository implements ReviewOperationRepository {
  ReviewCloudflareRepository({
    required EdgeAuth edgeAuth,
    http.Client? httpClient,
    String statesEndpoint = CloudflareConfig.reviewStatesEndpoint,
    String mutateEndpoint = CloudflareConfig.reviewMutateEndpoint,
  }) : _edgeAuth = edgeAuth,
       _httpClient = httpClient ?? http.Client(),
       _statesEndpoint = statesEndpoint,
       _mutateEndpoint = mutateEndpoint;

  final EdgeAuth _edgeAuth;
  final http.Client _httpClient;
  final String _statesEndpoint;
  final String _mutateEndpoint;

  /// Rows per `GET /review/states` page (server maximum).
  static const pageSize = 500;

  /// Guards against a server that keeps returning a cursor.
  static const _maxPages = 200;
  static const _timeout = Duration(seconds: 15);

  /// Deterministic, collision-proof per-user row identity, computed by the
  /// Worker exactly like this (and identical to the former Appwrite row id).
  /// Length-prefixed domain separation plus a SHA-256 digest prevents
  /// truncation, separator-injection and sanitization collisions.
  @visibleForTesting
  static String rowIdFor(String userId, String itemId) {
    final input = 'usr:${userId.length}:$userId:item:${itemId.length}:$itemId';
    final digest = sha256.convert(utf8.encode(input)).toString();
    return 'r_${digest.substring(0, 31)}';
  }

  Future<Map<String, String>> _headers({bool json = false}) async => {
    'Accept': 'application/json',
    if (json) 'Content-Type': 'application/json',
    ...await _edgeAuth.headers(),
  };

  Map<String, dynamic>? _decode(http.Response res) {
    if (res.body.isEmpty) return null;
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      // Non-JSON body (proxy error page): reported via the status code.
    }
    return null;
  }

  ReviewSyncException _failure(String what, http.Response res) {
    // 401: the Worker could not verify this JWT; mint a fresh one next time.
    if (res.statusCode == 401) _edgeAuth.clear();
    final body = _decode(res);
    return ReviewSyncException(
      'review $what failed with status ${res.statusCode}: '
      '${body?['message'] ?? res.body}',
      res.statusCode,
      body?['error'] as String? ?? 'HTTP_${res.statusCode}',
    );
  }

  bool _isSuccess(http.Response res) =>
      res.statusCode >= 200 && res.statusCode < 300;

  Future<http.Response> _mutate(Map<String, dynamic> body) async {
    return _httpClient
        .post(
          Uri.parse(_mutateEndpoint),
          headers: await _headers(json: true),
          body: jsonEncode(body),
        )
        .timeout(_timeout);
  }

  @override
  Future<List<MemoryItemState>> loadRemoteStates(String userId) async {
    final states = <MemoryItemState>[];
    String? cursor;
    for (var page = 0; page < _maxPages; page++) {
      final uri = Uri.parse(
        _statesEndpoint,
      ).replace(queryParameters: {'limit': '$pageSize', 'cursor': ?cursor});
      final res = await _httpClient
          .get(uri, headers: await _headers())
          .timeout(_timeout);
      if (!_isSuccess(res)) throw _failure('load', res);
      final body = _decode(res);
      final rows = body?['rows'];
      if (rows is! List) {
        throw ReviewSyncException(
          'review load returned no rows',
          res.statusCode,
          'MALFORMED_RESPONSE',
        );
      }
      for (final row in rows) {
        try {
          final raw = row is Map ? row['stateJson'] : null;
          if (raw is! String || raw.isEmpty) continue;
          final decoded = jsonDecode(raw);
          if (decoded is! Map) continue;
          states.add(
            MemoryItemState.fromMap(Map<String, dynamic>.from(decoded)),
          );
        } catch (e) {
          // Malformed server row: skip it, keep the rest.
          AppLogger.debug(
            'ReviewCloudflareRepository: skipping malformed row: $e',
          );
        }
      }
      final next = body?['nextCursor'];
      if (body?['hasMore'] != true || next is! String || next.isEmpty) {
        return states;
      }
      cursor = next;
    }
    return states;
  }

  @override
  Future<void> pushState(String userId, MemoryItemState item) async {
    // No userId in the body: the Worker derives it from the JWT.
    final res = await _mutate({
      'action': 'upsert',
      'itemId': item.itemId,
      'itemType': item.itemType.json,
      'stateJson': jsonEncode(item.toMap()),
      'nextReviewAt': item.nextReviewAt.toIso8601String(),
      'lastReviewedAt': item.lastReviewedAt?.toIso8601String(),
      'schemaVersion': ReviewStore.schemaVersion,
    });
    if (!_isSuccess(res)) throw _failure('upsert', res);
  }

  @override
  Future<bool> applyRecallOperation(
    String userId,
    ReviewRecallOperationPayload op,
  ) async {
    final res = await _mutate({
      'action': 'applyRecall',
      ...op.toMap(),
      // Ownership is server-derived; the body value is a hint only and
      // must equal the JWT user or the Worker rejects with 403.
      'userId': userId,
    });
    if (!_isSuccess(res)) throw _failure('applyRecall', res);
    // Server reports duplicate:true when the operationId was already applied.
    return _decode(res)?['duplicate'] != true;
  }

  @override
  Future<void> deleteState(String userId, String itemId) async {
    final res = await _mutate({'action': 'delete', 'itemId': itemId});
    if (_isSuccess(res) || res.statusCode == 404) return;
    throw _failure('delete', res);
  }
}
