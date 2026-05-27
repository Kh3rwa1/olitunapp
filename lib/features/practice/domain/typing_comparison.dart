import 'package:equatable/equatable.dart';

class TypingComparisonResult extends Equatable {
  final int matchedPrefixLength;
  final bool isComplete;
  final int? mistakeAtIndex;
  final String? expectedNextChar;

  const TypingComparisonResult({
    required this.matchedPrefixLength,
    required this.isComplete,
    this.mistakeAtIndex,
    this.expectedNextChar,
  });

  @override
  List<Object?> get props => [
    matchedPrefixLength,
    isComplete,
    mistakeAtIndex,
    expectedNextChar,
  ];
}

class TypingComparison {
  // Ol Chiki Unicode range: U+1C50 to U+1C7F (which contains 0-9 and letters)
  // Plus space, Danda (। - U+0964), Latin digits 0-9, and standard terminal punctuation for fallback/normalization support
  static final RegExp _validCharsRegex = RegExp(
    r'^[\s\u1C50-\u1C7F\u09640-9.!?]+$',
  );

  static bool isValidInputChar(String char) {
    if (char.isEmpty) return false;
    return _validCharsRegex.hasMatch(char);
  }

  static String _normalizeDigits(String input) {
    return input
        .replaceAll('0', '\u1C50')
        .replaceAll('1', '\u1C51')
        .replaceAll('2', '\u1C52')
        .replaceAll('3', '\u1C53')
        .replaceAll('4', '\u1C54')
        .replaceAll('5', '\u1C55')
        .replaceAll('6', '\u1C56')
        .replaceAll('7', '\u1C57')
        .replaceAll('8', '\u1C58')
        .replaceAll('9', '\u1C59');
  }

  static TypingComparisonResult compareInput(
    String typed,
    String target, {
    bool lenientPunctuation = true,
  }) {
    if (target.isEmpty) {
      throw ArgumentError('Target string cannot be empty.');
    }

    // 1. NFC Normalization (Composed/Decomposed forms)
    // Note: In pure Dart, strings are typically NFC unless constructed manually.
    // Standard compose/decompose normalization can be approximated or handled via standard string operations.
    // For Ol Chiki, the characters are mostly single code points (U+1C50 to U+1C7F)
    // with no multi-byte diacritics requiring complex NFC decomposition/composition.
    // Standard normalize operation is a clean trim and whitespace collapse:
    String normTyped = _normalizeDigits(
      typed.trim().replaceAll(RegExp(r'\s+'), ' '),
    );
    String normTarget = _normalizeDigits(
      target.trim().replaceAll(RegExp(r'\s+'), ' '),
    );

    // 2. Reject non-Ol-Chiki characters in typed string
    if (normTyped.isNotEmpty && !_validCharsRegex.hasMatch(normTyped)) {
      // Find the first invalid index in typed
      int firstInvalidIdx = -1;
      for (int i = 0; i < normTyped.length; i++) {
        if (!_validCharsRegex.hasMatch(normTyped[i])) {
          firstInvalidIdx = i;
          break;
        }
      }
      return TypingComparisonResult(
        matchedPrefixLength: 0,
        isComplete: false,
        mistakeAtIndex: firstInvalidIdx >= 0 ? firstInvalidIdx : 0,
        expectedNextChar: normTarget.isNotEmpty ? normTarget[0] : null,
      );
    }

    // 3. Lenient Punctuation Handling
    if (lenientPunctuation) {
      final trailingPunc = RegExp(r'[\u0964\.\!\?\s]+$');
      normTyped = normTyped.replaceAll(trailingPunc, '');
      normTarget = normTarget.replaceAll(trailingPunc, '');
    }

    // If normalized target is empty after stripping (e.g. it was just punctuation),
    // then an empty or punctuation-only input counts as complete.
    if (normTarget.isEmpty) {
      return const TypingComparisonResult(
        matchedPrefixLength: 0,
        isComplete: true,
      );
    }

    // 4. Prefix Matching and Mistake Detection
    int matchedLength = 0;
    int? mistakeIdx;

    for (int i = 0; i < normTyped.length; i++) {
      if (i >= normTarget.length) {
        // Typed more characters than the target
        mistakeIdx = i;
        break;
      }

      if (normTyped[i] == normTarget[i]) {
        matchedLength++;
      } else {
        // First mistake found
        mistakeIdx = i;
        break;
      }
    }

    final bool isComplete =
        matchedLength == normTarget.length && mistakeIdx == null;
    final String? expectedNext =
        (isComplete || matchedLength >= normTarget.length)
        ? null
        : normTarget[matchedLength];

    return TypingComparisonResult(
      matchedPrefixLength: matchedLength,
      isComplete: isComplete,
      mistakeAtIndex: mistakeIdx,
      expectedNextChar: expectedNext,
    );
  }
}
