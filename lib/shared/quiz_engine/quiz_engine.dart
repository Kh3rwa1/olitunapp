import '../models/content_models.dart';
import 'sentence_quiz_builder.dart';

class QuizCatalog {
  const QuizCatalog._();

  static final List<QuizModel> defaultQuizzes = [
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
}

class QuizEngine {
  const QuizEngine._();

  static const List<_VocabQuizSpec> _vocabSpecs = [
    _VocabQuizSpec(
      idSuffix: 'basics',
      keys: ['greeting', 'basic'],
      title: 'Greetings & Basics Quiz',
      level: 'beginner',
      order: 2,
    ),
    _VocabQuizSpec(
      idSuffix: 'family',
      keys: ['family'],
      title: 'Family & Relationships Quiz',
      level: 'beginner',
      order: 3,
    ),
    _VocabQuizSpec(
      idSuffix: 'daily',
      keys: ['daily'],
      title: 'Daily Use Words Quiz',
      level: 'intermediate',
      order: 4,
    ),
    _VocabQuizSpec(
      idSuffix: 'colors',
      keys: ['colors'],
      title: 'Colors Quiz',
      level: 'beginner',
      order: 5,
    ),
    _VocabQuizSpec(
      idSuffix: 'nature',
      keys: ['nature'],
      title: 'Animals & Nature Quiz',
      level: 'intermediate',
      order: 6,
    ),
    _VocabQuizSpec(
      idSuffix: 'time',
      keys: ['time'],
      title: 'Months & Seasons Quiz',
      level: 'advanced',
      order: 7,
    ),
    _VocabQuizSpec(
      idSuffix: 'trending',
      keys: ['trending'],
      title: 'Trending Words Quiz',
      level: 'advanced',
      order: 8,
    ),
    _VocabQuizSpec(
      idSuffix: 'body',
      keys: ['body'],
      title: 'Body Parts Quiz',
      level: 'intermediate',
      order: 9,
    ),
  ];

  static const List<_SentenceQuizSpec> _sentenceSpecs = [
    _SentenceQuizSpec(
      idSuffix: 'basics',
      key: 'basics',
      title: 'Basic Sentences Quiz',
      level: 'beginner',
      order: 10,
    ),
    _SentenceQuizSpec(
      idSuffix: 'conversations',
      key: 'conversations',
      title: 'Daily Conversations Quiz',
      level: 'intermediate',
      order: 11,
    ),
    _SentenceQuizSpec(
      idSuffix: 'polite',
      key: 'polite',
      title: 'Greetings & Politeness Quiz',
      level: 'beginner',
      order: 12,
    ),
    _SentenceQuizSpec(
      idSuffix: 'time_weather',
      key: 'time_weather',
      title: 'Time & Weather Quiz',
      level: 'advanced',
      order: 13,
    ),
  ];

  static const List<_HybridQuizSpec> _hybridSpecs = [
    _HybridQuizSpec(
      id: 'quiz_dynamic_hybrid_beginner',
      categoryId: 'cat_vocab',
      title: 'Daily Mixed Challenge',
      level: 'beginner',
      order: 14,
      wordKeys: ['greeting', 'basic', 'family', 'colors'],
      sentenceKeys: ['basics', 'polite'],
      targetCount: 10,
    ),
    _HybridQuizSpec(
      id: 'quiz_dynamic_hybrid_intermediate',
      categoryId: 'cat_sentences',
      title: 'Mastery Mixed Challenge',
      level: 'intermediate',
      order: 15,
      wordKeys: ['daily', 'nature', 'body'],
      sentenceKeys: ['conversations'],
      targetCount: 10,
    ),
    _HybridQuizSpec(
      id: 'quiz_dynamic_hybrid_advanced',
      categoryId: 'cat_sentences',
      title: 'Grand Mixed Challenge',
      level: 'advanced',
      order: 16,
      wordKeys: ['time', 'trending'],
      sentenceKeys: ['time_weather'],
      targetCount: 12,
    ),
  ];

  static List<QuizModel> compile({
    required List<QuizModel> baseQuizzes,
    required List<WordModel> words,
    required List<SentenceModel> sentences,
    String teachingLanguage = 'en',
  }) {
    final compiled = <QuizModel>[
      for (final quiz in baseQuizzes)
        if (quiz.categoryId != 'cat_vocab' &&
            quiz.categoryId != 'cat_sentences')
          quiz,
    ];

    _addMissingDefaults(compiled);
    compiled.addAll(
      _compileVocabularyQuizzes(words, teachingLanguage: teachingLanguage),
    );
    compiled.addAll(_compileSentenceQuizzes(sentences, words));
    compiled.addAll(
      _compileHybridQuizzes(
        words,
        sentences,
        teachingLanguage: teachingLanguage,
      ),
    );
    return compiled;
  }

  static List<QuizQuestion> sentenceQuestions(
    List<SentenceModel> sentences,
    List<WordModel> words,
  ) {
    return [
      for (final sentence in sentences)
        ?SentenceQuizBuilder.build(sentence, words),
    ];
  }

  /// Display text for an MCQ option: the localized meaning when present,
  /// otherwise the Ol Chiki word. Rendering '{olChiki} ({meaning})' let
  /// players string-match the prompt glyph inside the option text instead
  /// of knowing the language — options must show the meaning only.
  static String meaningDisplay(
    WordModel word, {
    String teachingLanguage = 'en',
  }) {
    if (teachingLanguage != 'en') {
      final loc = word.localizedMeaning(teachingLanguage).trim();
      if (loc.isNotEmpty) return loc;
    }
    final meaning = word.meaning.trim();
    return meaning.isNotEmpty ? meaning : word.wordOlChiki;
  }

  static List<WordModel> wordDistractors(
    WordModel correctWord,
    List<WordModel> allWords, {
    String teachingLanguage = 'en',
  }) {
    final sameCategory = allWords.where((word) {
      final correctCategory = correctWord.category;
      final candidateCategory = word.category;
      if (word.id == correctWord.id) return false;
      if (correctCategory == 'greeting' || correctCategory == 'basic') {
        return candidateCategory == 'greeting' || candidateCategory == 'basic';
      }
      return candidateCategory == correctCategory;
    }).toList();

    final fallback = allWords.where((word) {
      return word.id != correctWord.id &&
          !sameCategory.any((candidate) => candidate.id == word.id);
    });

    // Distractors must be display-distinct from the correct answer AND from
    // each other — two options reading the same meaning would make the
    // question ambiguous (picking either is equally "correct").
    final correctDisplay = meaningDisplay(
      correctWord,
      teachingLanguage: teachingLanguage,
    );
    final distinct = <WordModel>[];
    for (final candidate in <WordModel>[
      ...sameCategory,
      ...fallback,
    ]..shuffle()) {
      final display = meaningDisplay(
        candidate,
        teachingLanguage: teachingLanguage,
      );
      if (display == correctDisplay) continue;
      if (distinct.any(
        (d) => meaningDisplay(d, teachingLanguage: teachingLanguage) == display,
      )) {
        continue;
      }
      distinct.add(candidate);
      if (distinct.length == 3) break;
    }
    return distinct;
  }

  static void _addMissingDefaults(List<QuizModel> compiled) {
    for (final categoryId in const ['alphabets', 'numbers']) {
      if (!compiled.any((quiz) => quiz.categoryId == categoryId)) {
        compiled.addAll(
          QuizCatalog.defaultQuizzes.where(
            (quiz) => quiz.categoryId == categoryId,
          ),
        );
      }
    }
  }

  static Iterable<QuizModel> _compileVocabularyQuizzes(
    List<WordModel> words, {
    String teachingLanguage = 'en',
  }) {
    return [
      for (final spec in _vocabSpecs)
        if (_wordsForKeys(words, spec.keys) case final pool
            when pool.isNotEmpty)
          QuizModel(
            id: 'quiz_dynamic_vocab_${spec.idSuffix}',
            categoryId: 'cat_vocab',
            title: spec.title,
            level: spec.level,
            order: spec.order,
            questions: _wordQuestions(
              pool.takeShuffled(10),
              words,
              teachingLanguage: teachingLanguage,
            ),
          ),
    ];
  }

  static Iterable<QuizModel> _compileSentenceQuizzes(
    List<SentenceModel> sentences,
    List<WordModel> words,
  ) {
    return [
      for (final spec in _sentenceSpecs)
        if (sentenceQuestions(_sentencesForKeys(sentences, [spec.key]), words)
            case final questions when questions.isNotEmpty)
          QuizModel(
            id: 'quiz_dynamic_sentences_${spec.idSuffix}',
            categoryId: 'cat_sentences',
            title: spec.title,
            level: spec.level,
            order: spec.order,
            questions: questions.take(10).toList(),
          ),
    ];
  }

  static Iterable<QuizModel> _compileHybridQuizzes(
    List<WordModel> words,
    List<SentenceModel> sentences, {
    String teachingLanguage = 'en',
  }) {
    return [
      for (final spec in _hybridSpecs)
        ?_hybridQuiz(
          spec,
          words,
          sentences,
          teachingLanguage: teachingLanguage,
        ),
    ];
  }

  static QuizModel? _hybridQuiz(
    _HybridQuizSpec spec,
    List<WordModel> allWords,
    List<SentenceModel> allSentences, {
    String teachingLanguage = 'en',
  }) {
    final wordPool = _wordsForKeys(allWords, spec.wordKeys);
    final sentencePool = _sentencesForKeys(allSentences, spec.sentenceKeys);
    if (wordPool.isEmpty && sentencePool.isEmpty) return null;

    final splitCount = (spec.targetCount / 2).round();
    final questions = <QuizQuestion>[
      ..._wordQuestions(
        wordPool.takeShuffled(splitCount),
        allWords,
        teachingLanguage: teachingLanguage,
      ),
      ...sentenceQuestions(sentencePool.takeShuffled(splitCount), allWords),
    ];

    questions.addAll(
      _wordQuestions(
        _unusedWords(
          wordPool,
          questions,
        ).takeShuffled(spec.targetCount - questions.length),
        allWords,
        teachingLanguage: teachingLanguage,
      ),
    );

    questions.addAll(
      _wordQuestions(
        _unusedWords(
          allWords,
          questions,
        ).takeShuffled(spec.targetCount - questions.length),
        allWords,
        teachingLanguage: teachingLanguage,
      ),
    );

    if (questions.isEmpty) return null;

    questions.shuffle();
    return QuizModel(
      id: spec.id,
      categoryId: spec.categoryId,
      title: spec.title,
      level: spec.level,
      order: spec.order,
      questions: questions.take(spec.targetCount).toList(),
    );
  }

  static List<WordModel> _unusedWords(
    List<WordModel> words,
    List<QuizQuestion> questions,
  ) {
    final prompts = questions.map((question) => question.promptOlChiki).toSet();
    return words.where((word) => !prompts.contains(word.wordOlChiki)).toList();
  }

  static List<QuizQuestion> _wordQuestions(
    List<WordModel> words,
    List<WordModel> allWords, {
    String teachingLanguage = 'en',
  }) {
    return [
      for (final word in words)
        _wordQuestion(word, allWords, teachingLanguage: teachingLanguage),
    ];
  }

  static QuizQuestion _wordQuestion(
    WordModel word,
    List<WordModel> allWords, {
    String teachingLanguage = 'en',
  }) {
    final options = <WordModel>[
      word,
      ...wordDistractors(word, allWords, teachingLanguage: teachingLanguage),
    ]..shuffle();

    String prompt(String lang) {
      switch (lang) {
        case 'hi':
          return 'इस शब्द का सही अर्थ चुनें:';
        case 'bn':
          return 'এই শব্দটির সঠিক অর্থ বেছে নিন:';
        case 'or':
          return 'ଏହି ଶବ୍ଦର ସଠିକ୍ ଅର୍ଥ ବାଛନ୍ତୁ:';
        case 'sat':
          return 'ᱱᱚᱶᱟ ᱟᱹᱲᱟᱹ ᱨᱮᱭᱟᱜ ᱥᱟᱹᱨᱤ ᱢᱮᱱᱮᱛ ᱵᱟᱪᱷᱟᱣ ᱢᱮ:';
        case 'en':
        default:
          return 'Choose the correct English meaning for this word.';
      }
    }

    return QuizQuestion(
      promptOlChiki: word.wordOlChiki,
      promptLatin: prompt(teachingLanguage),
      optionsOlChiki: options.map((option) => option.wordOlChiki).toList(),
      optionsLatin: options
          .map((w) => meaningDisplay(w, teachingLanguage: teachingLanguage))
          .toList(),
      correctIndex: options.indexWhere((option) => option.id == word.id),
    );
  }

  static List<WordModel> _wordsForKeys(
    List<WordModel> words,
    List<String> keys,
  ) {
    return words.where((word) => keys.contains(word.category)).toList();
  }

  static List<SentenceModel> _sentencesForKeys(
    List<SentenceModel> sentences,
    List<String> keys,
  ) {
    return sentences
        .where((sentence) => keys.contains(sentence.category))
        .toList();
  }
}

class _VocabQuizSpec {
  const _VocabQuizSpec({
    required this.idSuffix,
    required this.keys,
    required this.title,
    required this.level,
    required this.order,
  });

  final String idSuffix;
  final List<String> keys;
  final String title;
  final String level;
  final int order;
}

class _SentenceQuizSpec {
  const _SentenceQuizSpec({
    required this.idSuffix,
    required this.key,
    required this.title,
    required this.level,
    required this.order,
  });

  final String idSuffix;
  final String key;
  final String title;
  final String level;
  final int order;
}

class _HybridQuizSpec {
  const _HybridQuizSpec({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.level,
    required this.order,
    required this.wordKeys,
    required this.sentenceKeys,
    required this.targetCount,
  });

  final String id;
  final String categoryId;
  final String title;
  final String level;
  final int order;
  final List<String> wordKeys;
  final List<String> sentenceKeys;
  final int targetCount;
}

extension _ShuffledTake<T> on List<T> {
  List<T> takeShuffled(int count) {
    if (count <= 0 || isEmpty) return const [];
    return (List<T>.from(this)..shuffle()).take(count).toList();
  }
}
