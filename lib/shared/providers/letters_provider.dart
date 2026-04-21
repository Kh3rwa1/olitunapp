import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/appwrite_db_service.dart';
import '../../core/storage/cache_service.dart';
import '../models/content_models.dart';

final lettersProvider =
    StateNotifierProvider<LettersNotifier, AsyncValue<List<LetterModel>>>(
      (ref) => LettersNotifier(ref),
    );

class LettersNotifier extends StateNotifier<AsyncValue<List<LetterModel>>> {
  LettersNotifier(this.ref) : super(AsyncValue.data(_seedLetters)) {
    _loadLetters();
  }

  final Ref ref;
  static const String _cacheKey = 'cached_letters';

  static final List<LetterModel> _seedLetters = [
    // ... (existing seeds)
    LetterModel(id: 'ᱚ', charOlChiki: 'ᱚ', transliterationLatin: 'La', pronunciation: 'o'),
    LetterModel(id: 'ᱟ', charOlChiki: 'ᱟ', transliterationLatin: 'Aah', pronunciation: 'aa'),
    LetterModel(id: 'ᱤ', charOlChiki: 'ᱤ', transliterationLatin: 'Li', pronunciation: 'i'),
    LetterModel(id: 'ᱩ', charOlChiki: 'ᱩ', transliterationLatin: 'Lu', pronunciation: 'u'),
    LetterModel(id: 'ᱮ', charOlChiki: 'ᱮ', transliterationLatin: 'Le', pronunciation: 'e'),
    LetterModel(id: 'ᱳ', charOlChiki: 'ᱳ', transliterationLatin: 'Lo', pronunciation: 'oh'),
    LetterModel(id: 'ᱠ', charOlChiki: 'ᱠ', transliterationLatin: 'Ok', pronunciation: 'ko'),
    LetterModel(id: 'ᱜ', charOlChiki: 'ᱜ', transliterationLatin: 'Ol', pronunciation: 'ga'),
  ];

  Future<void> _loadLetters() async {
    // 1. Try Cache
    final cached = await CacheService.getList(_cacheKey, (json) => LetterModel.fromJson(json));
    if (cached != null && cached.isNotEmpty) {
      state = AsyncValue.data(cached);
    }

    // 2. Network
    try {
      final db = ref.read(appwriteDbServiceProvider);
      final data = await db.listDocuments(
        'letters',
        queries: [Query.orderAsc('order'), Query.limit(500)],
      );
      final list = data.map((e) => LetterModel.fromJson(e)).toList();
      
      if (list.isNotEmpty) {
        state = AsyncValue.data(list);
        // 3. Save Cache
        await CacheService.set(_cacheKey, list.map((e) => e.toJson()).toList());
      }
    } catch (e) {
      debugPrint('❌ _loadLetters network FAILED: $e');
      if (!state.hasValue || state.value!.isEmpty) {
        state = AsyncValue.data(_seedLetters);
      }
    }
  }

  Future<void> add(LetterModel item) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.createDocument('letters', item.id, item.toJson());
      await _loadLetters();
    } catch (e) {
      debugPrint('❌ add letter FAILED: $e');
    }
  }

  Future<void> update(LetterModel item) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.updateDocument('letters', item.id, item.toJson());
      await _loadLetters();
    } catch (e) {
      debugPrint('❌ update letter FAILED: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.deleteDocument('letters', id);
      await _loadLetters();
    } catch (e) {
      debugPrint('❌ delete letter FAILED: $e');
    }
  }

  void addLetter(LetterModel item) => add(item);
  void updateLetter(LetterModel item) => update(item);
  void deleteLetter(String id) => delete(id);

  Future<void> seed() async => _loadLetters();
}
