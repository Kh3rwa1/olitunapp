import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/appwrite_db_service.dart';
import '../models/content_models.dart';

final wordsProvider =
    StateNotifierProvider<WordsNotifier, AsyncValue<List<WordModel>>>(
      WordsNotifier.new,
    );

class WordsNotifier extends StateNotifier<AsyncValue<List<WordModel>>> {
  WordsNotifier(this.ref) : super(AsyncValue.data(_seedWords)) {
    _loadWords();
  }

  final Ref ref;

  static final List<WordModel> _seedWords = [
    WordModel(id: 'w1', wordOlChiki: 'ᱡᱚᱦᱟᱨ', wordLatin: 'Johar', meaning: 'Hello'),
    WordModel(id: 'w2', wordOlChiki: 'ᱫᱟᱠ', wordLatin: 'Dak', meaning: 'Water'),
  ];

  Future<void> _loadWords() async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      final data = await db.listDocuments(
        'words',
        queries: [Query.orderAsc('order'), Query.limit(500)],
      );
      state = AsyncValue.data(data.map(WordModel.fromJson).toList());
    } catch (e) {
      state = AsyncValue.data(_seedWords);
    }
  }

  Future<void> add(WordModel item) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.createDocument('words', item.id, item.toJson());
      await _loadWords();
    } catch (e) {
      debugPrint('❌ add word FAILED: $e');
    }
  }

  Future<void> update(WordModel item) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.updateDocument('words', item.id, item.toJson());
      await _loadWords();
    } catch (e) {
      debugPrint('❌ update word FAILED: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.deleteDocument('words', id);
      await _loadWords();
    } catch (e) {
      debugPrint('❌ delete word FAILED: $e');
    }
  }

  void addWord(WordModel item) => add(item);
  void updateWord(WordModel item) => update(item);
  void deleteWord(String id) => delete(id);

  Future<void> seed() async => _loadWords();
}
