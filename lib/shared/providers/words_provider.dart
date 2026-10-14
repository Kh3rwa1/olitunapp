import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/core/logging/app_logger.dart';
import '../models/content_models.dart';
import 'seeded_content_list_notifier.dart';

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
final wordsProvider = AsyncNotifierProvider<WordsNotifier, List<WordModel>>(
  WordsNotifier.new,
);

class WordsNotifier extends SeededContentListNotifier<WordModel> {
  @override
  String get collectionId => 'words';

  @override
  String get label => 'word';

  @override
  WordModel Function(Map<String, dynamic> json) get fromJson =>
      WordModel.fromJson;

  @override
  String itemId(WordModel item) => item.id;

  @override
  int itemOrder(WordModel item) => item.order;

  @override
  Future<List<WordModel>> loadSeed() => loadSeedWords();

  @override
  Future<List<WordModel>> loadList() async {
    final seed = await loadSeedWords();
    try {
      final remote = await fetchRemote();
      if (remote.isEmpty) return seed;
      final Map<String, WordModel> map = {for (final w in seed) w.id: w};
      for (final r in remote) {
        map[r.id] = r;
      }
      return map.values.toList()..sort((a, b) => a.order.compareTo(b.order));
    } catch (e, stack) {
      AppLogger.warning(
        'Loading words failed; using bundled seed',
        name: 'WordsNotifier',
        error: e,
        stackTrace: stack,
      );
      // Offline or collection unavailable — fall back to bundled content.
      return seed;
    }
  }

  Future<void> addWord(WordModel item) => add(item);
  Future<void> updateWord(WordModel item) => updateItem(item);
  Future<void> deleteWord(String id) => delete(id);
}
