import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/languages/ol_chiki_multilingual_helper.dart';
import 'package:itun/shared/models/content/sentence_model.dart';
import 'package:itun/shared/models/content/word_model.dart';

void main() {
  group('OlChikiMultilingualHelper Transliteration & Digraphs', () {
    test('transliterates basic Ol Chiki vowels and consonants to Bengali', () {
      expect(OlChikiMultilingualHelper.toBengali('ᱚ'), 'অ');
      expect(OlChikiMultilingualHelper.toBengali('ᱟ'), 'আ');
      expect(OlChikiMultilingualHelper.toBengali('ᱵᱟᱵᱟ'), 'বাবা');
      expect(OlChikiMultilingualHelper.toBengali('ᱟᱭᱳ'), 'আয়ো');
    });

    test(
      'transliterates aspirated consonant digraphs correctly into single Indic aspirated letters',
      () {
        // ᱠ + ᱷ -> খ (Bengali), ख (Hindi), ଖ (Odia), kh (Latin)
        expect(OlChikiMultilingualHelper.toBengali('ᱠᱷ'), 'খ');
        expect(OlChikiMultilingualHelper.toHindi('ᱠᱷ'), 'ख');
        expect(OlChikiMultilingualHelper.toOdia('ᱠᱷ'), 'ଖ');
        expect(OlChikiMultilingualHelper.toLatin('ᱠᱷ'), 'kh');

        // ᱢᱚᱱᱮ ᱠᱷᱮᱞ -> মনে খেল (Bengali), मने खेल (Hindi), ମନେ ଖେଲ (Odia)
        expect(OlChikiMultilingualHelper.toBengali('ᱢᱚᱱᱮ ᱠᱷᱮᱞ'), 'মনে খেল');
        expect(OlChikiMultilingualHelper.toHindi('ᱢᱚᱱᱮ ᱠᱷᱮᱞ'), 'मने खेल');
        expect(OlChikiMultilingualHelper.toOdia('ᱢᱚᱱᱮ ᱠᱷᱮᱞ'), 'ମନେ ଖେଲ');
        expect(OlChikiMultilingualHelper.toLatin('ᱢᱚᱱᱮ ᱠᱷᱮᱞ'), 'mone khel');

        // ᱜᱷ -> ঘ / घ / ଘ
        expect(OlChikiMultilingualHelper.toBengali('ᱜᱷ'), 'ঘ');
        expect(OlChikiMultilingualHelper.toHindi('ᱜᱷ'), 'घ');
        expect(OlChikiMultilingualHelper.toOdia('ᱜᱷ'), 'ଘ');

        // ᱛᱷ -> থ / थ / ଥ
        expect(OlChikiMultilingualHelper.toBengali('ᱛᱷ'), 'থ');
        expect(OlChikiMultilingualHelper.toHindi('ᱛᱷ'), 'थ');
        expect(OlChikiMultilingualHelper.toOdia('ᱛᱷ'), 'ଥ');
      },
    );

    test('transliterates Ol Chiki to Hindi/Devanagari correctly', () {
      expect(OlChikiMultilingualHelper.toHindi('ᱚ'), 'अ');
      expect(OlChikiMultilingualHelper.toHindi('ᱵᱟᱵᱟ'), 'बाबा');
    });

    test('transliterates Ol Chiki to Odia correctly', () {
      expect(OlChikiMultilingualHelper.toOdia('ᱚ'), 'ଅ');
      expect(OlChikiMultilingualHelper.toOdia('ᱵᱟᱵᱟ'), 'ବାବା');
    });
  });

  group(
    'OlChikiMultilingualHelper translateMeaning Zero-Leakage Guarantees',
    () {
      test('translates English meanings into Bengali', () {
        expect(
          OlChikiMultilingualHelper.translateMeaning('Father', 'bn'),
          'পিতা',
        );
        expect(
          OlChikiMultilingualHelper.translateMeaning('Mother', 'bn'),
          'মাতা',
        );
        expect(
          OlChikiMultilingualHelper.translateMeaning(
            'Mind game / Flirting',
            'bn',
          ),
          'মনের খেলা / প্রেমভাব',
        );
      });

      test('returns empty string for missing non-English target languages', () {
        // Must NEVER return English fallback for non-English target languages
        expect(
          OlChikiMultilingualHelper.translateMeaning(
            'Some completely unknown text XYZ 123',
            'bn',
          ),
          '',
        );
        expect(
          OlChikiMultilingualHelper.translateMeaning(
            'Some completely unknown text XYZ 123',
            'hi',
          ),
          '',
        );
        expect(
          OlChikiMultilingualHelper.translateMeaning(
            'Some completely unknown text XYZ 123',
            'or',
          ),
          '',
        );
      });
    },
  );

  group('OlChikiMultilingualHelper resolveBlockDisplay & 3-Section Layout', () {
    test(
      'resolves 3-section layout for sentence with meaning at top, Ol Chiki middle, transliteration bottom',
      () {
        final display = OlChikiMultilingualHelper.resolveBlockDisplay(
          textOlChiki: 'ᱦᱟᱹᱨᱤᱭᱟᱹᱲ ᱵᱟᱹᱫᱽ ᱠᱚ ᱥᱚᱱᱟ ᱞᱮᱠᱟ ᱥᱟᱥᱟᱝ ᱦᱳᱲᱳ ᱛᱮ ᱯᱮᱨᱮᱡ ᱮᱱᱟ ᱾',
          textLatin:
              'Hariyar bad ko sona leka sasang horo te perej ena. – The green fields turned golden with ripe winter paddy.',
          teachingLanguage: 'bn',
          scriptMode: 'both',
        );

        // Top Section: Meaning in Bengali
        expect(display.title, 'সবুজ ক্ষেত পাকা সোনালি ধানে ভরে উঠল।');
        // Middle Section: Ol Chiki text
        expect(
          display.scriptText,
          'ᱦᱟᱹᱨᱤᱭᱟᱹᱲ ᱵᱟᱹᱫᱽ ᱠᱚ ᱥᱚᱱᱟ ᱞᱮᱠᱟ ᱥᱟᱥᱟᱝ ᱦᱳᱲᱳ ᱛᱮ ᱯᱮᱨᱮᱡ ᱮᱱᱟ ᱾',
        );
        // Bottom Section: Transliteration in Bengali script (centered below Ol Chiki)
        expect(
          display.subtitle,
          'হারিয়াড় বাদ ক সনা লেকা সাসাং হোড়ো তে পেরেজ এনা ।',
        );
        expect(display.ctaText, 'শুনুন');
        // Zero English letters in Bengali title or subtitle
        expect(RegExp(r'[A-Za-z]').hasMatch(display.title), isFalse);
        expect(RegExp(r'[A-Za-z]').hasMatch(display.subtitle), isFalse);
      },
    );

    test(
      'resolves Bengali display for Mone Khel with zero English leakage and 3-section layout',
      () {
        final display = OlChikiMultilingualHelper.resolveBlockDisplay(
          textOlChiki: 'ᱢᱚᱱᱮ ᱠᱷᱮᱞ',
          textLatin: 'Mone khel – Mind game / Flirting',
          teachingLanguage: 'bn',
          scriptMode: 'both',
        );

        // Middle Section
        expect(display.scriptText, 'ᱢᱚᱱᱮ ᱠᱷᱮᱞ');
        // Bottom Section: Transliteration
        expect(display.transliteration, 'মনে খেল');
        expect(display.subtitle, 'মনে খেল');
        // Top Section: Meaning
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
        expect(
          display.subtitle,
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
      expect(display.subtitle, 'बाबा');
      expect(display.title, 'पिता');
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
      expect(display.subtitle, 'ବାବା');
      expect(display.title, 'ବାପା');
      expect(display.ctaText, 'ଶୁଣନ୍ତୁ');
      expect(RegExp(r'[A-Za-z]').hasMatch(display.title), isFalse);
      expect(RegExp(r'[A-Za-z]').hasMatch(display.subtitle), isFalse);
    });

    test('resolves English display cleanly', () {
      final display = OlChikiMultilingualHelper.resolveBlockDisplay(
        textOlChiki: 'ᱵᱟᱵᱟ',
        textLatin: 'Baba – Father',
        teachingLanguage: 'en',
        scriptMode: 'both',
      );

      expect(display.scriptText, 'ᱵᱟᱵᱟ');
      expect(display.subtitle, 'Baba');
      expect(display.title, 'Father');
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

    test(
      'resolves contaminated Ol Chiki and descriptive textLatin in Bengali',
      () {
        final display = OlChikiMultilingualHelper.resolveBlockDisplay(
          textOlChiki: 'ᱪᱮᱫ - Ched (What?)',
          textLatin: 'Ched – Used to ask about things, objects, or actions',
          teachingLanguage: 'bn',
          scriptMode: 'both',
        );

        expect(display.scriptText, 'ᱪᱮᱫ');
        expect(display.title, 'কী?');
        expect(display.subtitle, 'চেদ');
        expect(display.ctaText, 'শুনুন');
        expect(RegExp(r'[A-Za-z]').hasMatch(display.scriptText), isFalse);
        expect(RegExp(r'[A-Za-z]').hasMatch(display.title), isFalse);
        expect(RegExp(r'[A-Za-z]').hasMatch(display.subtitle), isFalse);
      },
    );

    test(
      'resolves contaminated pronouns in Bengali without leaking English',
      () {
        final display = OlChikiMultilingualHelper.resolveBlockDisplay(
          textOlChiki: 'ᱤᱧ - Iny (I / Me)',
          textLatin: 'Iny – First person singular: I or Me',
          teachingLanguage: 'bn',
          scriptMode: 'both',
        );

        expect(display.scriptText, 'ᱤᱧ');
        expect(display.title, 'আমি / আমাকে');
        expect(display.subtitle, 'ইঞ');
        expect(RegExp(r'[A-Za-z]').hasMatch(display.title), isFalse);
        expect(RegExp(r'[A-Za-z]').hasMatch(display.subtitle), isFalse);
      },
    );

    test('resolves sentence lessons with composite textLatin in Bengali', () {
      final display = OlChikiMultilingualHelper.resolveBlockDisplay(
        textOlChiki: 'ᱫᱟᱠᱟ ᱡᱚᱢ ᱢᱮ',
        textLatin: 'Daka jom me – Please eat food',
        teachingLanguage: 'bn',
        scriptMode: 'both',
      );

      expect(display.scriptText, 'ᱫᱟᱠᱟ ᱡᱚᱢ ᱢᱮ');
      expect(display.title, 'দয়া করে খাবার খাও');
      expect(display.subtitle, 'দাকা জম মে');
      expect(RegExp(r'[A-Za-z]').hasMatch(display.title), isFalse);
      expect(RegExp(r'[A-Za-z]').hasMatch(display.subtitle), isFalse);
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
  });

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
      expect(word.localizedSubtitle('bn'), 'বাবা');
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
      expect(sentence.localizedSubtitle('bn'), 'ইঞ রেঁগেজ এদ ইঞা');
    });
  });
}
