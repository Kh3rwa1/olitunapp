import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:itun/core/config/cloudflare_config.dart';
import 'package:itun/core/logging/app_logger.dart';

import '../../core/api/admin_content_client.dart';
import '../../core/api/edge_json_client.dart';
import '../../core/storage/cache_service.dart';
import '../models/content_models.dart';

/// HTTP client provider for Letters Edge API (overridable in tests).
final lettersHttpClientProvider = Provider<http.Client>(
  (ref) => ref.watch(edgeHttpClientProvider),
);

@Deprecated('Use contentListProvider. Will be removed in v1.4.0')
final lettersProvider =
    AsyncNotifierProvider<LettersNotifier, List<LetterModel>>(
      LettersNotifier.new,
    );

/// Letters: cache-first, refreshed from the Cloudflare Worker, falling back to a bundled
/// seed when neither cache nor network has data.
class LettersNotifier extends AsyncNotifier<List<LetterModel>> {
  static const String _collectionId = 'letters';
  static const String _cacheKey = 'cached_letters';

  static final List<LetterModel> _seedLetters = [
    // ... (existing seeds)
    LetterModel(
      id: 'ᱚ',
      charOlChiki: 'ᱚ',
      transliterationLatin: 'La',
      pronunciation: 'o',
    ),
    LetterModel(
      id: 'ᱟ',
      charOlChiki: 'ᱟ',
      transliterationLatin: 'Aah',
      pronunciation: 'aa',
    ),
    LetterModel(
      id: 'ᱤ',
      charOlChiki: 'ᱤ',
      transliterationLatin: 'Li',
      pronunciation: 'i',
    ),
    LetterModel(
      id: 'ᱩ',
      charOlChiki: 'ᱩ',
      transliterationLatin: 'Lu',
      pronunciation: 'u',
    ),
    LetterModel(
      id: 'ᱮ',
      charOlChiki: 'ᱮ',
      transliterationLatin: 'Le',
      pronunciation: 'e',
    ),
    LetterModel(
      id: 'ᱳ',
      charOlChiki: 'ᱳ',
      transliterationLatin: 'Lo',
      pronunciation: 'oh',
    ),
    LetterModel(
      id: 'ᱠ',
      charOlChiki: 'ᱠ',
      transliterationLatin: 'Ok',
      pronunciation: 'ko',
    ),
    LetterModel(
      id: 'ᱜ',
      charOlChiki: 'ᱜ',
      transliterationLatin: 'Ol',
      pronunciation: 'ga',
    ),
  ];

  @override
  FutureOr<List<LetterModel>> build() async {
    var active = true;
    ref.onDispose(() => active = false);

    final cached = await CacheService.getList(_cacheKey, LetterModel.fromJson);
    final hasCache = cached != null && cached.isNotEmpty;
    if (active && hasCache) state = AsyncValue.data(cached);

    try {
      final rows = await EdgeJsonClient.getList(
        ref.read(lettersHttpClientProvider),
        Uri.parse(CloudflareConfig.lettersEndpoint),
        'letters',
        timeout: const Duration(seconds: 4),
      );
      final list = rows.map(LetterModel.fromJson).toList();
      if (list.isEmpty) {
        return hasCache ? cached : _deduplicate(_seedLetters);
      }
      final uniqueList = _deduplicate(list);
      await CacheService.set(
        _cacheKey,
        uniqueList.map((e) => e.toJson()).toList(),
      );
      return uniqueList;
    } catch (e, stack) {
      AppLogger.warning(
        'Loading letters failed; using cache or seed',
        name: 'LettersNotifier',
        error: e,
        stackTrace: stack,
      );
      return hasCache ? cached : _deduplicate(_seedLetters);
    }
  }

  List<LetterModel> _deduplicate(List<LetterModel> list) {
    final seenIds = <String>{};
    final seenChars = <String>{};
    final unique = <LetterModel>[];

    for (final item in list) {
      if (seenIds.contains(item.id)) continue;
      if (seenChars.contains(item.charOlChiki)) continue;
      seenIds.add(item.id);
      seenChars.add(item.charOlChiki);
      unique.add(item);
    }
    return unique;
  }

  Future<void> _mutate(String action, Future<void> Function() write) async {
    try {
      await write();
    } catch (e, stack) {
      AppLogger.error(
        '$action letter failed',
        name: 'LettersNotifier',
        error: e,
        stackTrace: stack,
      );
      return;
    }
    ref.invalidateSelf();
    await future;
  }

  Future<void> add(LetterModel item) => _mutate(
    'Add',
    () => ref
        .read(adminContentClientProvider)
        .upsert(_collectionId, item.id, item.toJson(), dropNulls: true),
  );

  Future<void> updateItem(LetterModel item) => _mutate(
    'Update',
    () => ref
        .read(adminContentClientProvider)
        .upsert(_collectionId, item.id, item.toJson(), dropNulls: true),
  );

  Future<void> delete(String id) => _mutate(
    'Delete',
    () => ref.read(adminContentClientProvider).delete(_collectionId, id),
  );

  Future<void> addLetter(LetterModel item) => add(item);
  Future<void> updateLetter(LetterModel item) => updateItem(item);
  Future<void> deleteLetter(String id) => delete(id);

  Future<void> seed() async {
    ref.invalidateSelf();
    await future;
  }
}
