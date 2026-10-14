import 'dart:async';

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/core/logging/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/appwrite_db_service.dart';
import '../../core/api/appwrite_query_builders.dart';
import '../../core/error/appwrite_error_classifier.dart';
import '../../core/storage/cache_service.dart';
import '../../core/storage/hive_service.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/quiz/domain/quiz_identity_validation.dart';
import '../../features/review/domain/review_corpus_identity.dart';
import '../models/content_models.dart';
import '../quiz_engine/quiz_engine.dart';
import 'language_settings_providers.dart';
import 'learner_content_providers.dart';

final quizzesProvider = AsyncNotifierProvider<QuizzesNotifier, List<QuizModel>>(
  QuizzesNotifier.new,
);

final quizzesByIdProvider = Provider<AsyncValue<Map<String, QuizModel>>>((ref) {
  return ref.watch(quizzesProvider).whenData((list) {
    return {for (final q in list) q.id: q};
  });
});

/// Quizzes = stored base quizzes (cache → Appwrite → bundled defaults)
/// compiled together with dynamic quizzes generated from learner words and
/// sentences in the effective teaching language.
class QuizzesNotifier extends AsyncNotifier<List<QuizModel>> {
  static const String _collectionId = 'quizzes';
  static const String _cacheKey = 'cached_quizzes';
  static const String _legacyCacheKey = 'quizzes';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  List<QuizModel> _baseQuizzes = [];

  @override
  FutureOr<List<QuizModel>> build() async {
    // Re-create the notifier when the auth state changes.
    ref.watch(isAuthenticatedProvider);
    var active = true;
    ref.onDispose(() => active = false);
    ref.listen(learnerWordsProvider, (_, _) => _recompile());
    ref.listen(learnerSentencesProvider, (_, _) => _recompile());
    ref.listen(effectiveTeachingLanguageProvider, (_, _) => _recompile());

    final cached = await _restoreCachedQuizzes();
    if (!active) return cached;
    if (cached.isNotEmpty) {
      _baseQuizzes = cached;
      _recompile();
    }

    final remote = await _fetchRemoteQuizzes();
    if (remote != null) {
      _baseQuizzes = remote.isNotEmpty ? remote : _fallbackIfEmpty();
      await _saveQuizzes(_baseQuizzes);
    } else if (_baseQuizzes.isEmpty) {
      _baseQuizzes = QuizCatalog.defaultQuizzes;
      await _saveQuizzes(_baseQuizzes);
    }
    final compiled = _compile();
    if (compiled.hasError) {
      return Future.error(compiled.error!, compiled.stackTrace);
    }
    return compiled.valueOrNull ?? _baseQuizzes;
  }

  /// Compiles base + dynamic quizzes from the learner word/sentence lists.
  ///
  /// Base quizzes are independently valid cached/bundled content: when the
  /// learner lists are loading or failed, the base quizzes alone are served.
  /// Only when there is no base content does a learner-list failure surface
  /// as an error; while they are loading with no base content the result is
  /// [AsyncLoading].
  AsyncValue<List<QuizModel>> _compile() {
    final wordsAsync = ref.read(learnerWordsProvider);
    final sentencesAsync = ref.read(learnerSentencesProvider);
    if (wordsAsync.hasError || sentencesAsync.hasError) {
      if (_baseQuizzes.isNotEmpty) return AsyncValue.data(_baseQuizzes);
      final failed = wordsAsync.hasError ? wordsAsync : sentencesAsync;
      return AsyncValue.error(
        failed.error!,
        failed.stackTrace ?? StackTrace.current,
      );
    }
    final words = wordsAsync.valueOrNull;
    final sentences = sentencesAsync.valueOrNull;
    if (words == null || sentences == null) {
      return _baseQuizzes.isNotEmpty
          ? AsyncValue.data(_baseQuizzes)
          : const AsyncValue.loading();
    }

    return AsyncValue.data(
      QuizEngine.compile(
        baseQuizzes: _baseQuizzes,
        words: words,
        sentences: sentences,
        teachingLanguage: ref.read(effectiveTeachingLanguageProvider),
      ),
    );
  }

  void _recompile() {
    final compiled = _compile();
    if (compiled.isLoading) return;
    state = compiled;
  }

  /// Fetches base quizzes from Appwrite; returns null when unavailable.
  Future<List<QuizModel>?> _fetchRemoteQuizzes() async {
    try {
      final data = await ref
          .read(appwriteDbServiceProvider)
          .listAllDocuments(
            _collectionId,
            queries: [DbQuery.orderAsc('order')],
          );
      return data.map(QuizModel.fromJson).toList();
    } catch (e, stack) {
      if (AppwriteErrorClassifier.infoOf(e)?.code == 404) {
        AppLogger.warning(
          'Quizzes collection ("$_collectionId") not found in Appwrite; '
          'using default quizzes. Run the setup script for new projects.',
          name: 'QuizzesNotifier',
        );
      } else {
        AppLogger.warning(
          'Failed to load quizzes from Appwrite',
          name: 'QuizzesNotifier',
          error: e,
          stackTrace: stack,
        );
      }
      return null;
    }
  }

  Future<List<QuizModel>> _restoreCachedQuizzes() async {
    try {
      final cached = await CacheService.getList<QuizModel>(
        _cacheKey,
        QuizModel.fromJson,
      );
      if (cached != null && cached.isNotEmpty) return cached;

      final stored =
          _prefs.getString(_cacheKey) ?? _prefs.getString(_legacyCacheKey);
      if (stored == null) return const [];

      final decoded = jsonDecode(stored) as List<dynamic>;
      final migrated = decoded.map((item) => QuizModel.fromJson(item)).toList();
      await _saveQuizzes(migrated);
      await _prefs.remove(_legacyCacheKey);
      await _prefs.remove(_cacheKey);
      return migrated;
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to load cached quizzes',
        name: 'QuizzesNotifier',
        error: e,
        stackTrace: stack,
      );
      return const [];
    }
  }

  List<QuizModel> _fallbackIfEmpty() {
    return _baseQuizzes.isNotEmpty ? _baseQuizzes : QuizCatalog.defaultQuizzes;
  }

  Future<void> _replaceBaseQuizzes(List<QuizModel> quizzes) async {
    _baseQuizzes = quizzes;
    _recompile();
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
    _validateForPublish(item);
    final previous = _baseQuizzes;
    await _applyOptimistic([..._baseQuizzes, item]);
    try {
      await ref
          .read(appwriteDbServiceProvider)
          .createDocument(_collectionId, item.id, _toAppwritePayload(item));
    } catch (e, stack) {
      await _applyOptimistic(previous);
      AppLogger.error(
        'Add quiz failed',
        name: 'QuizzesNotifier',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<void> updateItem(QuizModel item) async {
    _validateForPublish(item);
    final previous = _baseQuizzes;
    await _applyOptimistic([
      for (final quiz in _baseQuizzes)
        if (quiz.id == item.id) item else quiz,
    ]);
    try {
      await ref
          .read(appwriteDbServiceProvider)
          .updateDocument(_collectionId, item.id, _toAppwritePayload(item));
    } catch (e, stack) {
      await _applyOptimistic(previous);
      AppLogger.error(
        'Update quiz failed',
        name: 'QuizzesNotifier',
        error: e,
        stackTrace: stack,
      );
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
    } catch (e, stack) {
      await _applyOptimistic(previous);
      AppLogger.error(
        'Delete quiz failed',
        name: 'QuizzesNotifier',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<void> _applyOptimistic(List<QuizModel> quizzes) async {
    await _replaceBaseQuizzes(quizzes);
  }

  Future<void> addQuiz(QuizModel item) async => add(item);
  Future<void> updateQuiz(QuizModel item) async => updateItem(item);
  Future<void> deleteQuiz(String id) async => delete(id);

  /// Publish boundary: blocks invalid new/edited quizzes BEFORE any local
  /// optimistic write or remote mutation. Structural rules (exactly-one
  /// attribution, non-memory exclusivity) always apply. Corpus rules
  /// (existence, alias, tombstone, type) apply against the verified map;
  /// when the map is unavailable publication fails closed with a clear
  /// retry-online error — the UI is never the only enforcement layer.
  void _validateForPublish(QuizModel item) {
    final corpusMap = ref.read(corpusIdentityMapProvider).valueOrNull;
    final errors = validateQuizForPublish(item, corpusMap: corpusMap);
    if (errors.isNotEmpty) {
      final detail = errors.take(5).join(' | ');
      AppLogger.debug('QuizzesNotifier: publish blocked: $detail');
      throw ArgumentError(
        'Quiz "${item.id}" cannot be published with invalid question '
        'identity: $detail${errors.length > 5 ? ' (+${errors.length - 5} more)' : ''}',
      );
    }
  }

  Future<void> seedToAppwrite() async {
    state = const AsyncValue.loading();
    try {
      final db = ref.read(appwriteDbServiceProvider);
      final data = await db.listAllDocuments(_collectionId);
      final existingIds = data.map((doc) => doc['id'] as String).toSet();

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
      ref.invalidateSelf();
      await future;
    } catch (e, stack) {
      AppLogger.error(
        'Failed to seed default quizzes to Appwrite',
        name: 'QuizzesNotifier',
        error: e,
        stackTrace: stack,
      );
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> seed() async {
    await CacheService.delete(_cacheKey);
    ref.invalidateSelf();
    await future;
  }
}
