import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/core/logging/app_logger.dart';
import '../../core/api/appwrite_db_service.dart';
import '../models/content_models.dart';

/// Seeds the sentences collection from the bundled JSON asset
/// `assets/seed/sentences.json`.
Future<List<SentenceModel>> loadSeedSentences() async {
  final raw =
      jsonDecode(await rootBundle.loadString('assets/seed/sentences.json'))
          as List<dynamic>;
  return raw
      .cast<Map<String, dynamic>>()
      .map(SentenceModel.fromJson)
      .toList(growable: false);
}

@Deprecated('Use contentListProvider. Will be removed in v1.4.0')
final sentencesProvider =
    NotifierProvider<SentencesNotifier, AsyncValue<List<SentenceModel>>>(
      SentencesNotifier.new,
    );

class SentencesNotifier extends Notifier<AsyncValue<List<SentenceModel>>> {
  bool _disposed = false;

  @override
  AsyncValue<List<SentenceModel>> build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    // Deferred: `state` may not be read or written inside build().
    Future.microtask(_loadSentences);
    return const AsyncValue.loading();
  }

  Future<void> _loadSentences() async {
    final seed = await loadSeedSentences();
    try {
      final db = ref.read(appwriteDbServiceProvider);
      final data = await db.listDocuments(
        'sentences',
        queries: [Query.orderAsc('order'), Query.limit(500)],
      );
      if (_disposed) return;
      final remote = data.map(SentenceModel.fromJson).toList();
      final Map<String, SentenceModel> map = {for (final s in seed) s.id: s};
      for (final r in remote) {
        map[r.id] = r;
      }
      final merged = map.values.toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      state = AsyncValue.data(merged);
    } catch (e) {
      if (_disposed) return;
      state = AsyncValue.data(seed);
    }
  }

  Future<void> add(SentenceModel item) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.createDocument('sentences', item.id, item.toJson());
      await _loadSentences();
    } catch (e) {
      AppLogger.debug('❌ add sentence FAILED: $e');
      rethrow;
    }
  }

  Future<void> update(SentenceModel item) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.updateDocument('sentences', item.id, item.toJson());
      await _loadSentences();
    } catch (e) {
      AppLogger.debug('❌ update sentence FAILED: $e');
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.deleteDocument('sentences', id);
      await _loadSentences();
    } catch (e) {
      AppLogger.debug('❌ delete sentence FAILED: $e');
      rethrow;
    }
  }

  Future<void> seed() async {
    final db = ref.read(appwriteDbServiceProvider);
    final existingDocs = await db.listDocuments('sentences');
    final existingIds = existingDocs.map((doc) => doc['id'] as String).toSet();
    var seededCount = 0;
    for (final item in await loadSeedSentences()) {
      if (existingIds.contains(item.id)) continue;
      try {
        await db.createDocument('sentences', item.id, item.toJson());
        seededCount++;
      } catch (e) {
        AppLogger.debug('⚠️ Error seeding sentence ${item.id}: $e');
      }
    }
    AppLogger.debug('Seeded $seededCount missing default sentences.');
    await _loadSentences();
  }
}
