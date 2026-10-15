import '../../../core/languages/indic_translations_dictionary.dart';
import '../../../core/languages/indic_translations_lessons.dart';
import '../../../core/languages/indic_translations_sentences.dart';
import '../../../core/languages/indic_translations_stories.dart';
import '../../../core/languages/indic_translations_words.dart';
import '../../../core/languages/ol_chiki_multilingual_helper.dart';
import '../../../shared/models/content_models.dart';
import '../../../shared/quiz_engine/quiz_engine.dart';
import '../../../core/languages/santali_numbers.dart';
import '../../../shared/models/catalog/lesson_entity.dart';
import '../presentation/providers/mistake_item.dart';
import 'lesson_quiz_generator.dart';
import 'listening_quiz_generator.dart';
import 'quiz_option_equivalence.dart';

/// Localizes a historical or cached [QuizQuestion] from a mistake into the
/// learner's active [teachingLanguage] ('bn', 'hi', 'or', 'sat', 'en').
///
/// Invariants enforced:
/// - Preserves option count, option order, and the correct index.
/// - Preserves canonical memory attribution (`sourceWordId`, `sourceSentenceId`).
/// - Re-localizes prompts, options, explanations, and sentence translations.
/// - Dynamic fallback hierarchy:
///   1. Exact match in compiled/active quizzes or lesson quiz generators.
///   2. Word / Sentence corpus lookup (`WordModel`, `SentenceModel`).
///   3. Number & alphabet detection / transliteration.
///   4. Cross-language dictionary reverse-lookup via [IndicTranslationsDictionary].
QuizQuestion localizeMistakeQuestion(
  QuizQuestion question, {
  required String teachingLanguage,
  List<WordModel> words = const [],
  List<SentenceModel> sentences = const [],
  Map<String, QuizModel>? compiledQuizzes,
  List<LessonEntity>? lessons,
  String? quizId,
}) {
  // Tier 1: Try exact match in compiled/generated quizzes in current teachingLanguage
  final compiledMatch = _findMatchingCompiledQuestion(
    question: question,
    teachingLanguage: teachingLanguage,
    compiledQuizzes: compiledQuizzes,
    lessons: lessons,
    quizId: quizId,
  );

  if (compiledMatch != null) {
    final newOptionsLatin = <String>[];
    var allOptionsMapped = true;

    for (int i = 0; i < question.optionsOlChiki.length; i++) {
      final optOl = question.optionsOlChiki[i];
      final matchIdx = compiledMatch.optionsOlChiki.indexOf(optOl);
      if (matchIdx >= 0 && matchIdx < compiledMatch.optionsLatin.length) {
        newOptionsLatin.add(compiledMatch.optionsLatin[matchIdx]);
      } else {
        allOptionsMapped = false;
        break;
      }
    }

    if (allOptionsMapped &&
        newOptionsLatin.length == question.optionsLatin.length &&
        newOptionsLatin.isNotEmpty) {
      return question.copyWith(
        promptLatin: compiledMatch.promptLatin,
        optionsLatin: newOptionsLatin,
        explanation: compiledMatch.explanation ?? question.explanation,
        blankSentenceLatin:
            compiledMatch.blankSentenceLatin ?? question.blankSentenceLatin,
      );
    }
  }

  // Tier 2: Model & corpus resolution
  final wordId = question.sourceWordId?.trim();
  final matchedWord =
      (wordId != null && wordId.isNotEmpty
          ? words.where((w) => w.id == wordId).firstOrNull
          : null) ??
      words
          .where((w) => w.wordOlChiki == question.promptOlChiki.trim())
          .firstOrNull;

  final sentenceId = question.sourceSentenceId?.trim();
  final matchedSentence =
      (sentenceId != null && sentenceId.isNotEmpty
          ? sentences.where((s) => s.id == sentenceId).firstOrNull
          : null) ??
      (question.blankSentenceOlChiki != null
          ? sentences
                .where(
                  (s) => s.sentenceOlChiki == question.blankSentenceOlChiki,
                )
                .firstOrNull
          : null);

  final qIdLower = quizId?.toLowerCase() ?? '';
  final promptLatin = question.promptLatin;
  final promptOlChiki = question.promptOlChiki;

  final isNumber =
      qIdLower.contains('number') ||
      promptOlChiki.runes.any((r) => r >= 0x1C50 && r <= 0x1C59) ||
      _hasAnyKeyword(promptLatin, const [
        'number',
        'संख्या',
        'সংখ্যা',
        'ସଂଖ୍ୟା',
        'ᱞᱮᱠᱷᱟ',
        'sum',
        'arithmetic',
      ]);

  final isAlphabet =
      qIdLower.contains('alphabet') ||
      qIdLower.contains('letter') ||
      _hasAnyKeyword(promptLatin, const [
        'letter',
        'consonant',
        'sound',
        'अक्षर',
        'ध्वनि',
        'वर्ण',
        'উচ্চারণ',
        'ଅକ୍ଷର',
        'ଉଚ୍ଚାରଣ',
        'ᱪᱤᱠᱤ',
        'ᱥᱟᱰᱮ',
      ]) ||
      (promptOlChiki.trim().runes.length == 1 &&
          !isNumber &&
          matchedWord == null &&
          matchedSentence == null);

  final isListening =
      qIdLower.startsWith('listening_quiz_') ||
      question.type == 'listen_meaning' ||
      _hasAnyKeyword(promptLatin, const [
        'audio',
        'ऑडियो',
        'অডিও',
        'ଅଡିଓ',
        'ᱟᱰᱤᱭᱳ',
        'listen',
      ]);

  final isSentence =
      matchedSentence != null ||
      question.type == 'fill_blank' ||
      sentenceId != null ||
      _hasAnyKeyword(promptLatin, const [
        'sentence',
        'blank',
        'वाक्य',
        'বাক্য',
        'ବାକ୍ୟ',
        'ᱟᱹᱭᱟᱹᱛ',
      ]);

  final newPromptLatin = _resolvePrompt(
    promptLatin: promptLatin,
    promptOlChiki: promptOlChiki,
    teachingLanguage: teachingLanguage,
    isNumber: isNumber,
    isAlphabet: isAlphabet,
    isListening: isListening,
    isSentence: isSentence,
    matchedWord: matchedWord,
  );

  final newOptionsLatin = <String>[];
  final optionCount = question.optionsLatin.length;

  for (int i = 0; i < optionCount; i++) {
    final optOl = i < question.optionsOlChiki.length
        ? question.optionsOlChiki[i]
        : '';
    final optLatin = question.optionsLatin[i];

    final localizedOpt = _resolveOption(
      optOl: optOl,
      optLatin: optLatin,
      teachingLanguage: teachingLanguage,
      words: words,
      isNumber: isNumber,
      isAlphabet: isAlphabet,
    );
    newOptionsLatin.add(localizedOpt);
  }

  String? newExplanation;
  if (matchedWord != null) {
    newExplanation = QuizEngine.meaningDisplay(
      matchedWord,
      teachingLanguage: teachingLanguage,
    );
  } else if (matchedSentence != null) {
    newExplanation = matchedSentence.localizedMeaning(teachingLanguage);
  } else if (question.explanation != null && question.explanation!.isNotEmpty) {
    newExplanation =
        _TranslationIndex.translate(question.explanation!, teachingLanguage) ??
        question.explanation;
  }

  String? newBlankSentenceLatin;
  if (matchedSentence != null) {
    newBlankSentenceLatin = matchedSentence.localizedMeaning(teachingLanguage);
  } else if (question.blankSentenceLatin != null &&
      question.blankSentenceLatin!.isNotEmpty) {
    newBlankSentenceLatin =
        _TranslationIndex.translate(
          question.blankSentenceLatin!,
          teachingLanguage,
        ) ??
        question.blankSentenceLatin;
  }

  return question.copyWith(
    promptLatin: newPromptLatin,
    optionsLatin: newOptionsLatin.isNotEmpty
        ? newOptionsLatin
        : question.optionsLatin,
    explanation: newExplanation ?? question.explanation,
    blankSentenceLatin: newBlankSentenceLatin ?? question.blankSentenceLatin,
  );
}

/// Localizes a [MistakeItem]'s underlying question to [teachingLanguage].
MistakeItem localizeMistakeItem(
  MistakeItem item, {
  required String teachingLanguage,
  List<WordModel> words = const [],
  List<SentenceModel> sentences = const [],
  Map<String, QuizModel>? compiledQuizzes,
  List<LessonEntity>? lessons,
}) {
  final localizedQuestion = localizeMistakeQuestion(
    item.question,
    teachingLanguage: teachingLanguage,
    words: words,
    sentences: sentences,
    compiledQuizzes: compiledQuizzes,
    lessons: lessons,
    quizId: item.quizId,
  );
  return item.copyWith(question: localizedQuestion);
}

/// Localizes a list of [MistakeItem]s to [teachingLanguage].
List<MistakeItem> localizeMistakeItems(
  List<MistakeItem> items, {
  required String teachingLanguage,
  List<WordModel> words = const [],
  List<SentenceModel> sentences = const [],
  Map<String, QuizModel>? compiledQuizzes,
  List<LessonEntity>? lessons,
}) {
  return [
    for (final item in items)
      localizeMistakeItem(
        item,
        teachingLanguage: teachingLanguage,
        words: words,
        sentences: sentences,
        compiledQuizzes: compiledQuizzes,
        lessons: lessons,
      ),
  ];
}

QuizQuestion? _findMatchingCompiledQuestion({
  required QuizQuestion question,
  required String teachingLanguage,
  Map<String, QuizModel>? compiledQuizzes,
  List<LessonEntity>? lessons,
  String? quizId,
}) {
  if (quizId == null || quizId.isEmpty) return null;

  QuizModel? quiz = compiledQuizzes?[quizId];

  if (quiz == null && lessons != null && lessons.isNotEmpty) {
    if (quizId.startsWith('dynamic_quiz_')) {
      final lessonId = quizId.substring('dynamic_quiz_'.length);
      final lesson = lessons.where((l) => l.id == lessonId).firstOrNull;
      if (lesson != null) {
        quiz = LessonQuizGenerator.generate(
          lesson,
          teachingLanguage: teachingLanguage,
        );
      }
    } else if (quizId.startsWith('listening_quiz_')) {
      final lessonId = quizId.substring('listening_quiz_'.length);
      final lesson = lessons.where((l) => l.id == lessonId).firstOrNull;
      if (lesson != null) {
        quiz = ListeningQuizGenerator.generate(
          lesson,
          teachingLanguage: teachingLanguage,
        );
      }
    }
  }

  if (quiz == null || quiz.questions.isEmpty) return null;

  if (question.sourceWordId != null && question.sourceWordId!.isNotEmpty) {
    final match = quiz.questions
        .where((q) => q.sourceWordId == question.sourceWordId)
        .firstOrNull;
    if (match != null) return match;
  }

  if (question.sourceSentenceId != null &&
      question.sourceSentenceId!.isNotEmpty) {
    final match = quiz.questions
        .where((q) => q.sourceSentenceId == question.sourceSentenceId)
        .firstOrNull;
    if (match != null) return match;
  }

  return quiz.questions
      .where((q) => q.promptOlChiki == question.promptOlChiki)
      .firstOrNull;
}

String _resolveOption({
  required String optOl,
  required String optLatin,
  required String teachingLanguage,
  required List<WordModel> words,
  required bool isNumber,
  required bool isAlphabet,
}) {
  if (teachingLanguage == 'sat') {
    if (optOl.isNotEmpty) return optOl;
    return optLatin;
  }

  // 1. Try WordModel lookup in words corpus
  if (optOl.isNotEmpty) {
    final w = words
        .where((word) => word.wordOlChiki == optOl || word.id == optOl)
        .firstOrNull;
    if (w != null) {
      final meaning = QuizEngine.meaningDisplay(
        w,
        teachingLanguage: teachingLanguage,
      );
      if (meaning.isNotEmpty) return meaning;
    }
  }

  // 2. Number handling
  final numVal = QuizOptionEquivalence.extractNumberValue(
    optLatin.isNotEmpty ? optLatin : optOl,
  );
  if (numVal != null &&
      (isNumber ||
          optLatin.contains('(') ||
          optLatin.contains('–') ||
          RegExp(r'^\d+$').hasMatch(optLatin))) {
    if (optLatin.contains('(')) {
      return SantaliNumbers.teachingLanguageName(numVal, teachingLanguage);
    } else if (RegExp(
      r'^\s*[\d\u1C50-\u1C59\u09E6-\u09EF\u0966-\u096F\u0B66-\u0B6F]+\s*$',
    ).hasMatch(optLatin)) {
      return SantaliNumbers.toNumeral(numVal, teachingLanguage);
    } else {
      return SantaliNumbers.teachingLanguageName(numVal, teachingLanguage);
    }
  }

  // 3. Alphabet handling
  if (isAlphabet && optOl.isNotEmpty) {
    final transliterated = OlChikiMultilingualHelper.transliterateOlChiki(
      optOl,
      teachingLanguage,
    );
    if (transliterated.isNotEmpty) return transliterated;
  }

  // 4. Cross-language dictionary lookup
  if (optLatin.isNotEmpty) {
    final translated = _TranslationIndex.translate(optLatin, teachingLanguage);
    if (translated != null && translated.isNotEmpty) {
      return translated;
    }
  }

  // 5. Transliterate Ol Chiki if available
  if (optOl.isNotEmpty) {
    final transliterated = OlChikiMultilingualHelper.transliterateOlChiki(
      optOl,
      teachingLanguage,
    );
    if (transliterated.isNotEmpty) return transliterated;
  }

  return optLatin.isNotEmpty ? optLatin : optOl;
}

const Map<String, Map<String, String>> _canonicalPrompts = {
  'listen': {
    'hi': 'ऑडियो सुनें और सही अर्थ चुनें:',
    'bn': 'অডিও শুনুন এবং সঠিক অর্থ বেছে নিন:',
    'or': 'ଅଡିଓ ଶୁଣନ୍ତୁ ଏବଂ ସଠିକ୍ ଅର୍ଥ ବାଛନ୍ତୁ:',
    'sat': 'ᱟᱰᱤᱭᱳ ᱟᱸᱡᱚᱢ ᱢᱮ ᱟᱨ ᱥᱟᱹᱨᱤ ᱢᱮᱱᱮᱛ ᱵᱟᱪᱷᱟᱣ ᱢᱮ:',
    'en': 'Play the audio and choose the correct meaning:',
  },
  'number': {
    'hi': 'यह संख्या पहचानें:',
    'bn': 'এই সংখ্যাটি চিহ্নিত করুন:',
    'or': 'ଏହି ସଂଖ୍ୟାଟି ଚିହ୍ନଟ କରନ୍ତୁ:',
    'sat': 'ᱱᱚᱶᱟ ᱞᱮᱠᱷᱟ ᱪᱤᱱᱦᱟᱹᱣ ᱢᱮ:',
    'en': 'Identify this number:',
  },
  'letter': {
    'hi': 'इस अक्षर की ध्वनि पहचानें:',
    'bn': 'এই বর্ণের উচ্চারণ চিহ্নিত করুন:',
    'or': 'ଏହି ଅକ୍ଷରର ଉଚ୍ଚାରଣ ବାଛନ୍ତୁ:',
    'sat': 'ᱱᱚᱶᱟ ᱪᱤᱠᱤ ᱨᱮᱭᱟᱜ ᱥᱟᱰᱮ ᱵᱟᱪᱷᱟᱣ ᱢᱮ:',
    'en': 'Which sound does this letter make?',
  },
  'sentence': {
    'hi': 'सही शब्द चुनकर वाक्य पूरा करें।',
    'bn': 'সঠিক শব্দ বেছে বাক্যটি সম্পূর্ণ করুন।',
    'or': 'ସଠିକ୍ ଶବ୍ଦ ବାଛି ବାକ୍ୟ ପୂରଣ କରନ୍ତୁ।',
    'sat': 'ᱥᱟᱹᱨᱤ ᱟᱹᱲᱟᱹ ᱵᱟᱪᱷᱟᱣ ᱠᱟᱛᱮ ᱟᱹᱭᱟᱹᱛ ᱯᱩᱨᱟᱹᱣ ᱢᱮ᱾',
    'en': 'Complete the sentence with the correct word.',
  },
  'choose_meaning': {
    'hi': 'Choose the correct Hindi meaning:',
    'bn': 'Choose the correct Bengali meaning:',
    'or': 'Choose the correct Odia meaning:',
    'sat': 'ᱥᱟᱹᱨᱤ ᱢᱮᱱᱮᱛ ᱵᱟᱪᱷᱟᱣ ᱢᱮ:',
    'en': 'Choose the correct English meaning:',
  },
  'vocab': {
    'hi': 'इस शब्द का सही अर्थ चुनें:',
    'bn': 'এই শব্দটির সঠিক অর্থ বেছে নিন:',
    'or': 'ଏହି ଶବ୍ଦର ସଠିକ୍ ଅର୍ଥ ବାଛନ୍ତୁ:',
    'sat': 'ᱱᱚᱶᱟ ᱟᱹᱲᱟᱹ ᱨᱮᱭᱟᱜ ᱥᱟᱹᱨᱤ ᱢᱮᱱᱮᱛ ᱵᱟᱪᱷᱟᱣ ᱢᱮ:',
    'en': 'Choose the correct English meaning for this word.',
  },
};

String _promptFor(String key, String lang) =>
    _canonicalPrompts[key]?[lang] ?? _canonicalPrompts[key]?['en'] ?? '';

String _resolvePrompt({
  required String? promptLatin,
  required String promptOlChiki,
  required String teachingLanguage,
  bool isNumber = false,
  bool isAlphabet = false,
  bool isListening = false,
  bool isSentence = false,
  WordModel? matchedWord,
}) {
  if (isListening) return _promptFor('listen', teachingLanguage);
  if (isNumber) return _promptFor('number', teachingLanguage);
  if (isAlphabet) return _promptFor('letter', teachingLanguage);

  if (isSentence) {
    if (matchedWord != null) {
      final meaning = QuizEngine.meaningDisplay(
        matchedWord,
        teachingLanguage: teachingLanguage,
      );
      switch (teachingLanguage) {
        case 'hi':
          return 'जिस शब्द का अर्थ "$meaning" है उसे चुनकर वाक्य पूरा करें।';
        case 'bn':
          return 'যে শব্দটির অর্থ "$meaning" সেটি বেছে বাক্যটি সম্পূর্ণ করুন।';
        case 'or':
          return 'ଯେଉଁ ଶବ୍ଦର ଅର୍ଥ "$meaning" ତାହା ବାଛି ବାକ୍ୟ ପୂରଣ କରନ୍ତୁ।';
        case 'sat':
          return '"$meaning" ᱢᱮᱱᱮᱛᱟᱱ ᱟᱹᱲᱟᱹ ᱵᱟᱪᱷᱟᱣ ᱠᱟᱛᱮ ᱟᱹᱭᱟᱹᱛ ᱯᱩᱨᱟᱹᱣ ᱢᱮ᱾';
        case 'en':
        default:
          return 'Choose the word that means "$meaning" to complete the sentence.';
      }
    }
    return _promptFor('sentence', teachingLanguage);
  }

  final p = (promptLatin ?? '').toLowerCase();
  final isChooseMeaning =
      p.contains('choose the correct') && p.contains('meaning');
  if (isChooseMeaning) {
    return _promptFor('choose_meaning', teachingLanguage);
  }

  return _promptFor('vocab', teachingLanguage);
}

bool _hasAnyKeyword(String? text, List<String> keywords) {
  if (text == null || text.isEmpty) return false;
  final lower = text.toLowerCase();
  return keywords.any(lower.contains);
}

/// Reverse-index across aggregated dictionary collections.
class _TranslationIndex {
  static final Map<String, Map<String, String>> _textToLangMap = () {
    final map = <String, Map<String, String>>{};
    void addSource(Map<String, Map<String, String>> source) {
      for (final entry in source.values) {
        for (final val in entry.values) {
          final trimmed = val.trim().toLowerCase();
          if (trimmed.isNotEmpty && !map.containsKey(trimmed)) {
            map[trimmed] = entry;
          }
        }
      }
    }

    addSource(IndicTranslationsDictionary.vocabulary);
    addSource(IndicTranslationsWords.translations);
    addSource(IndicTranslationsSentences.translations);
    addSource(IndicTranslationsLessons.translations);
    addSource(IndicTranslationsStories.translations);
    return map;
  }();

  static String? translate(String text, String targetLang) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    final lower = trimmed.toLowerCase();

    final entry = _textToLangMap[lower];
    if (entry != null && entry.containsKey(targetLang)) {
      final res = entry[targetLang];
      if (res != null && res.trim().isNotEmpty) return res.trim();
    }

    final direct = IndicTranslationsDictionary.lookup(trimmed, targetLang);
    if (direct != null && direct.trim().isNotEmpty) return direct.trim();

    final translatedMeaning = OlChikiMultilingualHelper.translateMeaning(
      trimmed,
      targetLang,
    );
    if (translatedMeaning.trim().isNotEmpty) return translatedMeaning.trim();

    return null;
  }
}
