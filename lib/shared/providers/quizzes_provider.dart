import 'package:itun/core/logging/app_logger.dart';
import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/appwrite_db_service.dart';
import '../../core/storage/cache_service.dart';
import '../../core/storage/hive_service.dart';
import '../models/content_models.dart';
import '../quiz_engine/quiz_engine.dart';
import 'learner_content_providers.dart';

final quizzesProvider =
    StateNotifierProvider<QuizzesNotifier, AsyncValue<List<QuizModel>>>(
      QuizzesNotifier.new,
    );

class QuizzesNotifier extends StateNotifier<AsyncValue<List<QuizModel>>> {
  QuizzesNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadQuizzes();
    Future.microtask(() {
      if (!mounted) return;
      ref.listen(learnerWordsProvider, (_, _) => _updateDynamicQuizzes());
      ref.listen(learnerSentencesProvider, (_, _) => _updateDynamicQuizzes());
      _updateDynamicQuizzes();
    });
  }

  final Ref ref;

  static const String _collectionId = 'quizzes';
  static const String _cacheKey = 'cached_quizzes';
  static const String _legacyCacheKey = 'quizzes';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  List<QuizModel> _baseQuizzes = [];

  void _updateDynamicQuizzes() {
    if (!mounted) return;

    final words = ref.read(learnerWordsProvider).value;
    final sentences = ref.read(learnerSentencesProvider).value;
    if (words == null || sentences == null) {
      if (_baseQuizzes.isNotEmpty) {
        state = AsyncValue.data(_baseQuizzes);
      }
      return;
    }

    state = AsyncValue.data(
      QuizEngine.compile(
        baseQuizzes: _baseQuizzes,
        words: words,
        sentences: sentences,
      ),
    );
  }

  Future<void> _loadQuizzes() async {
    await _restoreCachedQuizzes();
    if (!mounted) return;

    try {
      final data = await ref
          .read(appwriteDbServiceProvider)
          .listDocuments(
            _collectionId,
            queries: [Query.orderAsc('order'), Query.limit(500)],
          );
      if (!mounted) return;

      final quizzes = data.map(QuizModel.fromJson).toList();
      await _replaceBaseQuizzes(
        quizzes.isNotEmpty ? quizzes : _fallbackIfEmpty(),
      );
    } catch (e) {
      if (!mounted) return;
      if (e is AppwriteException && e.code == 404) {
        AppLogger.debug(
          'Quizzes collection ("$_collectionId") not found in Appwrite. '
          'Default quizzes will be used. Please run the setup script if this is a new project.',
        );
      } else {
        AppLogger.debug('Failed to load quizzes from Appwrite: $e');
      }
      if (_baseQuizzes.isEmpty) {
        await _replaceBaseQuizzes(QuizCatalog.defaultQuizzes);
      }
    }
  }

  Future<void> _restoreCachedQuizzes() async {
    try {
      final cached = await CacheService.getList<QuizModel>(
        _cacheKey,
        QuizModel.fromJson,
      );
      if (!mounted) return;

      if (cached != null && cached.isNotEmpty) {
        _baseQuizzes = cached;
        _updateDynamicQuizzes();
        return;
      }

      final stored =
          _prefs.getString(_cacheKey) ?? _prefs.getString(_legacyCacheKey);
      if (stored == null) return;

      final decoded = jsonDecode(stored) as List<dynamic>;
      final migrated = decoded.map((item) => QuizModel.fromJson(item)).toList();
      await _replaceBaseQuizzes(migrated);
      await _prefs.remove(_legacyCacheKey);
      await _prefs.remove(_cacheKey);
    } catch (e) {
      if (mounted) {
        AppLogger.debug('Failed to load cached quizzes: $e');
      }
    }
  }

  List<QuizModel> _fallbackIfEmpty() {
    return _baseQuizzes.isNotEmpty ? _baseQuizzes : QuizCatalog.defaultQuizzes;
  }

  Future<void> _replaceBaseQuizzes(List<QuizModel> quizzes) async {
    if (!mounted) return;
    _baseQuizzes = quizzes;
    _updateDynamicQuizzes();
    await _saveQuizzes(quizzes);
  }

  Future<void> _saveQuizzes(List<QuizModel> quizzes) async {
    await CacheService.set(
      _cacheKey,
      quizzes.map((quiz) => quiz.toJson()).toList(),
    );
  }

  Map<String, dynamic> _toAppwritePayload(QuizModel quiz) {
    final payload = Map<String, dynamic>.from(quiz.toJson())..remove('id');
    payload['questions'] = jsonEncode(
      quiz.questions.map((question) => question.toMap()).toList(),
    );
    payload.removeWhere((key, value) => value == null);
    return payload;
  }

  Future<void> add(QuizModel item) async {
    final previous = _baseQuizzes;
    await _applyOptimistic([..._baseQuizzes, item]);
    try {
      await ref
          .read(appwriteDbServiceProvider)
          .createDocument(_collectionId, item.id, _toAppwritePayload(item));
    } catch (e) {
      await _applyOptimistic(previous);
      AppLogger.debug('add quiz failed: $e');
      rethrow;
    }
  }

  Future<void> update(QuizModel item) async {
    final previous = _baseQuizzes;
    await _applyOptimistic([
      for (final quiz in _baseQuizzes)
        if (quiz.id == item.id) item else quiz,
    ]);
    try {
      await ref
          .read(appwriteDbServiceProvider)
          .updateDocument(_collectionId, item.id, _toAppwritePayload(item));
    } catch (e) {
      await _applyOptimistic(previous);
      AppLogger.debug('update quiz failed: $e');
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    final previous = _baseQuizzes;
    await _applyOptimistic([
      for (final quiz in _baseQuizzes)
        if (quiz.id != id) quiz,
    ]);
    try {
      await ref
          .read(appwriteDbServiceProvider)
          .deleteDocument(_collectionId, id);
    } catch (e) {
      await _applyOptimistic(previous);
      AppLogger.debug('delete quiz failed: $e');
      rethrow;
    }
  }

  Future<void> _applyOptimistic(List<QuizModel> quizzes) async {
    await _replaceBaseQuizzes(quizzes);
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

      var seededCount = 0;
      for (final quiz in QuizCatalog.defaultQuizzes) {
        if (existingIds.contains(quiz.id)) continue;
        await db.createDocument(
          _collectionId,
          quiz.id,
          _toAppwritePayload(quiz),
        );
        seededCount++;
      }
      AppLogger.debug('Seeded $seededCount new quizzes to Appwrite.');
      await _loadQuizzes();
    } catch (e, stack) {
      AppLogger.debug('Failed to seed default quizzes to Appwrite: $e');
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
