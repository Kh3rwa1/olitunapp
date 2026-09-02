import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/utils/text_match.dart';

void main() {
  group('isTextMatch', () {
    test('requires a non-empty entity text', () {
      expect(isTextMatch('anything', ''), isFalse);
      expect(isTextMatch('anything', '   '), isFalse);
    });

    test('matches exact text case-insensitively', () {
      expect(isTextMatch('Mit', 'mit'), isTrue);
      expect(isTextMatch('Johar', 'johar'), isTrue);
    });

    test('ignores surrounding whitespace', () {
      expect(isTextMatch('  mit  ', ' mit '), isTrue);
    });

    test('strips punctuation before comparing', () {
      expect(isTextMatch('mit!', 'mit'), isTrue);
      // Both sides are punctuation-stripped, so these cleaned forms match.
      expect(isTextMatch('Hello, world.', 'hello world'), isTrue);
      expect(isTextMatch('Hello, world', 'hello, world!'), isTrue);
    });

    group('letter mode', () {
      test('allows substring matching inside a longer block', () {
        expect(isTextMatch('a b c', 'b', isLetter: true), isTrue);
        expect(isTextMatch('ᱚ ᱛ ᱜ', 'ᱛ', isLetter: true), isTrue);
      });

      test('fails when the glyph is absent', () {
        expect(isTextMatch('a b c', 'z', isLetter: true), isFalse);
      });
    });

    group('word/sentence mode', () {
      test('matches standalone tokens', () {
        expect(isTextMatch('the quick fox', 'fox'), isTrue);
        expect(isTextMatch('the quick fox', 'foxes'), isFalse);
      });

      test('treats dashes, dots and punctuation as token separators', () {
        expect(isTextMatch('well-known author', 'known'), isTrue);
        expect(isTextMatch('one.two.three', 'two'), isTrue);
        expect(isTextMatch('wait... what?', 'what'), isTrue);
      });

      test('does not do substring matching', () {
        expect(isTextMatch('catapult', 'cat'), isFalse);
      });
    });

    test('matches Ol Chiki glyphs', () {
      expect(isTextMatch('ᱚᱠᷚᱨ', 'ᱚᱠᷚᱨ'), isTrue);
      expect(isTextMatch('ᱚ - ᱛ', 'ᱛ'), isTrue);
    });
  });
}
