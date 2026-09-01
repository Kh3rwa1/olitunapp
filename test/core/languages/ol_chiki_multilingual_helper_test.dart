import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/languages/ol_chiki_multilingual_helper.dart';
import 'package:itun/shared/models/content/sentence_model.dart';
import 'package:itun/shared/models/content/word_model.dart';

void main() {
  group('OlChikiMultilingualHelper Character & Digraph Transliteration', () {
    test('transliterates Ol Chiki characters to Bengali script', () {
      expect(OlChikiMultilingualHelper.toBengali('ᱚ'), 'অ');
      expect(OlChikiMultilingualHelper.toBengali('ᱞ'), 'ল');
      expect(OlChikiMultilingualHelper.toBengali('ᱵᱟᱵᱟ'), 'বাবা');
    });

    test('transliterates aspirated consonant digraphs (khel -> খেল)', () {
      expect(OlChikiMultilingualHelper.toBengali('ᱢᱚᱱᱮ ᱠᱷᱮᱞ'), 'মনে খেল');
      expect(OlChikiMultilingualHelper.toHindi('ᱢᱚᱱᱮ ᱠᱷᱮᱞ'), 'मने खेल');
      expect(OlChikiMultilingualHelper.toOdia('ᱢᱚᱱᱮ ᱠᱷᱮᱞ'), 'ମନେ ଖେଲ');
      expect(OlChikiMultilingualHelper.toLatin('ᱢᱚᱱᱮ ᱠᱷᱮᱞ'), 'mone khel');
    });

    test('transliterates complex proverb sentences accurately', () {
      final bn = OlChikiMultilingualHelper.toBengali(
        'ᱞᱟᱠᱪᱟᱨ ᱦᱚᱨ ᱛᱮ ᱪᱟᱞᱟᱜ ᱜᱮ ᱥᱟᱱᱛᱟᱲ ᱦᱚᱯᱚᱱ ᱟᱜ ᱢᱟᱹᱱ ᱠᱟᱱᱟ',
      );
      expect(bn, 'লাকচার হর তে চালাগ গে সানতাড় হপন আগ মান কানা');
    });

    test('transliterates Ol Chiki characters to Hindi (Devanagari) script', () {
      expect(OlChikiMultilingualHelper.toHindi('ᱚ'), 'अ');
      expect(OlChikiMultilingualHelper.toHindi('ᱞ'), 'ल');
      expect(OlChikiMultilingualHelper.toHindi('ᱵᱟᱵᱟ'), 'बाबा');
    });

    test('transliterates Ol Chiki characters to Odia script', () {
      expect(OlChikiMultilingualHelper.toOdia('ᱚ'), 'ଅ');
      expect(OlChikiMultilingualHelper.toOdia('ᱞ'), 'ଲ');
      expect(OlChikiMultilingualHelper.toOdia('ᱵᱟᱵᱟ'), 'ବାବା');
    });

    test('transliterates Ol Chiki characters to Latin Romanized script', () {
      expect(OlChikiMultilingualHelper.toLatin('ᱚ'), 'o');
      expect(OlChikiMultilingualHelper.toLatin('ᱞ'), 'l');
      expect(OlChikiMultilingualHelper.toLatin('ᱵᱟᱵᱟ'), 'baba');
    });
  });

  group('OlChikiMultilingualHelper Composite Latin Parser', () {
    test('parses composite hyphen-separated Latin strings', () {
      final parsed = OlChikiMultilingualHelper.parseCompositeLatin(
        'In rengej ed inja – I am hungry',
      );
      expect(parsed.phoneticLatin, 'In rengej ed inja');
      expect(parsed.meaningEnglish, 'I am hungry');
    });

    test('handles single Latin words gracefully', () {
      final parsed = OlChikiMultilingualHelper.parseCompositeLatin('Baba');
      expect(parsed.phoneticLatin, 'Baba');
      expect(parsed.meaningEnglish, 'Father');
    });
  });

  group(
    'OlChikiMultilingualHelper resolveBlockDisplay & Zero-Leakage Invariants',
    () {
      test(
        'resolves Bengali display for sentence block with zero English leakage',
        () {
          final display = OlChikiMultilingualHelper.resolveBlockDisplay(
            textOlChiki: 'ᱤᱧ ᱨᱮᱸᱜᱮᱡ ᱮᱫ ᱤᱧᱟ',
            textLatin: 'In rengej ed inja – I am hungry',
            teachingLanguage: 'bn',
            scriptMode: 'both',
          );

          expect(display.scriptText, 'ᱤᱧ ᱨᱮᱸᱜᱮᱡ ᱮᱫ ᱤᱧᱟ');
          expect(display.subtitle, contains('আমার খিদে পেয়েছে'));
          expect(display.ctaText, 'শুনুন');
          // Zero English letters in Bengali title or subtitle
          expect(RegExp(r'[A-Za-z]').hasMatch(display.title), isFalse);
          expect(RegExp(r'[A-Za-z]').hasMatch(display.subtitle), isFalse);
        },
      );

      test(
        'resolves Bengali display for Mone Khel with zero English leakage',
        () {
          final display = OlChikiMultilingualHelper.resolveBlockDisplay(
            textOlChiki: 'ᱢᱚᱱᱮ ᱠᱷᱮᱞ',
            textLatin: 'Mone khel – Mind game / Flirting',
            teachingLanguage: 'bn',
            scriptMode: 'both',
          );

          expect(display.scriptText, 'ᱢᱚᱱᱮ ᱠᱷᱮᱞ');
          expect(display.transliteration, 'মনে খেল');
          expect(display.subtitle, 'মনে খেল – মনের খেলা / প্রেমভাব');
          expect(display.title, 'মনের খেলা / প্রেমভাব');
          expect(RegExp(r'[A-Za-z]').hasMatch(display.title), isFalse);
          expect(RegExp(r'[A-Za-z]').hasMatch(display.subtitle), isFalse);
        },
      );

      test(
        'resolves Bengali display for cultural proverb with zero English leakage',
        () {
          final display = OlChikiMultilingualHelper.resolveBlockDisplay(
            textOlChiki: 'ᱞᱟᱠᱪᱟᱨ ᱦᱚᱨ ᱛᱮ ᱪᱟᱞᱟᱜ ᱜᱮ ᱥᱟᱱᱛᱟᱲ ᱦᱚᱯᱚᱱ ᱟᱜ ᱢᱟᱹᱱ ᱠᱟᱱᱟ',
            textLatin:
                'Lakchar hor te chalag ge Santal hopon aak man kana – Going on the cultural path is the honor of the Santal people.',
            teachingLanguage: 'bn',
            scriptMode: 'both',
          );

          expect(
            display.scriptText,
            'ᱞᱟᱠᱪᱟᱨ ᱦᱚᱨ ᱛᱮ ᱪᱟᱞᱟᱜ ᱜᱮ ᱥᱟᱱᱛᱟᱲ ᱦᱚᱯᱚᱱ ᱟᱜ ᱢᱟᱹᱱ ᱠᱟᱱᱟ',
          );
          expect(
            display.transliteration,
            'লাকচার হর তে চালাগ গে সানতাড় হপন আগ মান কানা',
          );
          expect(display.title, 'সংস্কৃতির পথে চলা সাঁওতাল জাতির গৌরব।');
          expect(RegExp(r'[A-Za-z]').hasMatch(display.title), isFalse);
          expect(RegExp(r'[A-Za-z]').hasMatch(display.subtitle), isFalse);
        },
      );

      test('resolves Hindi display for family word', () {
        final display = OlChikiMultilingualHelper.resolveBlockDisplay(
          textOlChiki: 'ᱵᱟᱵᱟ',
          textLatin: 'Baba – Father',
          teachingLanguage: 'hi',
          scriptMode: 'both',
        );

        expect(display.scriptText, 'ᱵᱟᱵᱟ');
        expect(display.subtitle, 'बाबा – पिता');
        expect(display.ctaText, 'सुनें');
        expect(RegExp(r'[A-Za-z]').hasMatch(display.title), isFalse);
        expect(RegExp(r'[A-Za-z]').hasMatch(display.subtitle), isFalse);
      });

      test('resolves Odia display for family word', () {
        final display = OlChikiMultilingualHelper.resolveBlockDisplay(
          textOlChiki: 'ᱵᱟᱵᱟ',
          textLatin: 'Baba – Father',
          teachingLanguage: 'or',
          scriptMode: 'both',
        );

        expect(display.scriptText, 'ᱵᱟᱵᱟ');
        expect(display.subtitle, 'ବାବା – ବାପା');
        expect(display.ctaText, 'ଶୁଣନ୍ତୁ');
        expect(RegExp(r'[A-Za-z]').hasMatch(display.title), isFalse);
        expect(RegExp(r'[A-Za-z]').hasMatch(display.subtitle), isFalse);
      });

      test('resolves English display cleanly without repetitive phrases', () {
        final display = OlChikiMultilingualHelper.resolveBlockDisplay(
          textOlChiki: 'ᱵᱟᱵᱟ',
          textLatin: 'Baba – Father',
          teachingLanguage: 'en',
          scriptMode: 'both',
        );

        expect(display.scriptText, 'ᱵᱟᱵᱟ');
        expect(display.subtitle, 'Baba – Father');
        expect(display.ctaText, 'LISTEN');
      });

      test('hides subtitle when script mode is olchiki', () {
        final display = OlChikiMultilingualHelper.resolveBlockDisplay(
          textOlChiki: 'ᱵᱟᱵᱟ',
          textLatin: 'Baba – Father',
          teachingLanguage: 'en',
          scriptMode: 'olchiki',
        );

        expect(display.scriptText, 'ᱵᱟᱵᱟ');
        expect(display.subtitle, isEmpty);
      });

      test('hides subtitle when teaching language is santali', () {
        final display = OlChikiMultilingualHelper.resolveBlockDisplay(
          textOlChiki: 'ᱵᱟᱵᱟ',
          textLatin: 'Baba – Father',
          teachingLanguage: 'sat',
          scriptMode: 'both',
        );

        expect(display.scriptText, 'ᱵᱟᱵᱟ');
        expect(display.subtitle, isEmpty);
        expect(display.ctaText, 'ᱟᱸᱡᱚᱢ');
      });
    },
  );

  group('WordModel and SentenceModel Multilingual Extensions', () {
    test('WordModel returns localized transliterations and meanings', () {
      final word = WordModel(
        id: 'w1',
        wordOlChiki: 'ᱵᱟᱵᱟ',
        wordLatin: 'Baba',
        meaning: 'Father',
      );

      expect(word.localizedTransliteration('bn'), 'বাবা');
      expect(word.localizedTransliteration('hi'), 'बाबा');
      expect(word.localizedTransliteration('or'), 'ବାବା');
      expect(word.localizedMeaning('bn'), 'পিতা');
      expect(
        word.localizedMeaning('or'),
        OlChikiMultilingualHelper.translateMeaning('Father', 'or'),
      );

      expect(word.localizedSubtitle('bn'), 'বাবা – পিতা');
    });

    test('SentenceModel returns localized transliterations and meanings', () {
      final sentence = SentenceModel(
        id: 's1',
        sentenceOlChiki: 'ᱤᱧ ᱨᱮᱸᱜᱮᱡ ᱮᱫ ᱤᱧᱟ',
        sentenceLatin: 'In rengej ed inja',
        meaning: 'I am hungry',
      );

      expect(sentence.localizedMeaning('bn'), 'আমার খিদে পেয়েছে');
      expect(sentence.localizedMeaning('hi'), 'मुझे भूख लगी है');
      expect(sentence.localizedMeaning('or'), 'ମୋତେ ଭୋକ ଲାଗୁଛି');
      expect(sentence.localizedSubtitle('bn'), contains('আমার খিদে পেয়েছে'));
    });
  });
}
