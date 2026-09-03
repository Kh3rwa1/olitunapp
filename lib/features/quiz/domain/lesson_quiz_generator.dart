import '../../../core/languages/ol_chiki_multilingual_helper.dart';
import '../../../shared/models/content_models.dart';
import '../../lessons/domain/entities/lesson_entity.dart';

class LessonQuizGenerator {
  const LessonQuizGenerator._();

  static QuizModel generate(
    LessonEntity lesson, {
    String teachingLanguage = 'en',
    String scriptMode = 'both',
    String targetLanguage = 'sat',
  }) {
    final questions = <QuizQuestion>[];
    final blocks = lesson.blocks.where((b) => b.type != 'quiz').toList();

    final isNumberCategory = lesson.categoryId.toLowerCase().contains('number');
    final isAlphabetCategory =
        lesson.categoryId.toLowerCase().contains('alphabet') ||
        lesson.categoryId.toLowerCase().contains('letter');

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

    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      final olChiki = block.textOlChiki?.trim();
      final latin = block.textLatin?.trim();

      if (olChiki == null ||
          olChiki.isEmpty ||
          latin == null ||
          latin.isEmpty) {
        continue;
      }

      final correctOption = resolveBlockOption(
        block,
        teachingLanguage,
        isAlphabet: isAlphabetCategory,
        isNumber: isNumberCategory,
      );
      if (correctOption.isEmpty) continue;

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

      final promptLatin = isNumberCategory
          ? _numberPrompt(teachingLanguage)
          : (isAlphabetCategory
                ? _letterPrompt(teachingLanguage)
                : _meaningPrompt(teachingLanguage));

      questions.add(
        QuizQuestion(
          promptOlChiki: olChiki,
          promptLatin: promptLatin,
          optionsOlChiki: options,
          optionsLatin: options,
          correctIndex: correctIndex,
          audioUrl: block.audioUrl,
        ),
      );
    }

    // Fallback: If no interactive blocks could be extracted, generate a lesson-title question
    if (questions.isEmpty) {
      final fallbackPrompt = _titlePrompt(teachingLanguage);
      final fallbackOptions = _titleFallbackOptions(
        lesson.titleLatin,
        teachingLanguage,
      );
      questions.add(
        QuizQuestion(
          promptOlChiki: lesson.titleOlChiki,
          promptLatin: fallbackPrompt,
          optionsOlChiki: fallbackOptions,
          optionsLatin: fallbackOptions,
        ),
      );
    }

    return QuizModel(
      id: 'dynamic_quiz_${lesson.id}',
      categoryId: lesson.categoryId,
      title: '${lesson.titleLatin} Quiz',
      questions: questions.take(10).toList(),
    );
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

  static String _titlePrompt(String lang) {
    switch (lang) {
      case 'hi':
        return 'Choose the correct Hindi title for this lesson:';
      case 'bn':
        return 'Choose the correct Bengali title for this lesson:';
      case 'or':
        return 'Choose the correct Odia title for this lesson:';
      case 'sat':
        return 'ᱱᱚᱶᱟ ᱯᱟᱲᱦᱟᱣ ᱨᱮᱭᱟᱜ ᱧᱩᱛᱩᱢ ᱵᱟᱪᱷᱟᱣ ᱢᱮ:';
      case 'en':
      default:
        return 'Choose the correct English title for this lesson:';
    }
  }

  static List<String> _titleFallbackOptions(String title, String lang) {
    switch (lang) {
      case 'hi':
        return [title, 'अन्य पाठ', 'अभ्यास', 'समीक्षा'];
      case 'bn':
        return [title, 'অন্য পাঠ', 'অনুশীলন', 'পর্যালোচনা'];
      case 'or':
        return [title, 'ଅନ୍ୟ ପାଠ', 'ଅଭ୍ୟାସ', 'ସମୀକ୍ଷା'];
      case 'sat':
        return [title, 'ᱮᱴᱟᱜ ᱯᱟᱲᱦᱟᱣ', 'ᱯᱨᱟᱠᱴᱤᱥ', 'ᱨᱩᱣᱟᱹᱲ'];
      case 'en':
      default:
        return [title, 'Other Lesson', 'Practice', 'Review'];
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
