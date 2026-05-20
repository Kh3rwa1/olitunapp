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
  SentencesNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadSentences();
  }

  final Ref ref;

  static final List<SentenceModel> _seedSentences = [
    // ── Basics (basics) ──
    SentenceModel(
      id: 's1',
      sentenceOlChiki: 'ᱟᱢᱟᱜ ᱧᱩᱛᱩᱢ ᱪᱮᱫ?',
      sentenceLatin: 'Amaak nyutum ced?',
      meaning: 'What is your name?',
      pronunciation: 'A-maag nyu-tum ched?',
      category: 'basics',
      order: 1,
    ),
    SentenceModel(
      id: 's2',
      sentenceOlChiki: 'ᱤᱧᱟᱜ ᱧᱩᱛᱩᱢ ᱫᱚ ᱥᱟᱱᱛᱷᱟᱞ',
      sentenceLatin: 'Injaak nyutum do Santhal',
      meaning: 'My name is Santhal',
      pronunciation: 'In-jaag nyu-tum do San-thal',
      category: 'basics',
      order: 2,
    ),
    SentenceModel(
      id: 's3',
      sentenceOlChiki: 'ᱟᱢ ᱫᱚ ᱚᱠᱟᱛᱮᱢ ᱪᱟᱞᱟᱜ ᱠᱟᱱᱟ?',
      sentenceLatin: 'Am do okatem chalag kana?',
      meaning: 'Where are you going?',
      pronunciation: 'Am do o-ka-tem cha-lag ka-na?',
      category: 'basics',
      order: 3,
    ),
    SentenceModel(
      id: 's4',
      sentenceOlChiki: 'ᱟᱢ ᱫᱚ ᱚᱠᱟᱨᱮᱢ ᱛᱟᱦᱮᱸᱱᱟ?',
      sentenceLatin: 'Am do okarem tahena?',
      meaning: 'Where do you live?',
      pronunciation: 'Am do o-ka-rem ta-hen-a?',
      category: 'basics',
      order: 4,
    ),
    SentenceModel(
      id: 's5',
      sentenceOlChiki: 'ᱤᱧ ᱫᱚ ᱱᱚᱸᱰᱮᱧ ᱛᱟᱦᱮᱸᱱᱟ',
      sentenceLatin: 'In do nondenj tahena',
      meaning: 'I live here',
      pronunciation: 'In do non-denj ta-hen-a',
      category: 'basics',
      order: 5,
    ),

    // ── Daily Conversations (conversations) ──
    SentenceModel(
      id: 's6',
      sentenceOlChiki: 'ᱤᱧ ᱨᱮᱸᱜᱮᱡ ᱮᱫ ᱤᱧᱟ',
      sentenceLatin: 'In rengej ed inja',
      meaning: 'I am hungry',
      pronunciation: 'In ren-gej ed in-ja',
      category: 'conversations',
      order: 6,
    ),
    SentenceModel(
      id: 's7',
      sentenceOlChiki: 'ᱫᱟᱠᱟ ᱡᱚᱢ ᱢᱮ',
      sentenceLatin: 'Daka jom me',
      meaning: 'Please eat food',
      pronunciation: 'Da-ka jom me',
      category: 'conversations',
      order: 7,
    ),
    SentenceModel(
      id: 's8',
      sentenceOlChiki: 'ᱫᱟᱜ ᱧᱩ ᱢᱮ',
      sentenceLatin: 'Dag nju me',
      meaning: 'Please drink water',
      pronunciation: 'Dag nyu me',
      category: 'conversations',
      order: 8,
    ),
    SentenceModel(
      id: 's9',
      sentenceOlChiki: 'ᱤᱧ ᱯᱟᱲᱦᱟᱜ ᱠᱟᱱᱟᱧ',
      sentenceLatin: 'In parhaag kananj',
      meaning: 'I am studying',
      pronunciation: 'In par-haag ka-nanj',
      category: 'conversations',
      order: 9,
    ),
    SentenceModel(
      id: 's10',
      sentenceOlChiki: 'ᱟᱢ ᱪᱮᱫ ᱮᱢ ᱪᱤᱠᱟᱹᱭᱮᱫᱟ?',
      sentenceLatin: 'Am ced em cikayeda?',
      meaning: 'What are you doing?',
      pronunciation: 'Am ched em chi-kay-e-da?',
      category: 'conversations',
      order: 10,
    ),
    SentenceModel(
      id: 's11',
      sentenceOlChiki: 'ᱤᱧ ᱫᱚ ᱠᱟᱹᱢᱤᱭᱮᱫᱟᱧ',
      sentenceLatin: 'In do kamiyedanj',
      meaning: 'I am working',
      pronunciation: 'In do ka-mi-yed-anj',
      category: 'conversations',
      order: 11,
    ),

    // ── Greetings & Politeness (polite) ──
    SentenceModel(
      id: 's12',
      sentenceOlChiki: 'ᱟᱢ ᱪᱮᱞᱮᱠᱟ ᱢᱮᱱᱟᱢᱟ?',
      sentenceLatin: 'Am celeka menama?',
      meaning: 'Hello, how are you?',
      pronunciation: 'Am che-le-ka me-na-ma?',
      category: 'polite',
      order: 12,
    ),
    SentenceModel(
      id: 's13',
      sentenceOlChiki: 'ᱤᱧ ᱱᱟᱯᱟᱭ ᱜᱮ ᱢᱮᱱᱟᱧᱟ',
      sentenceLatin: 'In napay ge menanja',
      meaning: 'I am fine',
      pronunciation: 'In na-pay ge me-nan-ja',
      category: 'polite',
      order: 13,
    ),
    SentenceModel(
      id: 's14',
      sentenceOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱥᱮᱛᱟᱜ',
      sentenceLatin: 'Sagun setag',
      meaning: 'Good morning',
      pronunciation: 'Sa-gun se-tag',
      category: 'polite',
      order: 14,
    ),
    SentenceModel(
      id: 's15',
      sentenceOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱧᱤᱫᱟᱹ',
      sentenceLatin: 'Sagun njida',
      meaning: 'Good night',
      pronunciation: 'Sa-gun nyi-da',
      category: 'polite',
      order: 15,
    ),
    SentenceModel(
      id: 's16',
      sentenceOlChiki: 'ᱤᱠᱟᱹ ᱠᱟᱹᱧ ᱢᱮ',
      sentenceLatin: 'Ika kanj me',
      meaning: 'Excuse me / Sorry',
      pronunciation: 'I-ka kanj me',
      category: 'polite',
      order: 16,
    ),
    SentenceModel(
      id: 's17',
      sentenceOlChiki: 'ᱱᱟᱯᱟᱭ ᱛᱮ ᱛᱟᱦᱮᱸᱱ ᱢᱮ',
      sentenceLatin: 'Napay te tahen me',
      meaning: 'Take care',
      pronunciation: 'Na-pay te ta-hen me',
      category: 'polite',
      order: 17,
    ),
    SentenceModel(
      id: 's18',
      sentenceOlChiki: 'ᱫᱟᱭᱟ ᱠᱟᱛᱮ ᱫᱩᱲᱩᱵ ᱢᱮ',
      sentenceLatin: 'Daya kate durub me',
      meaning: 'Please sit down',
      pronunciation: 'Da-ya ka-te du-rub me',
      category: 'polite',
      order: 18,
    ),

    // ── Time & Weather (time_weather) ──
    SentenceModel(
      id: 's19',
      sentenceOlChiki: 'ᱛᱮᱦᱮᱧ ᱫᱚ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱫᱤᱱ ᱠᱟᱱᱟ',
      sentenceLatin: 'Tehenj do adi napay din kana',
      meaning: 'Today is a beautiful day',
      pronunciation: 'Te-henj do a-di na-pay din ka-na',
      category: 'time_weather',
      order: 19,
    ),
    SentenceModel(
      id: 's20',
      sentenceOlChiki: 'ᱱᱚᱶᱟ ᱫᱚ ᱛᱤᱱᱟᱹᱜ ᱫᱟᱢ ᱠᱟᱱᱟ?',
      sentenceLatin: 'Nowa do tinag dam kana?',
      meaning: 'How much is this?',
      pronunciation: 'No-wa do ti-nag dam ka-na?',
      category: 'time_weather',
      order: 20,
    ),
    SentenceModel(
      id: 's21',
      sentenceOlChiki: 'ᱫᱟᱜ ᱮ ᱡᱟᱹᱲᱤᱭᱮᱫᱟ',
      sentenceLatin: 'Dag e jariyeda',
      meaning: 'It is raining',
      pronunciation: 'Dag e ja-ri-ye-da',
      category: 'time_weather',
      order: 21,
    ),
    SentenceModel(
      id: 's22',
      sentenceOlChiki: 'ᱛᱮᱦᱮᱧ ᱫᱚ ᱟᱹᱰᱤ ᱥᱤᱛᱩᱝ ᱠᱟᱱᱟ',
      sentenceLatin: 'Tehenj do adi situng kana',
      meaning: 'It is very hot today',
      pronunciation: 'Te-henj do a-di si-tung ka-na',
      category: 'time_weather',
      order: 22,
    ),
    SentenceModel(
      id: 's23',
      sentenceOlChiki: 'ᱛᱤᱱᱟᱹᱜ ᱵᱟᱡᱟᱣ ᱮᱱᱟ?',
      sentenceLatin: 'Tinag bajaw ena?',
      meaning: 'What time is it?',
      pronunciation: 'Ti-nag ba-jaw e-na?',
      category: 'time_weather',
      order: 23,
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
