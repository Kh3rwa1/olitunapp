import '../../../core/languages/ol_chiki_multilingual_helper.dart';
import '../../../shared/models/content_models.dart';
import '../../lessons/domain/entities/lesson_entity.dart';
import 'quiz_generation_diagnostics.dart';
import 'quiz_identity_validation.dart';

export 'quiz_generation_diagnostics.dart';

class LessonQuizGenerator {
  const LessonQuizGenerator._();

  /// Legacy entry point. Returns the generated quiz, or a quiz with zero
  /// questions when nothing valid could be generated. Callers must treat an
  /// empty quiz as "unavailable" — never substitute placeholder questions.
  static QuizModel generate(
    LessonEntity lesson, {
    String teachingLanguage = 'en',
    String scriptMode = 'both',
    String targetLanguage = 'sat',
  }) {
    return generateResult(
      lesson,
      teachingLanguage: teachingLanguage,
      scriptMode: scriptMode,
      targetLanguage: targetLanguage,
    ).quiz;
  }

  /// Generates sentence/word/letter/number questions from lesson blocks and
  /// reports bounded per-block rejection diagnostics (lesson ID + block
  /// index only — no sentence text or translations).
  ///
  /// Fail-closed contract: when no valid questions can be generated the
  /// result carries an empty quiz. Lesson titles are never used as learning
  /// questions.
  static QuizGenerationResult generateResult(
    LessonEntity lesson, {
    String teachingLanguage = 'en',
    String scriptMode = 'both',
    String targetLanguage = 'sat',
  }) {
    final questions = <QuizQuestion>[];
    final rejections = <BlockRejection>[];
    void reject(int index, List<String> reasons) {
      if (rejections.length >= QuizGenerationResult.maxRejections) return;
      rejections.add(BlockRejection(blockIndex: index, reasons: reasons));
    }

    final blocks = lesson.blocks.where((b) => b.type != 'quiz').toList();

    final isNumberCategory = lesson.categoryId.toLowerCase().contains('number');
    final isAlphabetCategory =
        lesson.categoryId.toLowerCase().contains('alphabet') ||
        lesson.categoryId.toLowerCase().contains('letter');
    // Indic meaning prompts must be answered with real translations, never
    // with romanized Santali passed off as Hindi/Bengali/Odia.
    final requiresExplicitMeaning =
        (teachingLanguage == 'hi' ||
            teachingLanguage == 'bn' ||
            teachingLanguage == 'or') &&
        !isAlphabetCategory &&
        !isNumberCategory;

    // Pre-resolve options for all blocks in the lesson
    final resolvedBlockOptions = <String>[];
    for (final b in blocks) {
      final opt = resolveBlockOption(
        b,
        teachingLanguage,
        isAlphabet: isAlphabetCategory,
        isNumber: isNumberCategory,
      );
      if (opt.isNotEmpty) {
        resolvedBlockOptions.add(opt);
      }
    }

    final seenPrompts = <String>{};
    var validBlockCount = 0;

    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      if (block.dataMalformed) {
        reject(i, const [QuizRejectionReason.malformedData]);
        continue;
      }
      final olChiki = block.textOlChiki?.trim();
      final latin = block.textLatin?.trim();

      if (olChiki == null || olChiki.isEmpty) {
        reject(i, const [QuizRejectionReason.missingOlChiki]);
        continue;
      }
      if (latin == null || latin.isEmpty) {
        reject(i, const [QuizRejectionReason.missingLatin]);
        continue;
      }
      if (requiresExplicitMeaning &&
          !hasExplicitMeaning(block, teachingLanguage)) {
        reject(i, const [QuizRejectionReason.missingMeaning]);
        continue;
      }

      final correctOption = resolveBlockOption(
        block,
        teachingLanguage,
        isAlphabet: isAlphabetCategory,
        isNumber: isNumberCategory,
      );
      if (correctOption.isEmpty) {
        reject(i, const [QuizRejectionReason.missingMeaning]);
        continue;
      }

      final promptKey = olChiki;
      if (!seenPrompts.add(promptKey)) {
        reject(i, const [QuizRejectionReason.duplicateContent]);
        continue;
      }

      // 1. Gather other items in the same lesson as high-quality distractors
      final otherBlockTranslations = resolvedBlockOptions
          .where((opt) => opt != correctOption)
          .toSet()
          .toList();

      // 2. Fallback general distractors based on category & language
      final defaultDistractors = fallbackDistractors(
        teachingLanguage,
        isNumberCategory,
        isAlphabetCategory,
      );

      final distractors = [
        ...otherBlockTranslations,
        ...defaultDistractors,
      ].where((d) => d != correctOption).toSet().toList()..shuffle();

      final options = [correctOption, ...distractors.take(3)]..shuffle();
      final correctIndex = options.indexOf(correctOption);

      // Every multiple-choice question needs four unique, non-empty options
      // with a valid correct index — otherwise it is rejected, not shipped.
      if (options.length < 4 ||
          correctIndex < 0 ||
          options.any((o) => o.trim().isEmpty) ||
          options.toSet().length != options.length) {
        seenPrompts.remove(promptKey);
        reject(i, const [QuizRejectionReason.insufficientDistractors]);
        continue;
      }

      validBlockCount++;

      final promptLatin = isNumberCategory
          ? _numberPrompt(teachingLanguage)
          : (isAlphabetCategory
                ? _letterPrompt(teachingLanguage)
                : _meaningPrompt(teachingLanguage));

      final sourceWordId =
          (block.data?['sourceWordId'] ??
                  block.data?['wordId'] ??
                  block.data?['sourceWord'] ??
                  block.data?['word_id'])
              as String?;
      final sourceSentenceId =
          (block.data?['sourceSentenceId'] ??
                  block.data?['sentenceId'] ??
                  block.data?['sourceSentence'] ??
                  block.data?['sentence_id'])
              as String?;
      // Exactly-one normalization: a block carrying both ids keeps the
      // word attribution (documented build-time choice, logged).
      final attribution = normalizeSourceAttribution(
        sourceWordId: sourceWordId,
        sourceSentenceId: sourceSentenceId,
      );

      questions.add(
        QuizQuestion(
          promptOlChiki: olChiki,
          promptLatin: promptLatin,
          optionsOlChiki: options,
          optionsLatin: options,
          correctIndex: correctIndex,
          audioUrl: block.audioUrl,
          sourceWordId: attribution.wordId,
          sourceSentenceId: attribution.sentenceId,
          isNonMemory: !attribution.hasCanonical,
        ),
      );
    }

    // Fallback: removed. A lesson with no generatable blocks yields an
    // empty quiz so the UI can fail closed ("Quiz unavailable") instead of
    // serving a fake lesson-title question. Lesson titles are never
    // learning questions.

    return QuizGenerationResult(
      quiz: QuizModel(
        id: 'dynamic_quiz_${lesson.id}',
        categoryId: lesson.categoryId,
        title: '${lesson.titleLatin} Quiz',
        questions: questions.take(10).toList(),
      ),
      lessonId: lesson.id,
      validBlockCount: validBlockCount,
      rejections: rejections,
    );
  }

  /// True when [block] carries an explicit translation for [lang]: either a
  /// `data.meaning_<lang>` entry or the dedicated `textHindi`/`textBengali`/
  /// `textOdia` field. Machine transliteration and romanized Santali do not
  /// count — they must never be presented as a Hindi/Bengali/Odia meaning.
  static bool hasExplicitMeaning(LessonBlockEntity block, String lang) {
    if (_getExplicitMeaning(block, lang).isNotEmpty) return true;
    final field = switch (lang) {
      'hi' => block.textHindi,
      'bn' => block.textBengali,
      'or' => block.textOdia,
      _ => null,
    };
    return field?.trim().isNotEmpty == true;
  }

  static String resolveBlockOption(
    LessonBlockEntity block,
    String lang, {
    required bool isAlphabet,
    required bool isNumber,
  }) {
    final latin = (block.textLatin ?? '').trim();
    final olChiki = (block.textOlChiki ?? '').trim();

    // 1. Alphabet category: sound or letter pronunciation
    if (isAlphabet) {
      if (lang == 'sat') {
        final parsed = OlChikiMultilingualHelper.parseCompositeLatin(latin);
        return parsed.phoneticLatin.isNotEmpty
            ? parsed.phoneticLatin
            : (latin.isNotEmpty ? latin : olChiki);
      }
      if (lang == 'bn') {
        if (block.textBengali?.trim().isNotEmpty == true) {
          return block.textBengali!.trim();
        }
        final t = OlChikiMultilingualHelper.transliterateOlChiki(olChiki, 'bn');
        if (t.isNotEmpty) return t;
      } else if (lang == 'hi') {
        if (block.textHindi?.trim().isNotEmpty == true) {
          return block.textHindi!.trim();
        }
        final t = OlChikiMultilingualHelper.transliterateOlChiki(olChiki, 'hi');
        if (t.isNotEmpty) return t;
      } else if (lang == 'or') {
        if (block.textOdia?.trim().isNotEmpty == true) {
          return block.textOdia!.trim();
        }
        final t = OlChikiMultilingualHelper.transliterateOlChiki(olChiki, 'or');
        if (t.isNotEmpty) return t;
      }
      // English / Latin fallback for alphabet
      return latin.isNotEmpty
          ? latin
          : OlChikiMultilingualHelper.toLatin(olChiki);
    }

    // 2. Number category
    if (isNumber) {
      if (lang == 'sat') return olChiki.isNotEmpty ? olChiki : latin;
      final meaning = _getExplicitMeaning(block, lang);
      if (meaning.isNotEmpty) return meaning;
      return latin;
    }

    // 3. Vocabulary / Sentences
    // First, check explicit translations in block.data
    final explicit = _getExplicitMeaning(block, lang);
    if (explicit.isNotEmpty) return explicit;

    // Next, check explicit Indic script fields on block
    if (lang == 'bn' && block.textBengali?.trim().isNotEmpty == true) {
      return block.textBengali!.trim();
    }
    if (lang == 'hi' && block.textHindi?.trim().isNotEmpty == true) {
      return block.textHindi!.trim();
    }
    if (lang == 'or' && block.textOdia?.trim().isNotEmpty == true) {
      return block.textOdia!.trim();
    }

    // Extract English meaning from composite Latin
    final parsed = OlChikiMultilingualHelper.parseCompositeLatin(latin);
    final rawMeaning = parsed.meaningEnglish.isNotEmpty
        ? parsed.meaningEnglish
        : latin;

    if (lang == 'en') {
      return latin;
    }

    if (lang == 'sat') {
      return parsed.phoneticLatin.isNotEmpty
          ? parsed.phoneticLatin
          : (latin.isNotEmpty ? latin : olChiki);
    }

    // Translate to target Indic language (hi, bn, or)
    final translated = OlChikiMultilingualHelper.translateMeaning(
      rawMeaning,
      lang,
    );
    if (translated.isNotEmpty) return translated;

    final display = OlChikiMultilingualHelper.resolveBlockDisplay(
      textOlChiki: olChiki,
      textLatin: latin,
      explicitMeaning: rawMeaning,
      teachingLanguage: lang,
      scriptMode: 'both',
    );
    if (display.meaning.isNotEmpty) return display.meaning;
    if (display.title.isNotEmpty && display.title != latin) {
      return display.title;
    }
    if (display.transliteration.isNotEmpty) return display.transliteration;

    return latin;
  }

  static String _getExplicitMeaning(LessonBlockEntity block, String lang) {
    if (block.data == null) return '';
    final langKey = 'meaning_${lang.toLowerCase()}';
    final localized = block.data![langKey];
    if (localized is String && localized.trim().isNotEmpty) {
      return localized.trim();
    }
    if (lang == 'en') {
      final en = block.data!['meaning_en'] ?? block.data!['meaning'];
      if (en is String && en.trim().isNotEmpty) {
        return en.trim();
      }
    }
    return '';
  }

  static String _numberPrompt(String lang) {
    switch (lang) {
      case 'hi':
        return 'यह संख्या पहचानें:';
      case 'bn':
        return 'এই সংখ্যাটি চিহ্নিত করুন:';
      case 'or':
        return 'ଏହି ସଂଖ୍ୟାଟି ଚିହ୍ନଟ କରନ୍ତୁ:';
      case 'sat':
        return 'ᱱᱚᱶᱟ ᱞᱮᱠᱷᱟ ᱪᱤᱱᱦᱟᱹᱣ ᱢᱮ:';
      case 'en':
      default:
        return 'Identify this number:';
    }
  }

  static String _letterPrompt(String lang) {
    switch (lang) {
      case 'hi':
        return 'इस अक्षर की ध्वनि पहचानें:';
      case 'bn':
        return 'এই বর্ণের উচ্চারণ চিহ্নিত করুন:';
      case 'or':
        return 'ଏହି ଅକ୍ଷରର ଉଚ୍ଚାରଣ ବାଛନ୍ତୁ:';
      case 'sat':
        return 'ᱱᱚᱶᱟ ᱪᱤᱠᱤ ᱨᱮᱭᱟᱜ ᱥᱟᱰᱮ ᱵᱟᱪᱷᱟᱣ ᱢᱮ:';
      case 'en':
      default:
        return 'Which sound does this letter make?';
    }
  }

  static String _meaningPrompt(String lang) {
    switch (lang) {
      case 'hi':
        return 'Choose the correct Hindi meaning:';
      case 'bn':
        return 'Choose the correct Bengali meaning:';
      case 'or':
        return 'Choose the correct Odia meaning:';
      case 'sat':
        return 'ᱥᱟᱹᱨᱤ ᱢᱮᱱᱮᱛ ᱵᱟᱪᱷᱟᱣ ᱢᱮ:';
      case 'en':
      default:
        return 'Choose the correct English meaning:';
    }
  }

  static List<String> fallbackDistractors(
    String lang,
    bool isNumber,
    bool isAlphabet,
  ) {
    if (isNumber) {
      switch (lang) {
        case 'bn':
          return ['১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
        case 'or':
          return ['୧', '୨', '୩', '୪', '୫', '୬', '୭', '୮', '୯'];
        case 'sat':
          return ['᱑', '᱒', '᱓', '᱔', '᱕', '᱖', '᱗', '᱘', '᱙'];
        default:
          return ['1', '2', '3', '4', '5', '6', '7', '8', '9'];
      }
    }
    if (isAlphabet) {
      switch (lang) {
        case 'hi':
          return ['अ', 'आ', 'इ', 'उ', 'ए', 'ओ', 'क', 'ग', 'त', 'म'];
        case 'bn':
          return ['অ', 'আ', 'ই', 'উ', 'এ', 'ও', 'ক', 'গ', 'ত', 'ম'];
        case 'or':
          return ['ଅ', 'ଆ', 'ଇ', 'ଉ', 'ଏ', 'ଓ', 'କ', 'ଗ', 'ତ', 'ମ'];
        case 'sat':
          return ['ᱚ', 'ᱛ', 'ᱜ', 'ᱝ', 'ᱞ', 'ᱟ', 'ᱠ', 'ᱡ', 'ᱢ', 'ᱣ'];
        case 'en':
        default:
          return ['a', 'at', 'ag', 'ang', 'al', 'ak', 'aj', 'am', 'aw'];
      }
    }
    switch (lang) {
      case 'hi':
        return [
          'पानी',
          'खाना',
          'घर',
          'पेड़',
          'हाथ',
          'पैर',
          'सिर',
          'आंख',
          'नदी',
          'किताब',
        ];
      case 'bn':
        return [
          'জল',
          'খাবার',
          'বাড়ি',
          'গাছ',
          'হাত',
          'পা',
          'মাথা',
          'চোখ',
          'নদী',
          'বই',
        ];
      case 'or':
        return [
          'ପାଣି',
          'ଖାଦ୍ୟ',
          'ଘର',
          'ଗଛ',
          'ହାତ',
          'ଗୋଡ଼',
          'ମୁଣ୍ଡ',
          'ଆଖି',
          'ନଦୀ',
          'ବହି',
        ];
      case 'sat':
        return [
          'ᱫᱟᱜ',
          'ᱫᱟᱠᱟ',
          'ᱚᱲᱟᱜ',
          'ᱫᱟᱨᱮ',
          'ᱛᱤ',
          'ᱡᱟᱸᱜᱟ',
          'ᱵᱚᱦᱚᱜ',
          'ᱢᱮᱫ',
          'ᱜᱟᱰᱟ',
        ];
      case 'en':
      default:
        return [
          'water',
          'food',
          'house',
          'tree',
          'hand',
          'leg',
          'head',
          'eye',
          'river',
          'book',
        ];
    }
  }
}
