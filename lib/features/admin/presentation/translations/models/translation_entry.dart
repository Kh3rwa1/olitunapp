import 'package:itun/core/languages/ol_chiki_multilingual_helper.dart';

enum TranslationKind { word, sentence, lesson, category, rhyme }

class TranslationEntry {
  final String id;
  final TranslationKind kind;
  final String textOlChiki;
  final String textLatin;
  final String englishMeaning;
  final String? pronunciation;
  final String? category;
  final String? audioUrl;
  final Map<String, String>? customTranslations;

  const TranslationEntry({
    required this.id,
    required this.kind,
    required this.textOlChiki,
    required this.textLatin,
    required this.englishMeaning,
    this.pronunciation,
    this.category,
    this.audioUrl,
    this.customTranslations,
  });

  String get kindLabel => switch (kind) {
    TranslationKind.word => 'Word',
    TranslationKind.sentence => 'Sentence',
    TranslationKind.lesson => 'Lesson',
    TranslationKind.category => 'Category',
    TranslationKind.rhyme => 'Rhyme & Story',
  };

  String meaningFor(String lang) {
    if (lang == 'sat') return '';
    if (lang == 'en') {
      return englishMeaning.isNotEmpty ? englishMeaning : textLatin;
    }
    if (customTranslations != null &&
        customTranslations!.containsKey(lang) &&
        customTranslations![lang]!.trim().isNotEmpty) {
      return customTranslations![lang]!;
    }
    final translated = OlChikiMultilingualHelper.translateMeaning(
      englishMeaning,
      lang,
    );
    if (translated.isNotEmpty) return translated;
    return OlChikiMultilingualHelper.translateMeaning(textLatin, lang);
  }

  String transliterationFor(String lang) {
    if (lang == 'sat') return textOlChiki;
    if (lang == 'en') {
      return pronunciation?.isNotEmpty == true
          ? pronunciation!
          : OlChikiMultilingualHelper.transliterateOlChiki(textOlChiki, 'en');
    }
    return OlChikiMultilingualHelper.transliterateOlChiki(textOlChiki, lang);
  }

  bool isTranslatedFor(String lang) {
    if (lang == 'sat') return textOlChiki.isNotEmpty;
    if (lang == 'en') {
      return englishMeaning.isNotEmpty || textLatin.isNotEmpty;
    }
    final m = meaningFor(lang);
    return m.isNotEmpty &&
        m.toLowerCase() != englishMeaning.toLowerCase() &&
        m.toLowerCase() != textLatin.toLowerCase();
  }
}
