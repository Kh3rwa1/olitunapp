import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
final wordsProvider =
    NotifierProvider<WordsNotifier, AsyncValue<List<WordModel>>>(
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
  Future<void> loadList() async {
    final seed = await loadSeedWords();
    try {
      final remote = await fetchRemote();
      if (remote.isEmpty) return emit(seed);
      final Map<String, WordModel> map = {for (final w in seed) w.id: w};
      for (final r in remote) {
        map[r.id] = r;
      }
      emit(map.values.toList()..sort((a, b) => a.order.compareTo(b.order)));
    } catch (_) {
      // Offline or collection unavailable — fall back to bundled content.
      emit(seed);
    }
  }

  Future<void> addWord(WordModel item) => add(item);
  Future<void> updateWord(WordModel item) => update(item);
  Future<void> deleteWord(String id) => delete(id);
}
