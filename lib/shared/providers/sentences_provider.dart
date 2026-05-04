import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/appwrite_db_service.dart';
import '../models/content_models.dart';

final sentencesProvider =
    StateNotifierProvider<SentencesNotifier, AsyncValue<List<SentenceModel>>>(
      SentencesNotifier.new,
    );

class SentencesNotifier
    extends StateNotifier<AsyncValue<List<SentenceModel>>> {
  SentencesNotifier(this.ref) : super(AsyncValue.data(_seedSentences)) {
    _loadSentences();
  }

  final Ref ref;

  static final List<SentenceModel> _seedSentences = [
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

  Future<void> seed() async => _loadSentences();
}
