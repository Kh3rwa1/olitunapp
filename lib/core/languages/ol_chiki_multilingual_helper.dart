import 'package:flutter/widgets.dart';
import 'indic_translations_dictionary.dart';
import 'ol_chiki_char_maps.dart';

/// Resolved localized presentation of an Ol Chiki learning item.
@immutable
class LocalizedItemDisplay {
  /// The primary script glyph / target text (Ol Chiki).
  final String scriptText;

  /// Transliterated pronunciation guide in the user's script (Bengali, Devanagari, Odia, Latin).
  final String transliteration;

  /// Meaning / explanation translated to the learner's chosen language (Bengali, Hindi, Odia, English).
  final String meaning;

  /// Combined subtitle for cards (e.g. "মনে খেল – মনের খেলা" or "Baba – Father").
  final String subtitle;

  /// Clean hero title (without repetitive clutter or leaked foreign text).
  final String title;

  /// Action button label (e.g. "শুনুন" / "सुनें" / "ଶୁଣନ୍ତୁ" / "LISTEN").
  final String ctaText;

  const LocalizedItemDisplay({
    required this.scriptText,
    required this.transliteration,
    required this.meaning,
    required this.subtitle,
    required this.title,
    required this.ctaText,
  });
}

/// Helper utility for transliterating Ol Chiki into regional Indic scripts
/// (Bengali, Hindi/Devanagari, Odia) and English/Latin, as well as resolving
/// localized meanings and clean subtitles with strict language isolation.
class OlChikiMultilingualHelper {
  const OlChikiMultilingualHelper._();

  /// Transliterates Ol Chiki text into [targetLang] script ('bn', 'hi', 'or', 'en')
  /// with intelligent Brahmic matras and multi-character aspirated digraph support.
  static String transliterateOlChiki(String olChikiText, String targetLang) {
    if (olChikiText.isEmpty) return '';

    final lang = targetLang.toLowerCase();
    if (lang == 'sat') return olChikiText;

    final Map<String, String> digraphMap;
    final Map<String, String> charMap;
    final Map<String, String> matraMap;

    switch (lang) {
      case 'bn':
      case 'bengali':
        digraphMap = OlChikiCharMaps.bengaliDigraphs;
        charMap = OlChikiCharMaps.toBengaliChar;
        matraMap = OlChikiCharMaps.bengaliMatra;
        break;
      case 'hi':
      case 'hindi':
        digraphMap = OlChikiCharMaps.hindiDigraphs;
        charMap = OlChikiCharMaps.toHindiChar;
        matraMap = OlChikiCharMaps.hindiMatra;
        break;
      case 'or':
      case 'odia':
        digraphMap = OlChikiCharMaps.odiaDigraphs;
        charMap = OlChikiCharMaps.toOdiaChar;
        matraMap = OlChikiCharMaps.odiaMatra;
        break;
      case 'en':
      case 'latin':
      default:
        digraphMap = OlChikiCharMaps.latinDigraphs;
        charMap = OlChikiCharMaps.toLatinChar;
        matraMap = const {};
        break;
    }

    final runesList = olChikiText.runes.toList();
    final buffer = StringBuffer();
    bool prevWasConsonant = false;

    for (int i = 0; i < runesList.length; i++) {
      final currentChar = String.fromCharCode(runesList[i]);

      // Check for 2-character digraph (e.g. ᱠᱷ, ᱜᱷ, ᱪᱷ, ᱢᱚ etc.)
      if (i + 1 < runesList.length) {
        final nextChar = String.fromCharCode(runesList[i + 1]);
        final pair = '$currentChar$nextChar';

        if (digraphMap.containsKey(pair)) {
          buffer.write(digraphMap[pair]);
          prevWasConsonant = true;
          i++; // Skip the second character of digraph
          continue;
        }
      }

      // Check vowels and matras
      if (matraMap.isNotEmpty && OlChikiCharMaps.vowels.contains(currentChar)) {
        if (prevWasConsonant) {
          buffer.write(
            matraMap[currentChar] ?? charMap[currentChar] ?? currentChar,
          );
        } else {
          buffer.write(charMap[currentChar] ?? currentChar);
        }
        prevWasConsonant = false;
      } else if (charMap.containsKey(currentChar)) {
        buffer.write(charMap[currentChar]);
        prevWasConsonant = OlChikiCharMaps.consonants.contains(currentChar);
      } else {
        buffer.write(currentChar);
        prevWasConsonant = false;
      }
    }

    return buffer.toString();
  }

  static String toBengali(String olChikiText) =>
      transliterateOlChiki(olChikiText, 'bn');
  static String toHindi(String olChikiText) =>
      transliterateOlChiki(olChikiText, 'hi');
  static String toOdia(String olChikiText) =>
      transliterateOlChiki(olChikiText, 'or');
  static String toLatin(String olChikiText) =>
      transliterateOlChiki(olChikiText, 'en');

  /// Translates an English meaning into the learner's chosen [targetLang].
  ///
  /// CRITICAL GUARANTEE: If [targetLang] is non-English ('bn', 'hi', 'or', 'sat')
  /// and no translation exists, this method returns an empty string `''`
  /// so that foreign English words NEVER leak into the non-English learning UI.
  static String translateMeaning(String englishMeaning, String targetLang) {
    final cleaned = englishMeaning.trim();
    if (cleaned.isEmpty) return '';
    if (targetLang == 'sat') return '';
    if (targetLang == 'en' || targetLang == 'latin') return cleaned;

    final lower = cleaned.toLowerCase();

    // 1. Direct dictionary match
    const dict = IndicTranslationsDictionary.translations;
    if (dict.containsKey(lower)) {
      final transMap = dict[lower]!;
      if (transMap.containsKey(targetLang) &&
          transMap[targetLang]!.isNotEmpty) {
        return transMap[targetLang]!;
      }
    }

    // 2. Slash-separated composite meanings (e.g. "Mind game / Flirting" -> "মনের খেলা / প্রেমভাব")
    if (cleaned.contains(' / ') || cleaned.contains('/')) {
      final slashParts = cleaned.split(RegExp(r'\s*/\s*'));
      final translatedParts = <String>[];
      bool allTranslated = true;

      for (final part in slashParts) {
        final sub = translateMeaning(part, targetLang);
        if (sub.isNotEmpty) {
          translatedParts.add(sub);
        } else {
          allTranslated = false;
        }
      }

      if (allTranslated && translatedParts.isNotEmpty) {
        return translatedParts.join(' / ');
      } else if (translatedParts.isNotEmpty) {
        return translatedParts.first;
      }
    }

    // 3. Prefix / Substring matching for phrases
    for (final entry in dict.entries) {
      if (lower == entry.key ||
          lower.startsWith('${entry.key} ') ||
          lower.contains(entry.key)) {
        if (entry.value.containsKey(targetLang) &&
            entry.value[targetLang]!.isNotEmpty) {
          if (lower == entry.key) return entry.value[targetLang]!;
        }
      }
    }

    // Strict non-English isolation: Do NOT fallback to English!
    return '';
  }

  /// Splits a composite string like "Baba – Father" or "Mone khel – Mind game / Flirting"
  /// into Romanized Santali + English Meaning parts.
  static ({String phoneticLatin, String meaningEnglish}) parseCompositeLatin(
    String rawLatin,
  ) {
    final trimmed = rawLatin.trim();
    if (trimmed.isEmpty) return (phoneticLatin: '', meaningEnglish: '');

    // Check for standard separators: ' – ', ' - ', ' — ', ': '
    final separators = [' – ', ' - ', ' — ', ': '];
    for (final sep in separators) {
      if (trimmed.contains(sep)) {
        final parts = trimmed.split(sep);
        if (parts.length >= 2) {
          final romanized = parts[0].trim();
          final meaning = parts.sublist(1).join(sep).trim();
          return (phoneticLatin: romanized, meaningEnglish: meaning);
        }
      }
    }

    // Lookup known single words if no separator
    final lower = trimmed.toLowerCase();
    const dict = IndicTranslationsDictionary.translations;
    if (dict.containsKey(lower)) {
      final meaning =
          dict[lower]?['en'] ??
          (trimmed[0].toUpperCase() + trimmed.substring(1));
      return (phoneticLatin: trimmed, meaningEnglish: meaning);
    }

    return (phoneticLatin: trimmed, meaningEnglish: '');
  }

  /// Master resolver that computes the presentation details for any lesson block, word, or sentence
  /// according to the learner's active [teachingLanguage] ('bn', 'hi', 'or', 'en', 'sat')
  /// and [scriptMode] ('both', 'olchiki', 'latin').
  ///
  /// Zero-English Leakage Invariant:
  /// When [teachingLanguage] is 'bn', 'hi', 'or', or 'sat', no English text will ever appear
  /// in the title or subtitle.
  static LocalizedItemDisplay resolveBlockDisplay({
    String? textOlChiki,
    String? textLatin,
    String? textBengali,
    String? textHindi,
    String? textOdia,
    String? explicitMeaning,
    String? explicitPronunciation,
    required String teachingLanguage,
    required String scriptMode,
  }) {
    final olChiki = (textOlChiki ?? '').trim();
    final latin = (textLatin ?? '').trim();

    // 1. Separate Romanized Santali and English Meaning from composite textLatin
    final parsed = parseCompositeLatin(latin);
    final englishMeaning = (explicitMeaning?.trim().isNotEmpty == true)
        ? explicitMeaning!.trim()
        : parsed.meaningEnglish;
    final romanizedSantali = parsed.phoneticLatin.isNotEmpty
        ? parsed.phoneticLatin
        : latin;

    // 2. Resolve Transliteration according to teaching language
    String transliteration;
    switch (teachingLanguage) {
      case 'bn':
        transliteration = (textBengali != null && textBengali.trim().isNotEmpty)
            ? textBengali.trim()
            : (olChiki.isNotEmpty
                  ? transliterateOlChiki(olChiki, 'bn')
                  : romanizedSantali);
        break;
      case 'hi':
        transliteration = (textHindi != null && textHindi.trim().isNotEmpty)
            ? textHindi.trim()
            : (olChiki.isNotEmpty
                  ? transliterateOlChiki(olChiki, 'hi')
                  : romanizedSantali);
        break;
      case 'or':
        transliteration = (textOdia != null && textOdia.trim().isNotEmpty)
            ? textOdia.trim()
            : (olChiki.isNotEmpty
                  ? transliterateOlChiki(olChiki, 'or')
                  : romanizedSantali);
        break;
      case 'sat':
        transliteration = '';
        break;
      case 'en':
      default:
        transliteration = romanizedSantali;
        break;
    }

    // 3. Resolve Localized Meaning (Strictly Native, Zero Leakage)
    final String localizedMeaning;
    if (teachingLanguage == 'sat') {
      localizedMeaning = '';
    } else if (teachingLanguage == 'en') {
      localizedMeaning = englishMeaning;
    } else {
      localizedMeaning = translateMeaning(englishMeaning, teachingLanguage);
    }

    // 4. Construct Subtitle
    String subtitle;
    if (scriptMode == 'olchiki' || teachingLanguage == 'sat') {
      subtitle = '';
    } else if (transliteration.isNotEmpty && localizedMeaning.isNotEmpty) {
      subtitle = '$transliteration – $localizedMeaning';
    } else if (transliteration.isNotEmpty) {
      subtitle = transliteration;
    } else {
      subtitle = localizedMeaning;
    }

    // 5. Construct Clean Title (Hero/Header)
    final String title;
    if (teachingLanguage == 'sat') {
      title = olChiki.isNotEmpty ? olChiki : romanizedSantali;
    } else if (localizedMeaning.isNotEmpty) {
      title = localizedMeaning;
    } else if (transliteration.isNotEmpty) {
      title = transliteration;
    } else {
      title = olChiki;
    }

    // 6. Action Button CTA text
    final String ctaText;
    switch (teachingLanguage) {
      case 'bn':
        ctaText = 'শুনুন';
        break;
      case 'hi':
        ctaText = 'सुनें';
        break;
      case 'or':
        ctaText = 'ଶୁଣନ୍ତୁ';
        break;
      case 'sat':
        ctaText = 'ᱟᱸᱡᱚᱢ';
        break;
      case 'en':
      default:
        ctaText = 'LISTEN';
        break;
    }

    return LocalizedItemDisplay(
      scriptText: olChiki,
      transliteration: transliteration,
      meaning: localizedMeaning,
      subtitle: subtitle,
      title: title,
      ctaText: ctaText,
    );
  }
}
