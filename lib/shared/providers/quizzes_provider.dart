import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/appwrite_db_service.dart';
import '../../core/storage/hive_service.dart';
import '../../core/storage/cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/content_models.dart';
import 'words_provider.dart';
import 'sentences_provider.dart';

final quizzesProvider =
    StateNotifierProvider<QuizzesNotifier, AsyncValue<List<QuizModel>>>(
      QuizzesNotifier.new,
    );

class QuizzesNotifier extends StateNotifier<AsyncValue<List<QuizModel>>> {
  QuizzesNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadQuizzes();
    ref.listen(wordsProvider, (_, _) => _updateDynamicQuizzes());
    ref.listen(sentencesProvider, (_, _) => _updateDynamicQuizzes());
  }

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  final Ref ref;
  static const String _collectionId = 'quizzes';
  static const String _cacheKey = 'cached_quizzes';
  static const String _legacyCacheKey = 'quizzes';

  List<QuizModel> _baseQuizzes = [];

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
          optionsOlChiki: ['4', '5', '6', '7'],
          optionsLatin: ['4', '5', '6', '7'],
          correctIndex: 1,
        ),
        QuizQuestion(
          promptOlChiki: '᱙ - ᱕ = ?',
          promptLatin: 'What is the result of ᱙ (9) minus ᱕ (5)?',
          optionsOlChiki: ['3', '4', '5', '0'],
          optionsLatin: ['3', '4', '5', '0'],
          correctIndex: 1,
        ),
        QuizQuestion(
          promptOlChiki: '᱓ × ᱓ = ?',
          promptLatin: 'What is the product of ᱓ (3) multiplied by ᱓ (3)?',
          optionsOlChiki: ['6', '7', '8', '9'],
          optionsLatin: ['6', '7', '8', '9'],
          correctIndex: 3,
        ),
        QuizQuestion(
          promptOlChiki: '᱘ ÷ ᱒ = ?',
          promptLatin: 'What is the result of ᱘ (8) divided by ᱒ (2)?',
          optionsOlChiki: ['2', '3', '4', '5'],
          optionsLatin: ['2', '3', '4', '5'],
          correctIndex: 2,
        ),
      ],
    ),
  ];

  void _updateDynamicQuizzes() {
    if (!mounted) return;
    final wordsAsync = ref.read(wordsProvider);
    final sentencesAsync = ref.read(sentencesProvider);

    if (wordsAsync.value != null && sentencesAsync.value != null) {
      final words = wordsAsync.value!;
      final sentences = sentencesAsync.value!;
      final dynamicQuizzes = _generateDynamicQuizzes(_baseQuizzes, words, sentences);
      state = AsyncValue.data(dynamicQuizzes);
    } else {
      if (_baseQuizzes.isNotEmpty) {
        state = AsyncValue.data(_baseQuizzes);
      }
    }
  }

  List<QuizModel> _generateDynamicQuizzes(
    List<QuizModel> baseQuizzes,
    List<WordModel> words,
    List<SentenceModel> sentences,
  ) {
    final List<QuizModel> compiled = [];

    // Keep non-vocabulary/non-sentence quizzes (e.g. alphabets or numbers)
    for (final q in baseQuizzes) {
      if (q.categoryId != 'cat_vocab' && q.categoryId != 'cat_sentences') {
        compiled.add(q);
      }
    }

    // Add standard defaults if missing from DB/cache
    if (!compiled.any((q) => q.categoryId == 'alphabets')) {
      compiled.addAll(_defaultQuizzes.where((q) => q.categoryId == 'alphabets'));
    }
    if (!compiled.any((q) => q.categoryId == 'numbers')) {
      compiled.addAll(_defaultQuizzes.where((q) => q.categoryId == 'numbers'));
    }

    // Vocabulary Categories mapping
    final vocabSubcats = {
      'basics': {
        'keys': ['greeting', 'basic'],
        'title': 'Greetings & Basics Quiz',
        'level': 'beginner',
        'order': 2
      },
      'family': {
        'keys': ['family'],
        'title': 'Family & Relationships Quiz',
        'level': 'beginner',
        'order': 3
      },
      'daily': {
        'keys': ['daily'],
        'title': 'Daily Use Words Quiz',
        'level': 'intermediate',
        'order': 4
      },
      'colors': {
        'keys': ['colors'],
        'title': 'Colors Quiz',
        'level': 'beginner',
        'order': 5
      },
      'nature': {
        'keys': ['nature'],
        'title': 'Animals & Nature Quiz',
        'level': 'intermediate',
        'order': 6
      },
      'time': {
        'keys': ['time'],
        'title': 'Months & Seasons Quiz',
        'level': 'advanced',
        'order': 7
      },
      'trending': {
        'keys': ['trending'],
        'title': 'Trending Words Quiz',
        'level': 'advanced',
        'order': 8
      },
      'body': {
        'keys': ['body'],
        'title': 'Body Parts Quiz',
        'level': 'intermediate',
        'order': 9
      },
    };

    vocabSubcats.forEach((subKey, info) {
      final keys = info['keys'] as List<String>;
      final title = info['title'] as String;
      final level = info['level'] as String;
      final order = info['order'] as int;

      final catWords = words.where((w) => keys.contains(w.category)).toList();
      if (catWords.isNotEmpty) {
        final List<QuizQuestion> questions = [];
        final shuffledWords = List<WordModel>.from(catWords)..shuffle();
        final targetWords = shuffledWords.take(10).toList();

        for (final w in targetWords) {
          final distractors = _getWordDistractors(w, words);
          final options = [w, ...distractors];
          options.shuffle();
          final correctIndex = options.indexOf(w);

          questions.add(QuizQuestion(
            promptOlChiki: w.wordOlChiki,
            promptLatin: 'Choose the correct English meaning for this word.',
            optionsOlChiki: options.map((o) => o.wordOlChiki).toList(),
            optionsLatin: options.map((o) => '${o.wordOlChiki} (${o.meaning})').toList(),
            correctIndex: correctIndex,
          ));
        }

        compiled.add(QuizModel(
          id: 'quiz_dynamic_vocab_$subKey',
          categoryId: 'cat_vocab',
          title: title,
          level: level,
          order: order,
          questions: questions,
        ));
      }
    });

    // Sentence Categories mapping
    final sentenceSubcats = {
      'basics': {
        'key': 'basics',
        'title': 'Basic Sentences Quiz',
        'level': 'beginner',
        'order': 10
      },
      'conversations': {
        'key': 'conversations',
        'title': 'Daily Conversations Quiz',
        'level': 'intermediate',
        'order': 11
      },
      'polite': {
        'key': 'polite',
        'title': 'Greetings & Politeness Quiz',
        'level': 'beginner',
        'order': 12
      },
      'time_weather': {
        'key': 'time_weather',
        'title': 'Time & Weather Quiz',
        'level': 'advanced',
        'order': 13
      },
    };

    sentenceSubcats.forEach((subKey, info) {
      final key = info['key'] as String;
      final title = info['title'] as String;
      final level = info['level'] as String;
      final order = info['order'] as int;

      final catSentences = sentences.where((s) => s.category == key).toList();
      if (catSentences.isNotEmpty) {
        final questions = _generateSentenceQuestions(catSentences, words);
        if (questions.isNotEmpty) {
          compiled.add(QuizModel(
            id: 'quiz_dynamic_sentences_$subKey',
            categoryId: 'cat_sentences',
            title: title,
            level: level,
            order: order,
            questions: questions.take(10).toList(),
          ));
        }
      }
    });

    // --- Hybrid Mastery Quizzes Generation ---
    final beginnerWords = words.where((w) => ['greeting', 'basic', 'family', 'colors'].contains(w.category)).toList();
    final beginnerSentences = sentences.where((s) => ['basics', 'polite'].contains(s.category)).toList();

    final intermediateWords = words.where((w) => ['daily', 'nature', 'body'].contains(w.category)).toList();
    final intermediateSentences = sentences.where((s) => s.category == 'conversations').toList();

    final advancedWords = words.where((w) => ['time', 'trending'].contains(w.category)).toList();
    final advancedSentences = sentences.where((s) => s.category == 'time_weather').toList();

    QuizModel? compileHybridQuiz({
      required String id,
      required String categoryId,
      required String title,
      required String level,
      required int order,
      required List<WordModel> wordPool,
      required List<SentenceModel> sentencePool,
      required int targetCount,
    }) {
      if (wordPool.isEmpty && sentencePool.isEmpty) return null;

      final List<QuizQuestion> hybridQuestions = [];

      // 1. Compile word MCQs
      if (wordPool.isNotEmpty) {
        final shuffledWords = List<WordModel>.from(wordPool)..shuffle();
        final wordsToUse = shuffledWords.take((targetCount / 2).round()).toList();
        for (final w in wordsToUse) {
          final distractors = _getWordDistractors(w, words);
          final options = [w, ...distractors];
          options.shuffle();
          final correctIndex = options.indexOf(w);

          hybridQuestions.add(QuizQuestion(
            promptOlChiki: w.wordOlChiki,
            promptLatin: 'Choose the correct English meaning for this word.',
            optionsOlChiki: options.map((o) => o.wordOlChiki).toList(),
            optionsLatin: options.map((o) => '${o.wordOlChiki} (${o.meaning})').toList(),
            correctIndex: correctIndex,
          ));
        }
      }

      // 2. Compile sentence fill-in-the-blank questions
      if (sentencePool.isNotEmpty) {
        final shuffledSentences = List<SentenceModel>.from(sentencePool)..shuffle();
        final sentencesToUse = shuffledSentences.take((targetCount / 2).round()).toList();
        final sentenceQuestions = _generateSentenceQuestions(sentencesToUse, words);
        hybridQuestions.addAll(sentenceQuestions);
      }

      // Pad questions if we don't have enough to reach targetCount
      if (hybridQuestions.length < targetCount && wordPool.isNotEmpty) {
        final existingPrompts = hybridQuestions.map((q) => q.promptOlChiki).toSet();
        final remainingWords = wordPool.where((w) => !existingPrompts.contains(w.wordOlChiki)).toList()..shuffle();
        for (final w in remainingWords.take(targetCount - hybridQuestions.length)) {
          final distractors = _getWordDistractors(w, words);
          final options = [w, ...distractors];
          options.shuffle();
          final correctIndex = options.indexOf(w);

          hybridQuestions.add(QuizQuestion(
            promptOlChiki: w.wordOlChiki,
            promptLatin: 'Choose the correct English meaning for this word.',
            optionsOlChiki: options.map((o) => o.wordOlChiki).toList(),
            optionsLatin: options.map((o) => '${o.wordOlChiki} (${o.meaning})').toList(),
            correctIndex: correctIndex,
          ));
        }
      }

      // If we STILL don't have enough (e.g. because level-specific pool is small), pad from the global words database
      if (hybridQuestions.length < targetCount && words.isNotEmpty) {
        final existingPrompts = hybridQuestions.map((q) => q.promptOlChiki).toSet();
        final remainingWords = words.where((w) => !existingPrompts.contains(w.wordOlChiki)).toList()..shuffle();
        for (final w in remainingWords.take(targetCount - hybridQuestions.length)) {
          final distractors = _getWordDistractors(w, words);
          final options = [w, ...distractors];
          options.shuffle();
          final correctIndex = options.indexOf(w);

          hybridQuestions.add(QuizQuestion(
            promptOlChiki: w.wordOlChiki,
            promptLatin: 'Choose the correct English meaning for this word.',
            optionsOlChiki: options.map((o) => o.wordOlChiki).toList(),
            optionsLatin: options.map((o) => '${o.wordOlChiki} (${o.meaning})').toList(),
            correctIndex: correctIndex,
          ));
        }
      }

      // If we STILL don't have enough (extremely small dataset), allow duplicate questions from wordPool
      if (hybridQuestions.length < targetCount && wordPool.isNotEmpty) {
        final remainingCount = targetCount - hybridQuestions.length;
        final fallbackWords = List<WordModel>.from(wordPool)..shuffle();
        for (final w in fallbackWords.take(remainingCount)) {
          final distractors = _getWordDistractors(w, words);
          final options = [w, ...distractors];
          options.shuffle();
          final correctIndex = options.indexOf(w);

          hybridQuestions.add(QuizQuestion(
            promptOlChiki: w.wordOlChiki,
            promptLatin: 'Choose the correct English meaning for this word.',
            optionsOlChiki: options.map((o) => o.wordOlChiki).toList(),
            optionsLatin: options.map((o) => '${o.wordOlChiki} (${o.meaning})').toList(),
            correctIndex: correctIndex,
          ));
        }
      }

      if (hybridQuestions.isEmpty) return null;

      // Shuffle combined questions for an exciting, mixed learning experience
      hybridQuestions.shuffle();

      return QuizModel(
        id: id,
        categoryId: categoryId,
        title: title,
        level: level,
        order: order,
        questions: hybridQuestions.take(targetCount).toList(),
      );
    }

    final beginnerHybrid = compileHybridQuiz(
      id: 'quiz_dynamic_hybrid_beginner',
      categoryId: 'cat_vocab',
      title: 'Daily Mixed Challenge',
      level: 'beginner',
      order: 14,
      wordPool: beginnerWords,
      sentencePool: beginnerSentences,
      targetCount: 10,
    );
    if (beginnerHybrid != null) compiled.add(beginnerHybrid);

    final intermediateHybrid = compileHybridQuiz(
      id: 'quiz_dynamic_hybrid_intermediate',
      categoryId: 'cat_sentences',
      title: 'Mastery Mixed Challenge',
      level: 'intermediate',
      order: 15,
      wordPool: intermediateWords,
      sentencePool: intermediateSentences,
      targetCount: 10,
    );
    if (intermediateHybrid != null) compiled.add(intermediateHybrid);

    final advancedHybrid = compileHybridQuiz(
      id: 'quiz_dynamic_hybrid_advanced',
      categoryId: 'cat_sentences',
      title: 'Grand Mixed Challenge',
      level: 'advanced',
      order: 16,
      wordPool: advancedWords,
      sentencePool: advancedSentences,
      targetCount: 12,
    );
    if (advancedHybrid != null) compiled.add(advancedHybrid);

    return compiled;
  }


  List<WordModel> _getWordDistractors(WordModel correctWord, List<WordModel> allWords) {
    final List<WordModel> pool = [];

    final sameCategory = allWords.where((w) {
      if (correctWord.category == 'greeting' || correctWord.category == 'basic') {
        return (w.category == 'greeting' || w.category == 'basic') && w.id != correctWord.id;
      }
      return w.category == correctWord.category && w.id != correctWord.id;
    }).toList();
    pool.addAll(sameCategory);

    if (pool.length < 3) {
      final otherWords = allWords.where((w) => w.id != correctWord.id && !pool.any((p) => p.id == w.id)).toList();
      pool.addAll(otherWords);
    }

    pool.shuffle();
    return pool.take(3).toList();
  }

  List<QuizQuestion> _generateSentenceQuestions(List<SentenceModel> catSentences, List<WordModel> allWords) {
    final List<QuizQuestion> questions = [];

    for (final s in catSentences) {
      WordModel? matchedWord;
      for (final w in allWords) {
        if (w.wordOlChiki.length >= 2 && s.sentenceOlChiki.contains(w.wordOlChiki)) {
          matchedWord = w;
          break;
        }
      }

      if (matchedWord != null) {
        final blankedSentence = s.sentenceOlChiki.replaceAll(matchedWord.wordOlChiki, '___');
        final correctWord = matchedWord.wordOlChiki;
        final correctMeaning = matchedWord.meaning;

        final distractors = _getWordDistractors(matchedWord, allWords);
        final options = [matchedWord, ...distractors];
        options.shuffle();
        final correctIndex = options.indexOf(matchedWord);

        questions.add(QuizQuestion(
          type: 'fill_blank',
          promptOlChiki: 'Fill in the blank:',
          promptLatin: 'Choose the word that means "$correctMeaning" to complete the sentence.',
          optionsOlChiki: options.map((o) => o.wordOlChiki).toList(),
          optionsLatin: options.map((o) => '${o.wordOlChiki} (${o.meaning})').toList(),
          correctIndex: correctIndex,
          blankSentenceOlChiki: blankedSentence,
          blankSentenceLatin: s.meaning,
          correctAnswer: correctWord,
        ));
      } else {
        final sentenceWords = s.sentenceOlChiki.split(RegExp(r'\s+')).map((w) {
          return w.replaceAll(RegExp(r'[᱾,?.!-#%&()]'), '').trim();
        }).where((w) => w.length >= 3).toList();

        if (sentenceWords.isNotEmpty) {
          final targetWord = sentenceWords.first;
          final blankedSentence = s.sentenceOlChiki.replaceAll(targetWord, '___');

          final otherWords = List<WordModel>.from(allWords)..shuffle();
          final distractors = otherWords.take(3).toList();

          final optionsOlChiki = [targetWord];
          final optionsLatin = [targetWord];

          for (final d in distractors) {
            optionsOlChiki.add(d.wordOlChiki);
            optionsLatin.add('${d.wordOlChiki} (${d.meaning})');
          }

          final indices = [0, 1, 2, 3];
          indices.shuffle();

          final shuffledOptionsOlChiki = List<String>.filled(4, '');
          final shuffledOptionsLatin = List<String>.filled(4, '');
          int correctIndex = 0;

          for (int i = 0; i < 4; i++) {
            final oldIdx = indices[i];
            shuffledOptionsOlChiki[i] = optionsOlChiki[oldIdx];
            shuffledOptionsLatin[i] = optionsLatin[oldIdx];
            if (oldIdx == 0) {
              correctIndex = i;
            }
          }

          questions.add(QuizQuestion(
            type: 'fill_blank',
            promptOlChiki: 'Fill in the blank:',
            promptLatin: 'Complete the sentence with the correct word.',
            optionsOlChiki: shuffledOptionsOlChiki,
            optionsLatin: shuffledOptionsLatin,
            correctIndex: correctIndex,
            blankSentenceOlChiki: blankedSentence,
            blankSentenceLatin: s.meaning,
            correctAnswer: targetWord,
          ));
        }
      }
    }

    return questions;
  }

  Future<void> _loadQuizzes() async {
    try {
      final cached = await CacheService.getList<QuizModel>(
        _cacheKey,
        QuizModel.fromJson,
      );
      if (!mounted) return;
      if (cached != null && cached.isNotEmpty) {
        _baseQuizzes = cached;
        _updateDynamicQuizzes();
      } else {
        // Migration from SharedPreferences
        final stored =
            _prefs.getString(_cacheKey) ?? _prefs.getString(_legacyCacheKey);
        if (stored != null) {
          final List<dynamic> decoded = jsonDecode(stored);
          if (!mounted) return;
          final cachedQuizzes = decoded
              .map((e) => QuizModel.fromJson(e))
              .toList();
          _baseQuizzes = cachedQuizzes;
          _updateDynamicQuizzes();
          await _saveQuizzes(cachedQuizzes);
          _prefs.remove(_legacyCacheKey);
          _prefs.remove(_cacheKey);
        }
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Failed to load cached quizzes: $e');
      }
    }

    if (!mounted) return;

    try {
      final db = ref.read(appwriteDbServiceProvider);
      final data = await db.listDocuments(
        _collectionId,
        queries: [Query.orderAsc('order'), Query.limit(500)],
      );
      if (!mounted) return;
      final quizzes = data.map(QuizModel.fromJson).toList();
      if (quizzes.isNotEmpty) {
        _baseQuizzes = quizzes;
        _updateDynamicQuizzes();
        await _saveQuizzes(quizzes);
      } else if (!(_baseQuizzes.isNotEmpty)) {
        _baseQuizzes = _defaultQuizzes;
        _updateDynamicQuizzes();
        await _saveQuizzes(_defaultQuizzes);
      }
    } catch (e, stack) {
      if (!mounted) return;
      if (e is AppwriteException && e.code == 404) {
        debugPrint(
          'Quizzes collection ("$_collectionId") not found in Appwrite. '
          'Default quizzes will be used. Please run the setup script if this is a new project.',
        );
      } else {
        debugPrint('Failed to load quizzes from Appwrite: $e');
      }
      if (!(_baseQuizzes.isNotEmpty)) {
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
