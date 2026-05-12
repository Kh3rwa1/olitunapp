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
  WordsNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadWords();
  }

  final Ref ref;

  static final List<WordModel> _seedWords = [
    // ── Greetings & Basic ──
    WordModel(
      id: 'w1',
      wordOlChiki: 'ᱡᱚᱦᱟᱨ',
      wordLatin: 'Johar',
      meaning: 'Hello / Greetings',
      category: 'greeting',
    ),
    WordModel(
      id: 'w2',
      wordOlChiki: 'ᱫᱟᱠ',
      wordLatin: 'Dak',
      meaning: 'Water',
      category: 'food',
      order: 1,
    ),
    WordModel(
      id: 'w3',
      wordOlChiki: 'ᱥᱟᱨᱦᱟᱣ',
      wordLatin: 'Sarhaw',
      meaning: 'Thank you',
      category: 'greeting',
      order: 2,
    ),
    WordModel(
      id: 'w4',
      wordOlChiki: 'ᱦᱮᱸ',
      wordLatin: 'Hẽ',
      meaning: 'Yes',
      category: 'basic',
      order: 3,
    ),
    WordModel(
      id: 'w5',
      wordOlChiki: 'ᱵᱟᱝ',
      wordLatin: 'Bang',
      meaning: 'No',
      category: 'basic',
      order: 4,
    ),
    // ── Family ──
    WordModel(
      id: 'w6',
      wordOlChiki: 'ᱟᱯᱟ',
      wordLatin: 'Apa',
      meaning: 'Father',
      category: 'family',
      order: 5,
    ),
    WordModel(
      id: 'w7',
      wordOlChiki: 'ᱟᱭᱚ',
      wordLatin: 'Ayo',
      meaning: 'Mother',
      category: 'family',
      order: 6,
    ),
    WordModel(
      id: 'w8',
      wordOlChiki: 'ᱦᱟᱹᱴᱤᱧ',
      wordLatin: 'Hating',
      meaning: 'Elder brother',
      category: 'family',
      order: 7,
    ),
    WordModel(
      id: 'w9',
      wordOlChiki: 'ᱢᱤᱥᱨᱟ',
      wordLatin: 'Misra',
      meaning: 'Elder sister',
      category: 'family',
      order: 8,
    ),
    WordModel(
      id: 'w10',
      wordOlChiki: 'ᱦᱚᱯᱚᱱ',
      wordLatin: 'Hopon',
      meaning: 'Child / Son',
      category: 'family',
      order: 9,
    ),
    WordModel(
      id: 'w11',
      wordOlChiki: 'ᱠᱩᱲᱤ',
      wordLatin: 'Kuri',
      meaning: 'Girl / Daughter',
      category: 'family',
      order: 10,
    ),
    // ── Nature ──
    WordModel(
      id: 'w12',
      wordOlChiki: 'ᱵᱤᱨ',
      wordLatin: 'Bir',
      meaning: 'Forest / Jungle',
      category: 'nature',
      order: 11,
    ),
    WordModel(
      id: 'w13',
      wordOlChiki: 'ᱵᱩᱨᱩ',
      wordLatin: 'Buru',
      meaning: 'Mountain',
      category: 'nature',
      order: 12,
    ),
    WordModel(
      id: 'w14',
      wordOlChiki: 'ᱫᱟᱨᱮ',
      wordLatin: 'Dare',
      meaning: 'Tree',
      category: 'nature',
      order: 13,
    ),
    WordModel(
      id: 'w15',
      wordOlChiki: 'ᱵᱟᱦᱟ',
      wordLatin: 'Baha',
      meaning: 'Flower',
      category: 'nature',
      order: 14,
    ),
    WordModel(
      id: 'w16',
      wordOlChiki: 'ᱥᱤᱧ',
      wordLatin: 'Sing',
      meaning: 'Sun',
      category: 'nature',
      order: 15,
    ),
    WordModel(
      id: 'w17',
      wordOlChiki: 'ᱪᱟᱸᱫᱚ',
      wordLatin: 'Chando',
      meaning: 'Moon',
      category: 'nature',
      order: 16,
    ),
    WordModel(
      id: 'w18',
      wordOlChiki: 'ᱤᱯᱤᱞ',
      wordLatin: 'Ipil',
      meaning: 'Star',
      category: 'nature',
      order: 17,
    ),
    // ── Body Parts ──
    WordModel(
      id: 'w19',
      wordOlChiki: 'ᱵᱚᱦᱚᱠ',
      wordLatin: 'Bohok',
      meaning: 'Head',
      category: 'body',
      order: 18,
    ),
    WordModel(
      id: 'w20',
      wordOlChiki: 'ᱢᱮᱫ',
      wordLatin: 'Med',
      meaning: 'Eye',
      category: 'body',
      order: 19,
    ),
    WordModel(
      id: 'w21',
      wordOlChiki: 'ᱞᱩᱛᱩᱨ',
      wordLatin: 'Lutur',
      meaning: 'Ear',
      category: 'body',
      order: 20,
    ),
    WordModel(
      id: 'w22',
      wordOlChiki: 'ᱛᱤ',
      wordLatin: 'Ti',
      meaning: 'Hand',
      category: 'body',
      order: 21,
    ),
    // ── Food & Daily ──
    WordModel(
      id: 'w23',
      wordOlChiki: 'ᱡᱚᱢ',
      wordLatin: 'Jom',
      meaning: 'Eat / Food',
      category: 'food',
      order: 22,
    ),
    WordModel(
      id: 'w24',
      wordOlChiki: 'ᱤᱞ',
      wordLatin: 'Il',
      meaning: 'Meat / Fish',
      category: 'food',
      order: 23,
    ),
    WordModel(
      id: 'w25',
      wordOlChiki: 'ᱚᱞᱚᱝ',
      wordLatin: 'Olong',
      meaning: 'Home / House',
      category: 'daily',
      order: 24,
    ),
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

  Future<void> seed() async {
    for (final item in _seedWords) {
      try {
        final db = ref.read(appwriteDbServiceProvider);
        await db.createDocument('words', item.id, item.toJson());
      } catch (e) {
        debugPrint('Word already exists or error: $e');
      }
    }
    await _loadWords();
  }
}
