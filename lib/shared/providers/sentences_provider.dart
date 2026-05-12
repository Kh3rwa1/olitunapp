import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/appwrite_db_service.dart';
import '../models/content_models.dart';

final sentencesProvider =
    StateNotifierProvider<SentencesNotifier, AsyncValue<List<SentenceModel>>>(
      SentencesNotifier.new,
    );

class SentencesNotifier extends StateNotifier<AsyncValue<List<SentenceModel>>> {
  SentencesNotifier(this.ref) : super(AsyncValue.data(_seedSentences)) {
    _loadSentences();
  }

  final Ref ref;

  static final List<SentenceModel> _seedSentences = [
    // ── Greetings ──
    SentenceModel(
      id: 's1',
      sentenceOlChiki: 'ᱡᱚᱦᱟᱨ, ᱟᱢ ᱫᱚ ᱪᱮᱫ ᱧᱩᱛᱩᱢ ᱠᱟᱱᱟ?',
      sentenceLatin: 'Johar, am do ced nyutum kana?',
      meaning: 'Hello, how are you?',
      pronunciation: 'Jo-har, am do ched nyu-tum ka-na?',
      category: 'Greeting',
    ),
    SentenceModel(
      id: 's2',
      sentenceOlChiki: 'ᱤᱧ ᱫᱚ ᱵᱟᱝ ᱧᱩᱛᱩᱢ ᱠᱟᱱᱟ',
      sentenceLatin: 'Ing do bang nyutum kana',
      meaning: 'I am fine',
      pronunciation: 'Ing do bang nyu-tum ka-na',
      category: 'Greeting',
      order: 1,
    ),
    SentenceModel(
      id: 's3',
      sentenceOlChiki: 'ᱥᱟᱨᱦᱟᱣ ᱟᱢ ᱫᱚ',
      sentenceLatin: 'Sarhaw am do',
      meaning: 'Thank you',
      pronunciation: 'Sar-haw am do',
      category: 'Greeting',
      order: 2,
    ),
    SentenceModel(
      id: 's4',
      sentenceOlChiki: 'ᱡᱚᱦᱟᱨ, ᱥᱮᱞᱮᱫ ᱫᱤᱱ!',
      sentenceLatin: 'Johar, seled din!',
      meaning: 'Hello, good morning!',
      pronunciation: 'Jo-har, se-led din',
      category: 'Greeting',
      order: 3,
    ),
    SentenceModel(
      id: 's5',
      sentenceOlChiki: 'ᱟᱡ ᱢᱟ ᱪᱟᱞᱚᱜ ᱠᱟᱱᱟ',
      sentenceLatin: 'Aj ma chalog kana',
      meaning: 'Goodbye / See you later',
      pronunciation: 'Aj ma cha-log ka-na',
      category: 'Greeting',
      order: 4,
    ),
    // ── Introduction ──
    SentenceModel(
      id: 's6',
      sentenceOlChiki: 'ᱤᱧᱟᱜ ᱧᱩᱛᱩᱢ ___',
      sentenceLatin: 'Ingaak nyutum ___',
      meaning: 'My name is ___',
      pronunciation: 'In-gaak nyu-tum',
      category: 'Introduction',
      order: 5,
    ),
    SentenceModel(
      id: 's7',
      sentenceOlChiki: 'ᱟᱢᱟᱜ ᱧᱩᱛᱩᱢ ᱪᱮᱫ?',
      sentenceLatin: 'Amaak nyutum ced?',
      meaning: 'What is your name?',
      pronunciation: 'A-maak nyu-tum ched?',
      category: 'Introduction',
      order: 6,
    ),
    SentenceModel(
      id: 's8',
      sentenceOlChiki: 'ᱤᱧ ᱫᱚ ___ ᱠᱷᱚᱱ ᱦᱤᱡᱩᱜ ᱠᱟᱱᱟ',
      sentenceLatin: 'Ing do ___ khon hijug kana',
      meaning: 'I am from ___',
      pronunciation: 'Ing do... khon hi-jug ka-na',
      category: 'Introduction',
      order: 7,
    ),
    // ── Questions ──
    SentenceModel(
      id: 's9',
      sentenceOlChiki: 'ᱱᱚᱶᱟ ᱫᱚ ᱪᱮᱫ ᱠᱟᱱᱟ?',
      sentenceLatin: 'Nowa do ced kana?',
      meaning: 'What is this?',
      pronunciation: 'No-wa do ched ka-na?',
      category: 'Question',
      order: 8,
    ),
    SentenceModel(
      id: 's10',
      sentenceOlChiki: 'ᱟᱢ ᱫᱚ ᱚᱠᱟ ᱥᱮᱱ ᱠᱟᱱᱟ?',
      sentenceLatin: 'Am do oka sen kana?',
      meaning: 'Where are you going?',
      pronunciation: 'Am do o-ka sen ka-na?',
      category: 'Question',
      order: 9,
    ),
    SentenceModel(
      id: 's11',
      sentenceOlChiki: 'ᱱᱚᱶᱟ ᱫᱚ ᱚᱠᱛᱟ ᱠᱟᱱᱟ?',
      sentenceLatin: 'Nowa do okta kana?',
      meaning: 'How much is this?',
      pronunciation: 'No-wa do ok-ta ka-na?',
      category: 'Question',
      order: 10,
    ),
    SentenceModel(
      id: 's12',
      sentenceOlChiki: 'ᱫᱟᱠ ᱢᱮᱱᱟᱜ ᱟ?',
      sentenceLatin: 'Dak menag a?',
      meaning: 'Can I have some water?',
      pronunciation: 'Dak me-nag a?',
      category: 'Question',
      order: 11,
    ),
    // ── Daily Life ──
    SentenceModel(
      id: 's13',
      sentenceOlChiki: 'ᱤᱧ ᱡᱚᱢ ᱠᱟᱱᱟ',
      sentenceLatin: 'Ing jom kana',
      meaning: 'I am eating',
      pronunciation: 'Ing jom ka-na',
      category: 'Daily',
      order: 12,
    ),
    SentenceModel(
      id: 's14',
      sentenceOlChiki: 'ᱤᱧ ᱥᱮᱱ ᱠᱟᱱᱟ',
      sentenceLatin: 'Ing sen kana',
      meaning: 'I am going',
      pronunciation: 'Ing sen ka-na',
      category: 'Daily',
      order: 13,
    ),
    SentenceModel(
      id: 's15',
      sentenceOlChiki: 'ᱤᱧ ᱯᱟᱲᱦᱟᱣ ᱠᱟᱱᱟ',
      sentenceLatin: 'Ing parhaaw kana',
      meaning: 'I am studying',
      pronunciation: 'Ing par-haaw ka-na',
      category: 'Daily',
      order: 14,
    ),
    SentenceModel(
      id: 's16',
      sentenceOlChiki: 'ᱤᱧ ᱚᱞᱚᱝ ᱥᱮᱱ ᱠᱟᱱᱟ',
      sentenceLatin: 'Ing olong sen kana',
      meaning: 'I am going home',
      pronunciation: 'Ing o-long sen ka-na',
      category: 'Daily',
      order: 15,
    ),
    // ── Polite Expressions ──
    SentenceModel(
      id: 's17',
      sentenceOlChiki: 'ᱫᱟᱭᱟ ᱠᱟᱛᱮ ᱵᱚᱞᱚᱜ ᱢᱮ',
      sentenceLatin: 'Daya kate bolog me',
      meaning: 'Please sit down',
      pronunciation: 'Da-ya ka-te bo-log me',
      category: 'Polite',
      order: 16,
    ),
    SentenceModel(
      id: 's18',
      sentenceOlChiki: 'ᱢᱟᱹᱱᱟᱹᱯ ᱢᱮ',
      sentenceLatin: 'Manap me',
      meaning: 'Excuse me / Sorry',
      pronunciation: 'Ma-nap me',
      category: 'Polite',
      order: 17,
    ),
    // ── Nature ──
    SentenceModel(
      id: 's19',
      sentenceOlChiki: 'ᱫᱟᱨᱮ ᱨᱮ ᱵᱟᱦᱟ ᱵᱟᱦᱟ ᱮᱱᱟ',
      sentenceLatin: 'Dare re baha baha ena',
      meaning: 'The tree is full of flowers',
      pronunciation: 'Da-re re ba-ha ba-ha e-na',
      category: 'Nature',
      order: 18,
    ),
    SentenceModel(
      id: 's20',
      sentenceOlChiki: 'ᱟᱡ ᱫᱤᱱ ᱵᱟᱝ ᱵᱩᱞᱩᱝ ᱠᱟᱱᱟ',
      sentenceLatin: 'Aj din bang bulung kana',
      meaning: 'Today is a beautiful day',
      pronunciation: 'Aj din bang bu-lung ka-na',
      category: 'Nature',
      order: 19,
    ),
  ];

  Future<void> _loadSentences() async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      final data = await db.listDocuments(
        'sentences',
        queries: [Query.orderAsc('order'), Query.limit(500)],
      );
      state = AsyncValue.data(data.map(SentenceModel.fromJson).toList());
    } catch (e) {
      state = AsyncValue.data(_seedSentences);
    }
  }

  Future<void> add(SentenceModel item) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.createDocument('sentences', item.id, item.toJson());
      await _loadSentences();
    } catch (e) {
      debugPrint('❌ add sentence FAILED: $e');
    }
  }

  Future<void> update(SentenceModel item) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.updateDocument('sentences', item.id, item.toJson());
      await _loadSentences();
    } catch (e) {
      debugPrint('❌ update sentence FAILED: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.deleteDocument('sentences', id);
      await _loadSentences();
    } catch (e) {
      debugPrint('❌ delete sentence FAILED: $e');
    }
  }

  Future<void> seed() async {
    for (final item in _seedSentences) {
      try {
        final db = ref.read(appwriteDbServiceProvider);
        await db.createDocument('sentences', item.id, item.toJson());
      } catch (e) {
        debugPrint('Sentence already exists or error: $e');
      }
    }
    await _loadSentences();
  }
}
