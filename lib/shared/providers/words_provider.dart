import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/core/api/appwrite_db_service.dart';
import 'package:itun/core/logging/app_logger.dart';
import '../models/content_models.dart';

/// Seeds the words collection from the bundled JSON asset
/// `assets/seed/words.json`.
Future<List<WordModel>> loadSeedWords() async {
  final raw =
      jsonDecode(await rootBundle.loadString('assets/seed/words.json'))
          as List<dynamic>;
  return raw
      .cast<Map<String, dynamic>>()
      .map(WordModel.fromJson)
      .toList(growable: false);
}

@Deprecated('Use contentListProvider. Will be removed in v1.4.0')
final wordsProvider =
    NotifierProvider<WordsNotifier, AsyncValue<List<WordModel>>>(
      WordsNotifier.new,
    );

class WordsNotifier extends Notifier<AsyncValue<List<WordModel>>> {
  bool _disposed = false;

  Future<List<WordModel>> _fetchWords() async {
    final db = ref.read(appwriteDbServiceProvider);
    final data = await db.listDocuments(
      'words',
      queries: [Query.orderAsc('order'), Query.limit(500)],
    );
    return data.map(WordModel.fromJson).toList();
  }

  @override
  AsyncValue<List<WordModel>> build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    // Deferred: `state` may not be read or written inside build().
    Future.microtask(_load);
    return const AsyncValue.loading();
  }

  Future<void> _load() async {
    final seed = await loadSeedWords();
    try {
      final remote = await _fetchWords();
      if (_disposed) return;
      final Map<String, WordModel> map = {for (final w in seed) w.id: w};
      for (final r in remote) {
        map[r.id] = r;
      }
      final merged = map.values.toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      state = AsyncValue.data(merged);
    } catch (_) {
      if (_disposed) return;
      // Offline or collection unavailable — fall back to bundled content.
      state = AsyncValue.data(seed);
    }
  }

  Future<void> _reload() async {
    state = const AsyncValue.loading();
    await _load();
  }

  Future<void> add(WordModel item) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.createDocument('words', item.id, item.toJson());
      await _reload();
    } catch (e) {
      AppLogger.debug('❌ add word FAILED: $e');
      rethrow;
    }
  }

  Future<void> update(WordModel item) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.updateDocument('words', item.id, item.toJson());
      await _reload();
    } catch (e) {
      AppLogger.debug('❌ update word FAILED: $e');
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.deleteDocument('words', id);
      await _reload();
    } catch (e) {
      AppLogger.debug('❌ delete word FAILED: $e');
      rethrow;
    }
  }

  Future<void> addWord(WordModel item) => add(item);
  Future<void> updateWord(WordModel item) => update(item);
  Future<void> deleteWord(String id) => delete(id);

  Future<void> seed() async {
    final db = ref.read(appwriteDbServiceProvider);
    final existingDocs = await db.listDocuments('words');
    final existingIds = existingDocs.map((doc) => doc['id'] as String).toSet();
    var seededCount = 0;
    for (final item in await loadSeedWords()) {
      if (existingIds.contains(item.id)) continue;
      try {
        await db.createDocument('words', item.id, item.toJson());
        seededCount++;
      } catch (e) {
        AppLogger.debug('⚠️ Error seeding word ${item.id}: $e');
      }
    }
    AppLogger.debug('Seeded $seededCount missing default words.');
    await _reload();
  }
}
