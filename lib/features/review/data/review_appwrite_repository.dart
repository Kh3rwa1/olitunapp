// Appwrite-backed review state repository (production implementation).
//
// Collection: `review_states` (olitun_db), one row per user+item with
// row-level owner permissions (`user:{userId}`) — a user can never read or
// modify another user's review state (P9). Document ID is deterministic
// `${userId}_${itemId}`, so Appwrite's unique document-ID constraint IS the
// duplicate-prevention mechanism and pushes are idempotent.
//
// Indexed columns (userId, nextReviewAt, lastReviewedAt) support server-side
// queries without loading full histories; the scheduler payload travels as
// `stateJson` so scheduler evolution never requires attribute migrations.
// See scripts/create_review_collection.mjs for provisioning.

import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';

import '../../../core/api/appwrite_db_service.dart';
import '../../../core/api/appwrite_query_builders.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/review_item.dart';
import '../domain/review_repository.dart';
import 'review_store.dart';

class ReviewAppwriteRepository implements ReviewRepository {
  final AppwriteDbService _db;

  ReviewAppwriteRepository(this._db);

  static const collectionId = 'review_states';

  /// Deterministic per-user identity. Sanitized to Appwrite's allowed
  /// document-ID characters; content IDs are alphanumerics in practice.
  @visibleForTesting
  static String rowIdFor(String userId, String itemId) {
    String clean(String raw) => raw
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')
        .substring(0, raw.length.clamp(0, 60));
    return '${clean(userId)}__${clean(itemId)}';
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
    final rowId = rowIdFor(userId, item.itemId);
    final data = <String, dynamic>{
      'userId': userId,
      'itemId': item.itemId,
      'itemType': item.itemType.json,
      'stateJson': jsonEncode(item.toMap()),
      'nextReviewAt': item.nextReviewAt.toIso8601String(),
      'lastReviewedAt': item.lastReviewedAt?.toIso8601String(),
      'schemaVersion': ReviewStore.schemaVersion,
    };
    try {
      await _db.createOwnerPrivateRow(collectionId, rowId, data, userId);
    } on AppwriteException catch (e) {
      if (e.code == 409) {
        // Duplicate push: same deterministic row exists — overwrite.
        await _db.updateDataPreservingPermissions(collectionId, rowId, data);
      } else {
        rethrow;
      }
    }
  }
}
