// Appwrite-backed review state repository (production implementation).
//
// Collection: `review_states` (olitun_db), one row per user+item with
// row-level owner permissions (`user:{userId}`) — a user can never read or
// modify another user's review state (P9).
//
// Document mutations (upsert/delete) are performed via the trusted serverless
// Appwrite Function `mutateReviewState` to eliminate deterministic row-ID
// squatting and verify authenticated user sessions.
//
// Remote reads remain direct via TablesDB with row-level security enabled
// (`rowSecurity: true`), guaranteeing users can only read their own documents.

import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../../core/api/appwrite_db_service.dart';
import '../../../core/api/appwrite_functions_service.dart';
import '../../../core/api/appwrite_query_builders.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/review_item.dart';
import '../domain/review_repository.dart';
import 'review_store.dart';

class ReviewAppwriteRepository implements ReviewRepository {
  final AppwriteDbService _db;
  final AppwriteFunctionsService _functions;

  ReviewAppwriteRepository(this._db, this._functions);

  static const collectionId = 'review_states';
  static const functionId = 'mutateReviewState';

  /// Legacy row-ID algorithm (sanitized and clamped to 60 chars per component):
  /// `${clean(userId)}__${clean(itemId)}` where clean replaces non-alphanumeric chars with `_`.
  @visibleForTesting
  static String legacyRowIdFor(String userId, String itemId) {
    String clean(String raw) => raw
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')
        .substring(0, raw.length.clamp(0, 60));
    return '${clean(userId)}__${clean(itemId)}';
  }

  /// Current deterministic, collision-proof per-user row identity.
  /// Uses length-prefixed domain separation and SHA-256 digest to prevent
  /// truncation collisions, separator injection, and character sanitization collisions.
  /// Result is 33 chars starting with 'r_' (valid Appwrite document ID: <= 36 chars, alphanumeric start).
  @visibleForTesting
  static String rowIdFor(String userId, String itemId) {
    final input = 'usr:${userId.length}:$userId:item:${itemId.length}:$itemId';
    final digest = sha256.convert(utf8.encode(input)).toString();
    return 'r_${digest.substring(0, 31)}';
  }

  @override
  Future<List<MemoryItemState>> loadRemoteStates(String userId) async {
    final rows = await _db.listDocuments(
      collectionId,
      queries: [DbQuery.equal('userId', userId)],
    );
    final states = <MemoryItemState>[];
    for (final row in rows) {
      try {
        final raw = row['stateJson'];
        if (raw is! String || raw.isEmpty) continue;
        final decoded = jsonDecode(raw);
        if (decoded is! Map) continue;
        states.add(MemoryItemState.fromMap(Map<String, dynamic>.from(decoded)));
      } catch (e) {
        // Malformed server response: skip the row, keep the rest.
        AppLogger.debug('ReviewAppwriteRepository: skipping malformed row: $e');
      }
    }
    return states;
  }

  @override
  Future<void> pushState(String userId, MemoryItemState item) async {
    final res = await _functions.execute(
      functionId,
      body: {
        'action': 'upsert',
        'itemId': item.itemId,
        'itemType': item.itemType.json,
        'stateJson': jsonEncode(item.toMap()),
        'nextReviewAt': item.nextReviewAt.toIso8601String(),
        'lastReviewedAt': item.lastReviewedAt?.toIso8601String(),
        'schemaVersion': ReviewStore.schemaVersion,
      },
      usePost: true,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AppwriteException(
        'mutateReviewState push failed with status ${res.statusCode}: ${res.responseBody}',
        res.statusCode,
        res.bodyJson?['error'] as String? ?? 'FUNCTION_ERROR',
      );
    }
  }

  @override
  Future<void> deleteState(String userId, String itemId) async {
    final res = await _functions.execute(
      functionId,
      body: {'action': 'delete', 'itemId': itemId},
      usePost: true,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      if (res.statusCode == 404) return;
      throw AppwriteException(
        'mutateReviewState delete failed with status ${res.statusCode}: ${res.responseBody}',
        res.statusCode,
        res.bodyJson?['error'] as String? ?? 'FUNCTION_ERROR',
      );
    }
  }
}
