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
    // ── Greetings & Basics (greeting/basic) ──
    WordModel(
      id: 'w1',
      wordOlChiki: 'ᱡᱚᱦᱟᱨ',
      wordLatin: 'Johar',
      meaning: 'Hello / Greetings',
      category: 'greeting',
      order: 1,
    ),
    WordModel(
      id: 'w2',
      wordOlChiki: 'ᱥᱟᱨᱦᱟᱣ',
      wordLatin: 'Sarhaw',
      meaning: 'Thank you',
      category: 'greeting',
      order: 2,
    ),
    WordModel(
      id: 'w3',
      wordOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱫᱟᱨᱟᱢ',
      wordLatin: 'Sagun Daram',
      meaning: 'Welcome',
      category: 'greeting',
      order: 3,
    ),
    WordModel(
      id: 'w4',
      wordOlChiki: 'ᱦᱮᱸ',
      wordLatin: 'Hẽ',
      meaning: 'Yes',
      category: 'basic',
      order: 4,
    ),
    WordModel(
      id: 'w5',
      wordOlChiki: 'ᱵᱟᱝ',
      wordLatin: 'Bang',
      meaning: 'No',
      category: 'basic',
      order: 5,
    ),

    // ── Family & Relationships (family) ──
    WordModel(
      id: 'w6',
      wordOlChiki: 'ᱵᱟᱵᱟ',
      wordLatin: 'Baba',
      meaning: 'Father',
      category: 'family',
      order: 6,
    ),
    WordModel(
      id: 'w7',
      wordOlChiki: 'ᱟᱭᱳ',
      wordLatin: 'Ayo',
      meaning: 'Mother',
      category: 'family',
      order: 7,
    ),
    WordModel(
      id: 'w8',
      wordOlChiki: 'ᱳᱲᱟᱜ ᱦᱚᱲ',
      wordLatin: 'Orag hor',
      meaning: 'Spouse / Family member',
      category: 'family',
      order: 8,
    ),
    WordModel(
      id: 'w9',
      wordOlChiki: 'ᱫᱟᱫᱟ',
      wordLatin: 'Dada',
      meaning: 'Elder brother',
      category: 'family',
      order: 9,
    ),
    WordModel(
      id: 'w10',
      wordOlChiki: 'ᱫᱟᱹᱭ',
      wordLatin: 'Dai',
      meaning: 'Elder sister',
      category: 'family',
      order: 10,
    ),
    WordModel(
      id: 'w11',
      wordOlChiki: 'ᱵᱚᱠᱚᱧ',
      wordLatin: 'Bokonj',
      meaning: 'Younger brother',
      category: 'family',
      order: 11,
    ),
    WordModel(
      id: 'w12',
      wordOlChiki: 'ᱢᱤᱥᱮᱨᱟ',
      wordLatin: 'Misera',
      meaning: 'Younger sister',
      category: 'family',
      order: 12,
    ),

    // ── Daily Use Words (daily) ──
    WordModel(
      id: 'w13',
      wordOlChiki: 'ᱫᱟᱜ',
      wordLatin: 'Dag',
      meaning: 'Water',
      category: 'daily',
      order: 13,
    ),
    WordModel(
      id: 'w14',
      wordOlChiki: 'ᱫᱟᱠᱟ',
      wordLatin: 'Daka',
      meaning: 'Cooked Rice / Food',
      category: 'daily',
      order: 14,
    ),
    WordModel(
      id: 'w15',
      wordOlChiki: 'ᱳᱲᱟᱜ',
      wordLatin: 'Orag',
      meaning: 'Home / House',
      category: 'daily',
      order: 15,
    ),
    WordModel(
      id: 'w16',
      wordOlChiki: 'ᱠᱤᱪᱨᱤᱡ',
      wordLatin: 'Kicrij',
      meaning: 'Cloth',
      category: 'daily',
      order: 16,
    ),
    WordModel(
      id: 'w17',
      wordOlChiki: 'ᱦᱚᱨ',
      wordLatin: 'Hor',
      meaning: 'Path / Road',
      category: 'daily',
      order: 17,
    ),
    WordModel(
      id: 'w18',
      wordOlChiki: 'ᱟᱹᱛᱩ',
      wordLatin: 'Atu',
      meaning: 'Village',
      category: 'daily',
      order: 18,
    ),
    WordModel(
      id: 'w19',
      wordOlChiki: 'ᱴᱟᱠᱟ',
      wordLatin: 'Taka',
      meaning: 'Money',
      category: 'daily',
      order: 19,
    ),

    // ── Colors (colors) ──
    WordModel(
      id: 'w20',
      wordOlChiki: 'ᱟᱨᱟᱜ',
      wordLatin: 'Arag',
      meaning: 'Red',
      category: 'colors',
      order: 20,
    ),
    WordModel(
      id: 'w21',
      wordOlChiki: 'ᱥᱟᱥᱟᱝ',
      wordLatin: 'Sasang',
      meaning: 'Yellow',
      category: 'colors',
      order: 21,
    ),
    WordModel(
      id: 'w22',
      wordOlChiki: 'ᱦᱟᱹᱨᱭᱟᱹᱲ',
      wordLatin: 'Haryar',
      meaning: 'Green',
      category: 'colors',
      order: 22,
    ),
    WordModel(
      id: 'w23',
      wordOlChiki: 'ᱯᱩᱸᱰ',
      wordLatin: 'Pund',
      meaning: 'White',
      category: 'colors',
      order: 23,
    ),
    WordModel(
      id: 'w24',
      wordOlChiki: 'ᱦᱮᱱᱫᱮ',
      wordLatin: 'Hende',
      meaning: 'Black',
      category: 'colors',
      order: 24,
    ),
    WordModel(
      id: 'w25',
      wordOlChiki: 'ᱞᱤᱞ',
      wordLatin: 'Lil',
      meaning: 'Blue',
      category: 'colors',
      order: 25,
    ),

    // ── Animals & Nature (nature) ──
    WordModel(
      id: 'w26',
      wordOlChiki: 'ᱥᱮᱛᱟ',
      wordLatin: 'Seta',
      meaning: 'Dog',
      category: 'nature',
      order: 26,
    ),
    WordModel(
      id: 'w27',
      wordOlChiki: 'ᱯᱩᱥᱤ',
      wordLatin: 'Pusi',
      meaning: 'Cat',
      category: 'nature',
      order: 27,
    ),
    WordModel(
      id: 'w28',
      wordOlChiki: 'ᱢᱮᱨᱳᱢ',
      wordLatin: 'Merom',
      meaning: 'Goat',
      category: 'nature',
      order: 28,
    ),
    WordModel(
      id: 'w29',
      wordOlChiki: 'ᱜᱟᱹᱭ',
      wordLatin: 'Gai',
      meaning: 'Cow',
      category: 'nature',
      order: 29,
    ),
    WordModel(
      id: 'w30',
      wordOlChiki: 'ᱛᱟᱹᱨᱩᱵ',
      wordLatin: 'Tarub',
      meaning: 'Tiger',
      category: 'nature',
      order: 30,
    ),
    WordModel(
      id: 'w31',
      wordOlChiki: 'ᱪᱮᱬᱮ',
      wordLatin: 'Cene',
      meaning: 'Bird',
      category: 'nature',
      order: 31,
    ),
    WordModel(
      id: 'w32',
      wordOlChiki: 'ᱦᱟᱹᱠᱩ',
      wordLatin: 'Haku',
      meaning: 'Fish',
      category: 'nature',
      order: 32,
    ),
    WordModel(
      id: 'w33',
      wordOlChiki: 'ᱫᱟᱨᱮ',
      wordLatin: 'Dare',
      meaning: 'Tree',
      category: 'nature',
      order: 33,
    ),
    WordModel(
      id: 'w34',
      wordOlChiki: 'ᱵᱟᱦᱟ',
      wordLatin: 'Baha',
      meaning: 'Flower',
      category: 'nature',
      order: 34,
    ),
    WordModel(
      id: 'w35',
      wordOlChiki: 'ᱥᱤᱧ',
      wordLatin: 'Sing',
      meaning: 'Sun',
      category: 'nature',
      order: 35,
    ),
    WordModel(
      id: 'w36',
      wordOlChiki: 'ᱤᱯᱤᱞ',
      wordLatin: 'Ipil',
      meaning: 'Star',
      category: 'nature',
      order: 36,
    ),

    // ── Months, Days & Seasons (time) ──
    WordModel(
      id: 'w37',
      wordOlChiki: 'ᱪᱟᱸᱫᱚ',
      wordLatin: 'Chando',
      meaning: 'Month / Moon',
      category: 'time',
      order: 37,
    ),
    WordModel(
      id: 'w38',
      wordOlChiki: 'ᱢᱟᱦᱟ',
      wordLatin: 'Maha',
      meaning: 'Day',
      category: 'time',
      order: 38,
    ),
    WordModel(
      id: 'w39',
      wordOlChiki: 'ᱛᱮᱦᱮᱧ',
      wordLatin: 'Tehenj',
      meaning: 'Today',
      category: 'time',
      order: 39,
    ),
    WordModel(
      id: 'w40',
      wordOlChiki: 'ᱜᱟᱯᱟ',
      wordLatin: 'Gapa',
      meaning: 'Tomorrow',
      category: 'time',
      order: 40,
    ),
    WordModel(
      id: 'w41',
      wordOlChiki: 'ᱦᱚᱞᱟ',
      wordLatin: 'Hola',
      meaning: 'Yesterday',
      category: 'time',
      order: 41,
    ),
    WordModel(
      id: 'w42',
      wordOlChiki: 'ᱥᱤᱛᱩᱝ ᱨᱤᱛᱩ',
      wordLatin: 'Situng ritu',
      meaning: 'Summer',
      category: 'time',
      order: 42,
    ),
    WordModel(
      id: 'w43',
      wordOlChiki: 'ᱫᱟᱜ ᱨᱤᱛᱩ',
      wordLatin: 'Dag ritu',
      meaning: 'Rainy Season',
      category: 'time',
      order: 43,
    ),

    // ── Trending & Popular (trending) ──
    WordModel(
      id: 'w44',
      wordOlChiki: 'ᱯᱟᱹᱨᱥᱤ',
      wordLatin: 'Parsi',
      meaning: 'Language',
      category: 'trending',
      order: 44,
    ),
    WordModel(
      id: 'w45',
      wordOlChiki: 'ᱥᱟᱱᱛᱟᱲᱤ',
      wordLatin: 'Santali',
      meaning: 'Santali',
      category: 'trending',
      order: 45,
    ),
    WordModel(
      id: 'w46',
      wordOlChiki: 'ᱚᱞ ᱪᱤᱠᱤ',
      wordLatin: 'Ol Chiki',
      meaning: 'Ol Chiki Script',
      category: 'trending',
      order: 46,
    ),
    WordModel(
      id: 'w47',
      wordOlChiki: 'ᱯᱩᱛᱷᱤ',
      wordLatin: 'Puthi',
      meaning: 'Book',
      category: 'trending',
      order: 47,
    ),
    WordModel(
      id: 'w48',
      wordOlChiki: 'ᱤᱛᱩᱱ ᱟᱥᱲᱟ',
      wordLatin: 'Itun asra',
      meaning: 'School',
      category: 'trending',
      order: 48,
    ),
    WordModel(
      id: 'w49',
      wordOlChiki: 'ᱫᱤᱥᱚᱢ',
      wordLatin: 'Disom',
      meaning: 'Country',
      category: 'trending',
      order: 49,
    ),
    WordModel(
      id: 'w50',
      wordOlChiki: 'ᱦᱚᱲ',
      wordLatin: 'Hor',
      meaning: 'People',
      category: 'trending',
      order: 50,
    ),

    // ── Additional Body Parts (body) ──
    WordModel(
      id: 'w51',
      wordOlChiki: 'ᱵᱚᱦᱚᱜ',
      wordLatin: 'Bohog',
      meaning: 'Head',
      category: 'body',
      order: 51,
    ),
    WordModel(
      id: 'w52',
      wordOlChiki: 'ᱤᱞ',
      wordLatin: 'Il',
      meaning: 'Feather',
      category: 'body',
      order: 52,
    ),
    WordModel(
      id: 'w53',
      wordOlChiki: 'ᱚᱞᱚᱝ',
      wordLatin: 'Olong',
      meaning: 'Forehead',
      category: 'body',
      order: 53,
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
