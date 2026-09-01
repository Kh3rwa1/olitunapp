import 'package:flutter/widgets.dart';
import 'indic_translations_dictionary.dart';
import 'ol_chiki_char_maps.dart';

/// Resolved localized presentation of an Ol Chiki learning item.
@immutable
class LocalizedItemDisplay {
  /// The primary script glyph / target text (Ol Chiki) in center.
  final String scriptText;

  /// Transliterated pronunciation guide in the user's script (Bengali, Devanagari, Odia, Latin).
  final String transliteration;

  /// Meaning / explanation translated to the learner's chosen language (Bengali, Hindi, Odia, English).
  final String meaning;

  /// Subtitle shown under the Ol Chiki card (strictly the pronunciation guide transliteration).
  final String subtitle;

  /// Hero title shown at the top (strictly the translated Meaning in the user's language).
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

  /// Cleans any foreign Latin annotations, dashes, or parenthetical descriptions
  /// from a contaminated Ol Chiki string (e.g. "ᱪᱮᱫ - Ched (What?)" -> "ᱪᱮᱫ").
  static String sanitizeOlChiki(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';

    // If string has both Ol Chiki runes and Latin characters
    if (trimmed.runes.any((r) => r >= 0x1C50 && r <= 0x1C7F) &&
        RegExp(r'[a-zA-Z]').hasMatch(trimmed)) {
      final match = RegExp(r'^([\u1C50-\u1C7F\s\-–\.]+)').firstMatch(trimmed);
      if (match != null && match.group(1)!.trim().isNotEmpty) {
        return match
            .group(1)!
            .trim()
            .replaceAll(RegExp(r'[\-–—:\s]+$'), '')
            .trim();
      }
    }
    return trimmed;
  }

  /// Transliterates Ol Chiki text into [targetLang] script ('bn', 'hi', 'or', 'en')
  /// with intelligent Brahmic matras and multi-character aspirated digraph support.
  static String transliterateOlChiki(String olChikiText, String targetLang) {
    final cleanText = sanitizeOlChiki(olChikiText);
    if (cleanText.isEmpty) return '';

    final lang = targetLang.toLowerCase();
    if (lang == 'sat') return cleanText;

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

    final runesList = cleanText.runes.toList();
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
    final direct = IndicTranslationsDictionary.lookup(lower, targetLang);
    if (direct != null && direct.isNotEmpty) {
      return direct;
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

    // Strict non-English isolation: Do NOT fallback to English!
    return '';
  }

  /// Splits a composite string like "Baba – Father" or "Ched – Used to ask about things"
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
          var meaning = parts.sublist(1).join(sep).trim();

          // Clean grammatical descriptions to concise terms
          final lowerMeaning = meaning.toLowerCase();
          if (lowerMeaning.startsWith('used to ask about things') ||
              lowerMeaning.startsWith('ask about things')) {
            meaning = 'What?';
          } else if (lowerMeaning.startsWith('used to ask about people')) {
            meaning = 'Who?';
          } else if (lowerMeaning.startsWith('used to ask about places')) {
            meaning = 'Which / Where?';
          } else if (lowerMeaning.startsWith('used to ask about time')) {
            meaning = 'When?';
          } else if (lowerMeaning.startsWith('used to ask about condition')) {
            meaning = 'How?';
          } else if (lowerMeaning.startsWith('first person singular')) {
            meaning = 'I / Me';
          } else if (lowerMeaning.startsWith('second person singular')) {
            meaning = 'You';
          } else if (lowerMeaning.startsWith('third person singular')) {
            meaning = 'He / She';
          } else if (lowerMeaning.startsWith('we (including the listener)')) {
            meaning = 'We all (inclusive)';
          } else if (lowerMeaning.startsWith('we (excluding the listener)')) {
            meaning = 'We (exclusive)';
          } else if (lowerMeaning.startsWith('second person plural')) {
            meaning = 'You all';
          } else if (lowerMeaning.startsWith('third person plural')) {
            meaning = 'They';
          }

          return (phoneticLatin: romanized, meaningEnglish: meaning);
        }
      }
    }

    // Check for parenthesized meaning: e.g. "Iny (I / Me)" or "Ched (What?)"
    final parenMatch = RegExp(r'^([^(]+)\s*\(([^)]+)\)$').firstMatch(trimmed);
    if (parenMatch != null) {
      final romanized = parenMatch.group(1)!.trim();
      final meaning = parenMatch.group(2)!.trim();
      return (phoneticLatin: romanized, meaningEnglish: meaning);
    }

    // Lookup known single words if no separator
    final lower = trimmed.toLowerCase();
    final direct = IndicTranslationsDictionary.lookup(lower, 'en');
    if (direct != null && direct.isNotEmpty) {
      return (phoneticLatin: trimmed, meaningEnglish: direct);
    }

    return (phoneticLatin: trimmed, meaningEnglish: '');
  }

  /// Master resolver that computes the 3-section layout for any lesson block, word, or sentence:
  ///
  /// - Top Section ([LocalizedItemDisplay.title]): Meaning in user's language (Bengali, Hindi, Odia, English).
  /// - Middle Section ([LocalizedItemDisplay.scriptText]): Target Ol Chiki text.
  /// - Bottom Section ([LocalizedItemDisplay.subtitle]): Pronunciation guide transliterated into user's script, centered.
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
    final rawOlChiki = (textOlChiki ?? '').trim();
    final olChiki = sanitizeOlChiki(rawOlChiki);
    final latin = (textLatin ?? '').trim();

    // 1. Separate Romanized Santali and English Meaning from composite textLatin
    final parsed = parseCompositeLatin(latin);
    var englishMeaning = (explicitMeaning?.trim().isNotEmpty == true)
        ? explicitMeaning!.trim()
        : parsed.meaningEnglish;

    // Check if rawOlChiki contained a parenthesized meaning like "ᱪᱮᱫ - Ched (What?)"
    if (englishMeaning.isEmpty && rawOlChiki.contains('(')) {
      final parenMatch = RegExp(r'\(([^)]+)\)').firstMatch(rawOlChiki);
      if (parenMatch != null) {
        englishMeaning = parenMatch.group(1)!.trim();
      }
    }

    final romanizedSantali = parsed.phoneticLatin.isNotEmpty
        ? parsed.phoneticLatin
        : (latin.isNotEmpty ? latin : toLatin(olChiki));

    // 2. Resolve Transliteration (Pronunciation Guide in learner's script)
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

    // 3. Resolve Localized Meaning (User's language definition)
    final String localizedMeaning;
    if (teachingLanguage == 'sat') {
      localizedMeaning = '';
    } else if (teachingLanguage == 'en') {
      localizedMeaning = englishMeaning;
    } else {
      localizedMeaning = translateMeaning(englishMeaning, teachingLanguage);
    }

    // 4. Bottom Section Subtitle: strictly the clean pronunciation transliteration
    final String subtitle;
    if (scriptMode == 'olchiki' || teachingLanguage == 'sat') {
      subtitle = '';
    } else {
      subtitle = transliteration;
    }

    // 5. Top Section Title: strictly the Meaning in the user's language!
    final String title;
    if (teachingLanguage == 'sat') {
      title = olChiki.isNotEmpty ? olChiki : romanizedSantali;
    } else if (localizedMeaning.isNotEmpty) {
      title = localizedMeaning;
    } else {
      // If meaning not translated, fallback to romanized Santali, never duplicating the Indic transliteration
      title = romanizedSantali.isNotEmpty ? romanizedSantali : olChiki;
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
