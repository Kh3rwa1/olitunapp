import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:itun/core/api/appwrite_db_service.dart';
import 'package:itun/core/api/edge_json_client.dart';
import 'package:itun/core/config/cloudflare_config.dart';
import 'package:itun/core/logging/app_logger.dart';

/// HTTP client provider for SeededContent Edge API (overridable in tests).
final seededContentHttpClientProvider = Provider<http.Client>(
  (ref) => ref.watch(edgeHttpClientProvider),
);

/// Shared skeleton for the admin content-list notifiers (words, letters,
/// numbers, sentences).
///
/// Subclasses supply the collection id, model mapping, bundled seed, and their
/// own load policy via [loadList]; the provider lifecycle, remote fetch, CRUD,
/// and seed backfill live here exactly once.
abstract class SeededContentListNotifier<T> extends AsyncNotifier<List<T>> {
  /// Appwrite collection backing this list.
  String get collectionId;

  /// Human-readable noun used in log messages ('word', 'letter', ...).
  String get label;

  /// Decode one remote document.
  T Function(Map<String, dynamic> json) get fromJson;

  /// Stable unique id used for CRUD and seed backfill.
  String itemId(T item);

  /// Sort key; the merged list is emitted ascending by it.
  int itemOrder(T item);

  /// Bundled seed shown offline and used as the merge baseline.
  Future<List<T>> loadSeed();

  /// Whether CRUD errors are rethrown to the caller (words/sentences) or
  /// logged and swallowed (numbers).
  bool get rethrowCrudErrors => true;

  @override
  FutureOr<List<T>> build() => loadList();

  /// Loads the list. Implementations may use any policy (seed merge,
  /// cache-first, dedupe); the returned list becomes the provider's data.
  Future<List<T>> loadList();

  /// Fetches the remote collection (ordered ascending by `order`) from the
  /// Cloudflare Worker. An empty list is a valid result; failures throw.
  Future<List<T>> fetchRemote() async {
    final edgeEndpoint = _cloudflareEndpointFor(collectionId);
    if (edgeEndpoint == null) {
      throw UnsupportedError('No Cloudflare Worker route for $collectionId');
    }
    final rows = await EdgeJsonClient.getList(
      ref.read(seededContentHttpClientProvider),
      Uri.parse(edgeEndpoint),
      _keyForCollection(collectionId),
      timeout: const Duration(seconds: 4),
    );
    return rows.map(fromJson).toList();
  }

  String? _cloudflareEndpointFor(String collection) {
    switch (collection.toLowerCase()) {
      case 'words':
      case 'word':
        return CloudflareConfig.wordsEndpoint;
      case 'letters':
      case 'letter':
        return CloudflareConfig.lettersEndpoint;
      case 'numbers':
      case 'number':
        return CloudflareConfig.numbersEndpoint;
      case 'sentences':
      case 'sentence':
        return CloudflareConfig.sentencesEndpoint;
      default:
        return null;
    }
  }

  String _keyForCollection(String collection) {
    switch (collection.toLowerCase()) {
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
      default:
        return collection;
    }
  }

  /// Decodes a bundled seed asset (`assets/seed/<name>.json`).
  Future<List<T>> loadSeedAsset(String assetPath) async {
    final raw =
        jsonDecode(await rootBundle.loadString(assetPath)) as List<dynamic>;
    return raw
        .cast<Map<String, dynamic>>()
        .map(fromJson)
        .toList(growable: false);
  }

  /// Re-runs [build] and waits for the refreshed list.
  Future<void> reload() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> add(T item) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.createDocument(collectionId, itemId(item), _encode(item));
      await reload();
    } catch (e, stack) {
      AppLogger.error(
        'add $label failed',
        name: 'SeededContentListNotifier',
        error: e,
        stackTrace: stack,
      );
      if (rethrowCrudErrors) rethrow;
    }
  }

  Future<void> updateItem(T item) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.updateDocument(collectionId, itemId(item), _encode(item));
      await reload();
    } catch (e, stack) {
      AppLogger.error(
        'update $label failed',
        name: 'SeededContentListNotifier',
        error: e,
        stackTrace: stack,
      );
      if (rethrowCrudErrors) rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.deleteDocument(collectionId, id);
      await reload();
    } catch (e, stack) {
      AppLogger.error(
        'delete $label failed',
        name: 'SeededContentListNotifier',
        error: e,
        stackTrace: stack,
      );
      if (rethrowCrudErrors) rethrow;
    }
  }

  /// Backfills missing bundled seed rows into the remote collection, then
  /// reloads. Skips ids that already exist remotely.
  Future<void> seed() async {
    final db = ref.read(appwriteDbServiceProvider);
    final seedItems = await loadSeed();
    final existingDocs = await db.listAllDocuments(collectionId);
    final existingIds = existingDocs.map((doc) => doc['id'] as String).toSet();
    var seededCount = 0;
    for (final item in seedItems) {
      if (existingIds.contains(itemId(item))) continue;
      try {
        await db.createDocument(collectionId, itemId(item), _encode(item));
        seededCount++;
      } catch (e, stack) {
        AppLogger.warning(
          'Seeding $label ${itemId(item)} failed',
          name: 'SeededContentListNotifier',
          error: e,
          stackTrace: stack,
        );
      }
    }
    AppLogger.debug('Seeded $seededCount missing default $label entries.');
    await reload();
  }

  Map<String, dynamic> _encode(T item) =>
      (item as dynamic).toJson() as Map<String, dynamic>;
}
