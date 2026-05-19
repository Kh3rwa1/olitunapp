import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/appwrite_db_service.dart';
import '../../core/storage/hive_service.dart';
import '../../core/storage/cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/content_models.dart';

final quizzesProvider =
    StateNotifierProvider<QuizzesNotifier, AsyncValue<List<QuizModel>>>(
      QuizzesNotifier.new,
    );

class QuizzesNotifier extends StateNotifier<AsyncValue<List<QuizModel>>> {
  QuizzesNotifier(this.ref) : super(AsyncValue.data(_defaultQuizzes)) {
    _loadQuizzes();
  }

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  final Ref ref;
  static const String _collectionId = 'quizzes';
  static const String _cacheKey = 'cached_quizzes';
  static const String _legacyCacheKey = 'quizzes';

  static final List<QuizModel> _defaultQuizzes = [
    QuizModel(
      id: 'quiz_alphabets_basics',
      categoryId: 'alphabets',
      title: 'Alphabet Basics',
      questions: [
        QuizQuestion(
          promptOlChiki: 'ᱚ',
          promptLatin: 'Which sound does this letter make?',
          optionsOlChiki: ['a', 'i', 'u', 'o'],
          optionsLatin: ['a', 'i', 'u', 'o'],
        ),
        QuizQuestion(
          promptOlChiki: 'ᱛ',
          promptLatin: 'Identify this consonant:',
          optionsOlChiki: ['at', 'ag', 'al', 'ak'],
          optionsLatin: ['at', 'ag', 'al', 'ak'],
        ),
      ],
    ),
    QuizModel(
      id: 'quiz_numbers_arithmetic',
      categoryId: 'numbers',
      title: 'Arithmetic Mastery',
      order: 1,
      questions: [
        QuizQuestion(
          promptOlChiki: '᱒ + ᱓ = ?',
          promptLatin: 'What is the sum of ᱒ (2) and ᱓ (3)?',
          optionsOlChiki: ['᱔', '᱕', '᱖', '᱗'],
          optionsLatin: ['᱔ (4)', '᱕ (5)', '᱖ (6)', '᱗ (7)'],
          correctIndex: 1,
        ),
        QuizQuestion(
          promptOlChiki: '᱙ - ᱕ = ?',
          promptLatin: 'What is the result of ᱙ (9) minus ᱕ (5)?',
          optionsOlChiki: ['᱓', '᱔', '᱕', '᱐'],
          optionsLatin: ['᱓ (3)', '᱔ (4)', '᱕ (5)', '᱐ (0)'],
          correctIndex: 1,
        ),
        QuizQuestion(
          promptOlChiki: '᱓ × ᱓ = ?',
          promptLatin: 'What is the product of ᱓ (3) multiplied by ᱓ (3)?',
          optionsOlChiki: ['᱖', '᱗', '᱘', '᱙'],
          optionsLatin: ['᱖ (6)', '᱗ (7)', '᱘ (8)', '᱙ (9)'],
          correctIndex: 3,
        ),
        QuizQuestion(
          promptOlChiki: '᱘ ÷ ᱒ = ?',
          promptLatin: 'What is the result of ᱘ (8) divided by ᱒ (2)?',
          optionsOlChiki: ['᱒', '᱓', '᱔', '᱕'],
          optionsLatin: ['᱒ (2)', ' (3)', '᱔ (4)', '᱕ (5)'],
          correctIndex: 2,
        ),
      ],
    ),
    QuizModel(
      id: 'quiz_vocabulary_fill_blank',
      categoryId: 'cat_vocab',
      title: 'Sentence',
      order: 2,
      questions: [
        QuizQuestion(
          type: 'fill_blank',
          promptOlChiki: 'Fill in the blank:',
          promptLatin:
              'Choose the word that means "dog" to complete the sentence.',
          optionsOlChiki: ['ᱥᱮᱛᱟ', 'ᱢᱮᱨᱳᱢ', 'ᱟᱨᱟᱜ', 'ᱥᱟᱥᱟᱝ'],
          optionsLatin: [
            'ᱥᱮᱛᱟ (Dog)',
            'ᱢᱮᱨᱳᱢ (Cat)',
            'ᱟᱨᱟᱜ (Red)',
            'ᱥᱟᱥᱟᱝ (Green)',
          ],
          blankSentenceOlChiki: 'ᱤᱧ ᱢᱤᱫ ___ ᱢᱮᱱᱟᱜᱼᱤᱧᱟ ᱾',
          blankSentenceLatin: 'I have a dog.',
          correctAnswer: 'ᱥᱮᱛᱟ',
        ),
        QuizQuestion(
          type: 'fill_blank',
          promptOlChiki: 'Fill in the blank:',
          promptLatin:
              'Choose the correct relationship word to complete the sentence.',
          optionsOlChiki: ['ᱟᱭᱳ', 'ᱵᱟᱵᱟ', 'ᱫᱟᱫᱟ', 'ᱫᱟᱹᱭ'],
          optionsLatin: [
            'ᱟᱭᱳ (Mother)',
            'ᱵᱟᱵᱟ (Father)',
            'ᱫᱟᱫᱟ (Elder Brother)',
            'ᱫᱟᱹᱭ (Elder Sister)',
          ],
          correctIndex: 1,
          blankSentenceOlChiki: 'ᱱᱩᱭ ᱫᱚ ᱤᱧᱤᱡ ___ ᱠᱟᱱᱟᱭ ᱾',
          blankSentenceLatin: 'He is my father.',
          correctAnswer: 'ᱵᱟᱵᱟ',
        ),
        QuizQuestion(
          type: 'fill_blank',
          promptOlChiki: 'Fill in the blank:',
          promptLatin: 'Complete the color statement.',
          optionsOlChiki: ['ᱦᱮᱱᱫᱮ', 'ᱯᱩᱱᱫ', 'ᱟᱨᱟᱜ', 'ᱥᱟᱥᱟᱝ'],
          optionsLatin: [
            'ᱦᱮᱱᱫᱮ (Black)',
            'ᱯᱩᱱᱫ (White)',
            'ᱟᱨᱟᱜ (Red)',
            'ᱥᱟᱥᱟᱝ (Green)',
          ],
          correctIndex: 2,
          blankSentenceOlChiki: 'ᱡᱮᱞᱮᱠᱟ ᱢᱟᱭᱟᱢ ᱫᱚ ___ ᱜᱮᱭᱟ ᱾',
          blankSentenceLatin: 'For example, blood is red.',
          correctAnswer: 'ᱟᱨᱟᱜ',
        ),
      ],
    ),
  ];

  Future<void> _loadQuizzes() async {
    try {
      final cached = await CacheService.getList<QuizModel>(
        _cacheKey,
        QuizModel.fromJson,
      );
      if (cached != null && cached.isNotEmpty) {
        state = AsyncValue.data(cached);
      } else {
        // Migration from SharedPreferences
        final stored =
            _prefs.getString(_cacheKey) ?? _prefs.getString(_legacyCacheKey);
        if (stored != null) {
          final List<dynamic> decoded = jsonDecode(stored);
          final cachedQuizzes = decoded
              .map((e) => QuizModel.fromJson(e))
              .toList();
          state = AsyncValue.data(cachedQuizzes);
          await _saveQuizzes(cachedQuizzes);
          _prefs.remove(_legacyCacheKey);
          _prefs.remove(_cacheKey);
        }
      }
    } catch (e) {
      debugPrint('Failed to load cached quizzes: $e');
    }

    try {
      final db = ref.read(appwriteDbServiceProvider);
      final data = await db.listDocuments(
        _collectionId,
        queries: [Query.orderAsc('order'), Query.limit(500)],
      );
      final quizzes = data.map(QuizModel.fromJson).toList();
      if (quizzes.isNotEmpty) {
        state = AsyncValue.data(quizzes);
        await _saveQuizzes(quizzes);
      } else if (!(state.value?.isNotEmpty ?? false)) {
        state = AsyncValue.data(_defaultQuizzes);
        await _saveQuizzes(_defaultQuizzes);
      }
    } catch (e, stack) {
      if (e is AppwriteException && e.code == 404) {
        debugPrint(
          'Quizzes collection ("$_collectionId") not found in Appwrite. '
          'Default quizzes will be used. Please run the setup script if this is a new project.',
        );
      } else {
        debugPrint('Failed to load quizzes from Appwrite: $e');
      }
      if (!(state.value?.isNotEmpty ?? false)) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  Future<void> _saveQuizzes(List<QuizModel> quizzes) async {
    final data = quizzes.map((e) => e.toJson()).toList();
    await CacheService.set(_cacheKey, data);
  }

  Map<String, dynamic> _toAppwritePayload(QuizModel quiz) {
    final payload = Map<String, dynamic>.from(quiz.toJson())..remove('id');
    payload['questions'] = jsonEncode(
      quiz.questions.map((q) => q.toMap()).toList(),
    );
    payload.removeWhere((key, value) => value == null);
    return payload;
  }

  Future<void> add(QuizModel item) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.createDocument(_collectionId, item.id, _toAppwritePayload(item));
      await _loadQuizzes();
    } catch (e) {
      debugPrint('add quiz failed: $e');
      rethrow;
    }
  }

  Future<void> update(QuizModel item) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.updateDocument(_collectionId, item.id, _toAppwritePayload(item));
      await _loadQuizzes();
    } catch (e) {
      debugPrint('update quiz failed: $e');
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.deleteDocument(_collectionId, id);
      await _loadQuizzes();
    } catch (e) {
      debugPrint('delete quiz failed: $e');
      rethrow;
    }
  }

  Future<void> addQuiz(QuizModel item) async => add(item);
  Future<void> updateQuiz(QuizModel item) async => update(item);
  Future<void> deleteQuiz(String id) async => delete(id);

  Future<void> seedToAppwrite() async {
    state = const AsyncValue.loading();
    try {
      final db = ref.read(appwriteDbServiceProvider);

      final data = await db.listDocuments(
        _collectionId,
        queries: [Query.limit(500)],
      );
      final existingIds = data.map((doc) => doc['\$id'] as String).toSet();

      int seededCount = 0;
      for (final quiz in _defaultQuizzes) {
        if (!existingIds.contains(quiz.id)) {
          await db.createDocument(
            _collectionId,
            quiz.id,
            _toAppwritePayload(quiz),
          );
          seededCount++;
        }
      }
      debugPrint('Seeded $seededCount new quizzes to Appwrite.');
      await _loadQuizzes();
    } catch (e, stack) {
      debugPrint('Failed to seed default quizzes to Appwrite: $e');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> seed() async {
    state = const AsyncValue.loading();
    await CacheService.delete(_cacheKey);
    await _loadQuizzes();
  }
}
