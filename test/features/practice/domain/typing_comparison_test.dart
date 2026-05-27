import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/practice/domain/typing_comparison.dart';

void main() {
  group('TypingComparison', () {
    // Helper to generate Ol Chiki characters safely
    // ᱚ U+1C5A, ᱟ U+1C5B, ᱤ U+1C5C, ᱩ U+1C5D
    const ol1 = '\u1C5A\u1C5B\u1C5C'; // ᱚᱟᱤ
    const ol2 = '\u1C5A\u1C5B\u1C5D'; // ᱚᱟᱩ

    test('1. Exact match of pure Ol Chiki text', () {
      final result = TypingComparison.compareInput(ol1, ol1);
      expect(result.isComplete, isTrue);
      expect(result.matchedPrefixLength, 3);
      expect(result.mistakeAtIndex, isNull);
      expect(result.expectedNextChar, isNull);
    });

    test('2. Partial matched prefix', () {
      final result = TypingComparison.compareInput('\u1C5A\u1C5B', ol1);
      expect(result.isComplete, isFalse);
      expect(result.matchedPrefixLength, 2);
      expect(result.mistakeAtIndex, isNull);
      expect(result.expectedNextChar, '\u1C5C');
    });

    test('3. First mistake at index detected', () {
      final result = TypingComparison.compareInput('\u1C5A\u1C5D', ol1); // Second char is incorrect
      expect(result.isComplete, isFalse);
      expect(result.matchedPrefixLength, 1);
      expect(result.mistakeAtIndex, 1);
      expect(result.expectedNextChar, '\u1C5B');
    });

    test('4. Mixed script targets with Ol Chiki and allowed punctuation', () {
      const target = '$ol1\u0964'; // ᱚᱟᱤ।
      final result = TypingComparison.compareInput(target, target);
      expect(result.isComplete, isTrue);
      expect(result.matchedPrefixLength, 3);
    });

    test('5. Rejects completely invalid characters (Latin alphabet)', () {
      final result = TypingComparison.compareInput('abc', ol1);
      expect(result.isComplete, isFalse);
      expect(result.matchedPrefixLength, 0);
      expect(result.mistakeAtIndex, 0);
      expect(result.expectedNextChar, '\u1C5A');
    });

    test('6. Rejects partially invalid character within valid input', () {
      final result = TypingComparison.compareInput('\u1C5A\u1C5Babc', ol1);
      expect(result.isComplete, isFalse);
      expect(result.matchedPrefixLength, 0);
      expect(result.mistakeAtIndex, 2); // 'a' is at index 2
    });

    test('7. Lenient punctuation strips terminal punctuation', () {
      const typed = '$ol1 '; // trailing space
      const target = '$ol1\u0964'; // target has trailing Danda ।
      final result = TypingComparison.compareInput(typed, target, lenientPunctuation: true);
      expect(result.isComplete, isTrue);
      expect(result.matchedPrefixLength, 3);
    });

    test('8. Lenient punctuation works with periods and exclamation marks', () {
      const typed = '$ol1!';
      const target = '$ol1.';
      final result = TypingComparison.compareInput(typed, target, lenientPunctuation: true);
      expect(result.isComplete, isTrue);
    });

    test('9. Strict punctuation mode does not ignore punctuation', () {
      const typed = '$ol1';
      const target = '$ol1\u0964';
      final result = TypingComparison.compareInput(typed, target, lenientPunctuation: false);
      expect(result.isComplete, isFalse);
      expect(result.matchedPrefixLength, 3);
      expect(result.expectedNextChar, '\u0964');
    });

    test('10. Digit normalization: Latin input matches Ol Chiki target', () {
      const typed = '2'; // Latin
      const target = '\u1C52'; // Ol Chiki ᱒
      final result = TypingComparison.compareInput(typed, target);
      expect(result.isComplete, isTrue);
      expect(result.matchedPrefixLength, 1);
    });

    test('11. Digit normalization: Ol Chiki input matches Latin target', () {
      const typed = '\u1C52'; // Ol Chiki ᱒
      const target = '2'; // Latin
      final result = TypingComparison.compareInput(typed, target);
      expect(result.isComplete, isTrue);
      expect(result.matchedPrefixLength, 1);
    });

    test('12. Collapses consecutive spaces correctly', () {
      const typed = '\u1C5A   \u1C5B';
      const target = '\u1C5A \u1C5B';
      final result = TypingComparison.compareInput(typed, target);
      expect(result.isComplete, isTrue);
    });

    test('13. Empty target string throws ArgumentError', () {
      expect(() => TypingComparison.compareInput(ol1, ''), throwsArgumentError);
    });

    test('14. Extra trailing characters beyond target length detected as mistake', () {
      final result = TypingComparison.compareInput('$ol1\u1C5A', ol1);
      expect(result.isComplete, isFalse);
      expect(result.matchedPrefixLength, 3);
      expect(result.mistakeAtIndex, 3);
    });
  });
}
