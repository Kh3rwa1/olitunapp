import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/content_models.dart';
import 'seeded_content_list_notifier.dart';

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

class SentencesNotifier extends SeededContentListNotifier<SentenceModel> {
  @override
  String get collectionId => 'sentences';

  @override
  String get label => 'sentence';

  @override
  SentenceModel Function(Map<String, dynamic> json) get fromJson =>
      SentenceModel.fromJson;

  @override
  String itemId(SentenceModel item) => item.id;

  @override
  int itemOrder(SentenceModel item) => item.order;

  @override
  Future<List<SentenceModel>> loadSeed() => loadSeedSentences();

  @override
  Future<void> loadList() async {
    final seed = await loadSeedSentences();
    try {
      final remote = await fetchRemote();
      if (remote.isEmpty) return emit(seed);
      final Map<String, SentenceModel> map = {for (final s in seed) s.id: s};
      for (final r in remote) {
        map[r.id] = r;
      }
      emit(map.values.toList()
        ..sort((a, b) => a.order.compareTo(b.order)));
    } catch (_) {
      // Offline or collection unavailable — fall back to bundled content.
      emit(seed);
    }
  }
}
