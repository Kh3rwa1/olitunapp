import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/appwrite_db_service.dart';
import '../../core/storage/hive_service.dart';
import '../models/content_models.dart';

final quizzesProvider =
    StateNotifierProvider<QuizzesNotifier, AsyncValue<List<QuizModel>>>(
      QuizzesNotifier.new,
    );

class QuizzesNotifier extends StateNotifier<AsyncValue<List<QuizModel>>> {
  QuizzesNotifier(this.ref) : super(AsyncValue.data(_defaultQuizzes)) {
    _loadQuizzes();
  }

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
          correctIndex: 0,
        ),
        QuizQuestion(
          promptOlChiki: 'ᱛ',
          promptLatin: 'Identify this consonant:',
          optionsOlChiki: ['at', 'ag', 'al', 'ak'],
          optionsLatin: ['at', 'ag', 'al', 'ak'],
          correctIndex: 0,
        ),
      ],
    ),
    QuizModel(
      id: 'quiz_numbers_1to10',
      categoryId: 'numbers',
      title: 'Numbers 1-10',
      order: 1,
      questions: [
        QuizQuestion(
          promptOlChiki: '᱑',
          promptLatin: 'What number is this?',
          optionsOlChiki: ['1', '2', '3', '4'],
          optionsLatin: ['One', 'Two', 'Three', 'Four'],
          correctIndex: 0,
        ),
        QuizQuestion(
          promptOlChiki: '᱕',
          promptLatin: 'Identify this number:',
          optionsOlChiki: ['3', '4', '5', '6'],
          optionsLatin: ['Three', 'Four', 'Five', 'Six'],
          correctIndex: 2,
        ),
      ],
    ),
    QuizModel(
      id: 'quiz_vowels',
      categoryId: 'alphabets',
      title: 'Master the Vowels',
      level: 'intermediate',
      order: 2,
      passingScore: 80,
      questions: [
        QuizQuestion(
          promptOlChiki: 'ᱤ',
          promptLatin: 'This is the vowel for:',
          optionsOlChiki: ['a', 'i', 'u', 'e'],
          optionsLatin: ['a', 'i', 'u', 'e'],
          correctIndex: 1,
        ),
        QuizQuestion(
          promptOlChiki: 'ᱩ',
          promptLatin: 'Identify this vowel sound:',
          optionsOlChiki: ['a', 'i', 'u', 'o'],
          optionsLatin: ['a', 'i', 'u', 'o'],
          correctIndex: 2,
        ),
      ],
    ),
  ];

  Future<void> _loadQuizzes() async {
    try {
      final stored =
          prefs.getString(_cacheKey) ?? prefs.getString(_legacyCacheKey);
      if (stored != null) {
        final List<dynamic> decoded = jsonDecode(stored);
        final cachedQuizzes = decoded
            .map((e) => QuizModel.fromJson(e))
            .toList();
        state = AsyncValue.data(cachedQuizzes);
        _saveQuizzes(cachedQuizzes);
        prefs.remove(_legacyCacheKey);
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
        _saveQuizzes(quizzes);
      } else if (!(state.value?.isNotEmpty ?? false)) {
        state = AsyncValue.data(_defaultQuizzes);
        _saveQuizzes(_defaultQuizzes);
      }
    } catch (e, stack) {
      debugPrint('Failed to load quizzes from Appwrite: $e');
      if (!(state.value?.isNotEmpty ?? false)) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  void _saveQuizzes(List<QuizModel> quizzes) {
    final encoded = jsonEncode(quizzes.map((e) => e.toJson()).toList());
    prefs.setString(_cacheKey, encoded);
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

  Future<void> seed() async {
    state = const AsyncValue.loading();
    prefs.remove(_cacheKey);
    await _loadQuizzes();
  }
}
