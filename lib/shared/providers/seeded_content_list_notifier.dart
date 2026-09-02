import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/core/api/appwrite_db_service.dart';
import 'package:itun/core/logging/app_logger.dart';

/// Shared skeleton for the admin content-list notifiers (words, letters,
/// numbers, sentences).
///
/// Subclasses supply the collection id, model mapping, bundled seed, and their
/// own load policy via [loadList]; the provider lifecycle, remote fetch, CRUD,
/// and seed backfill live here exactly once.
abstract class SeededContentListNotifier<T> extends Notifier<AsyncValue<List<T>>> {
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

  bool _disposed = false;

  @override
  AsyncValue<List<T>> build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    // Deferred: `state` may not be read or written inside build().
    Future.microtask(loadList);
    return const AsyncValue.loading();
  }

  /// Loads and emits the list. Implementations may use any policy (seed merge,
  /// cache-first, dedupe) but must respect the [_disposed] guard.
  Future<void> loadList();

  /// Fetches the remote collection ordered ascending by `order`.
  Future<List<T>> fetchRemote() async {
    final db = ref.read(appwriteDbServiceProvider);
    final data = await db.listDocuments(
      collectionId,
      queries: [Query.orderAsc('order'), Query.limit(500)],
    );
    return data.map(fromJson).toList();
  }

  /// Decodes a bundled seed asset (`assets/seed/<name>.json`).
  Future<List<T>> loadSeedAsset(String assetPath) async {
    final raw = jsonDecode(await rootBundle.loadString(assetPath)) as List<dynamic>;
    return raw.cast<Map<String, dynamic>>().map(fromJson).toList(growable: false);
  }

  /// Emits [items] unless the notifier was disposed mid-flight.
  void emit(List<T> items) {
    if (_disposed) return;
    state = AsyncValue.data(items);
  }

  Future<void> add(T item) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.createDocument(collectionId, itemId(item), _encode(item));
      await loadList();
    } catch (e) {
      AppLogger.debug('❌ add $label FAILED: $e');
      if (rethrowCrudErrors) rethrow;
    }
  }

  Future<void> update(T item) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.updateDocument(collectionId, itemId(item), _encode(item));
      await loadList();
    } catch (e) {
      AppLogger.debug('❌ update $label FAILED: $e');
      if (rethrowCrudErrors) rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.deleteDocument(collectionId, id);
      await loadList();
    } catch (e) {
      AppLogger.debug('❌ delete $label FAILED: $e');
      if (rethrowCrudErrors) rethrow;
    }
  }

  /// Backfills missing bundled seed rows into the remote collection, then
  /// reloads. Skips ids that already exist remotely.
  Future<void> seed() async {
    final db = ref.read(appwriteDbServiceProvider);
    final seedItems = await loadSeed();
    final existingDocs = await db.listDocuments(collectionId);
    final existingIds = existingDocs.map((doc) => doc['id'] as String).toSet();
    var seededCount = 0;
    for (final item in seedItems) {
      if (existingIds.contains(itemId(item))) continue;
      try {
        await db.createDocument(collectionId, itemId(item), _encode(item));
        seededCount++;
      } catch (e) {
        AppLogger.debug('⚠️ Error seeding $label ${itemId(item)}: $e');
      }
    }
    AppLogger.debug('Seeded $seededCount missing default $label entries.');
    await loadList();
  }

  Map<String, dynamic> _encode(T item) =>
      (item as dynamic).toJson() as Map<String, dynamic>;
}
