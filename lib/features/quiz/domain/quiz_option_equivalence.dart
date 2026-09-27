import 'dart:math';

import '../../../shared/utils/santali_number_names.dart';
import '../../../shared/utils/santali_numbers.dart';

/// Centralized semantic equivalence and option-building logic for quiz questions.
///
/// Invariants enforced:
/// 1. Exactly 4 unique, non-equivalent options are presented to the learner.
/// 2. Numerically equivalent options (e.g. "সাত (৭)" vs "৭" vs "সাত") are
///    recognized as the same number and never duplicated within a question.
/// 3. Options from the lesson itself are prioritized so that the question maintains
///    consistent formatting (e.g. all options showing "Word (Numeral)").
/// 4. Fallback distractors are drawn only when the lesson has fewer than 3 valid
///    distractors, matching the question's format.
/// 5. A learner selecting an equivalent valid representation of the correct answer
///    is recognized as correct rather than penalized.
class QuizOptionEquivalence {
  const QuizOptionEquivalence._();

  static const String _digitPatternStr =
      r'[\d\u1C50-\u1C59\u09E6-\u09EF\u0966-\u096F\u0B66-\u0B6F]';

  /// Converts a string composed of digits in supported scripts to an integer 0..100.
  static int? _digitsToDecimal(String digitStr) {
    final buffer = StringBuffer();
    for (final rune in digitStr.runes) {
      if (rune >= 0x1C50 && rune <= 0x1C59) {
        buffer.write(rune - 0x1C50);
      } else if (rune >= 0x09E6 && rune <= 0x09EF) {
        buffer.write(rune - 0x09E6);
      } else if (rune >= 0x0966 && rune <= 0x096F) {
        buffer.write(rune - 0x0966);
      } else if (rune >= 0x0B66 && rune <= 0x0B6F) {
        buffer.write(rune - 0x0B66);
      } else if (rune >= 0x30 && rune <= 0x39) {
        buffer.write(rune - 0x30);
      }
    }
    if (buffer.isEmpty) return null;
    return int.tryParse(buffer.toString());
  }

  /// Attempts to extract an integer 0..100 from an option string.
  ///
  /// Distinguishes legitimate numbers from alphanumeric codes (like 'A0', 'B1'):
  /// - Pure digits (e.g. "7", "৭", "৭", "100")
  /// - Parenthesized numeral (e.g. "সাত (৭)", "Seven (7)")
  /// - Dash format (e.g. "7 – Seven", "21 – Bar Gel Mit")
  /// - Recognized number words ("সাত", "Seven", "सात", "ଏୟାୟ")
  static int? extractNumberValue(String? text) {
    if (text == null) return null;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    // 1. Pure digits (with optional whitespace)
    final pureDigitsRegex = RegExp('^\\s*$_digitPatternStr+\\s*\$');
    if (pureDigitsRegex.hasMatch(trimmed)) {
      final val = _digitsToDecimal(trimmed);
      if (val != null && val >= 0 && val <= 100) return val;
    }

    // 2. Parenthesized numeral: "Word (Numeral)"
    final parenRegex = RegExp(r'\(\s*(' + _digitPatternStr + r'+)\s*\)');
    final parenMatch = parenRegex.firstMatch(trimmed);
    if (parenMatch != null) {
      final val = _digitsToDecimal(parenMatch.group(1)!);
      if (val != null && val >= 0 && val <= 100) return val;
    }

    // 3. Dash format: "Numeral – Word" or "Word – Numeral"
    final dashPrefixRegex = RegExp(r'^\s*(' + _digitPatternStr + r'+)\s*[–-]');
    final dashPrefixMatch = dashPrefixRegex.firstMatch(trimmed);
    if (dashPrefixMatch != null) {
      final val = _digitsToDecimal(dashPrefixMatch.group(1)!);
      if (val != null && val >= 0 && val <= 100) return val;
    }

    final dashSuffixRegex = RegExp(r'[–-]\s*(' + _digitPatternStr + r'+)\s*$');
    final dashSuffixMatch = dashSuffixRegex.firstMatch(trimmed);
    if (dashSuffixMatch != null) {
      final val = _digitsToDecimal(dashSuffixMatch.group(1)!);
      if (val != null && val >= 0 && val <= 100) return val;
    }

    // If alphanumeric code like "A0", "B1", "Q2", reject immediately
    if (RegExp(r'^[A-Za-z]\d+$').hasMatch(trimmed)) {
      return null;
    }

    // 4. Known number words (when no digits present)
    final clean = trimmed.toLowerCase();

    final bnIdx = SantaliNumberNames.bengali.indexWhere(
      (w) => w.toLowerCase() == clean,
    );
    if (bnIdx >= 0) return bnIdx;

    final hiIdx = SantaliNumberNames.hindi.indexWhere(
      (w) => w.toLowerCase() == clean,
    );
    if (hiIdx >= 0) return hiIdx;

    final orIdx = SantaliNumberNames.odia.indexWhere(
      (w) => w.toLowerCase() == clean,
    );
    if (orIdx >= 0) return orIdx;

    for (var i = 0; i <= 100; i++) {
      if (SantaliNumbers.englishName(i).toLowerCase() == clean) return i;
      if (SantaliNumbers.nameOlChiki(i).toLowerCase() == clean) return i;
      if (SantaliNumbers.nameLatin(i).toLowerCase() == clean) return i;
    }

    return null;
  }

  /// Determines whether two options represent the same semantic answer.
  static bool areEquivalent(
    String a,
    String b, {
    bool isNumber = false,
    bool isAlphabet = false,
  }) {
    final cleanA = a.trim();
    final cleanB = b.trim();
    if (cleanA.isEmpty || cleanB.isEmpty) return false;

    // Exact case-insensitive match
    if (cleanA.toLowerCase() == cleanB.toLowerCase()) return true;

    // Number semantic equivalence (by numeric value 0..100)
    if (isNumber) {
      final numA = extractNumberValue(cleanA);
      final numB = extractNumberValue(cleanB);
      if (numA != null && numB != null && numA == numB) {
        return true;
      }
    }

    // Composite decomposition: e.g. "সাত (৭)" vs "৭" or "সাত"
    if (_matchesComposite(cleanA, cleanB) ||
        _matchesComposite(cleanB, cleanA)) {
      return true;
    }

    // Alphabet / sound equivalence (e.g. "a" vs "a (ᱚ)")
    if (isAlphabet) {
      final strippedA = cleanA
          .replaceAll(RegExp(r'[\s()–\-]'), '')
          .toLowerCase();
      final strippedB = cleanB
          .replaceAll(RegExp(r'[\s()–\-]'), '')
          .toLowerCase();
      if (strippedA.isNotEmpty && strippedA == strippedB) return true;
    }

    return false;
  }

  static bool _matchesComposite(String composite, String target) {
    final targetClean = target.trim().toLowerCase();
    if (targetClean.isEmpty) return false;

    // 1. Parenthesized: "Word (Sub)" -> matches "Word" or "Sub"
    final parenMatch = RegExp(r'^([^(]+)\s*\(([^)]+)\)$').firstMatch(composite);
    if (parenMatch != null) {
      final outer = parenMatch.group(1)!.trim().toLowerCase();
      final inner = parenMatch.group(2)!.trim().toLowerCase();
      if (targetClean == outer || targetClean == inner) return true;
    }

    // 2. Dash-separated: "Prefix – Suffix" -> matches "Prefix" or "Suffix"
    final dashMatch = RegExp(
      r'^([^–-]+)\s*[–-]\s*([^–-]+)$',
    ).firstMatch(composite);
    if (dashMatch != null) {
      final part1 = dashMatch.group(1)!.trim().toLowerCase();
      final part2 = dashMatch.group(2)!.trim().toLowerCase();
      if (targetClean == part1 || targetClean == part2) return true;
    }

    return false;
  }

  /// Builds a list of 4 options containing [correctOption] and 3 distinct distractors.
  static List<String> buildOptions({
    required String correctOption,
    required List<String> lessonOptions,
    required bool isNumber,
    required bool isAlphabet,
    required List<String> Function() getFallbackDistractors,
    Random? rng,
  }) {
    if (correctOption.trim().isEmpty) return const [];

    final selectedDistractors = <String>[];

    // 1. Gather other items from the same lesson
    final shuffledLesson = List<String>.from(lessonOptions)..shuffle(rng);
    for (final opt in shuffledLesson) {
      if (opt.trim().isEmpty) continue;
      if (areEquivalent(
        opt,
        correctOption,
        isNumber: isNumber,
        isAlphabet: isAlphabet,
      )) {
        continue;
      }
      if (selectedDistractors.any(
        (d) =>
            areEquivalent(d, opt, isNumber: isNumber, isAlphabet: isAlphabet),
      )) {
        continue;
      }
      selectedDistractors.add(opt);
      if (selectedDistractors.length == 3) break;
    }

    // 2. Only if fewer than 3 distractors were found, draw from fallback
    if (selectedDistractors.length < 3) {
      final fallbacks = getFallbackDistractors()..shuffle(rng);
      for (final fb in fallbacks) {
        if (fb.trim().isEmpty) continue;
        if (areEquivalent(
          fb,
          correctOption,
          isNumber: isNumber,
          isAlphabet: isAlphabet,
        )) {
          continue;
        }
        if (selectedDistractors.any(
          (d) =>
              areEquivalent(d, fb, isNumber: isNumber, isAlphabet: isAlphabet),
        )) {
          continue;
        }
        selectedDistractors.add(fb);
        if (selectedDistractors.length == 3) break;
      }
    }

    if (selectedDistractors.length < 3) {
      return const [];
    }

    final options = [correctOption, ...selectedDistractors]..shuffle(rng);
    return options;
  }
}
