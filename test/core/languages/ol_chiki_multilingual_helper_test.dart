import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/languages/ol_chiki_multilingual_helper.dart';
import 'package:itun/shared/models/content/sentence_model.dart';
import 'package:itun/shared/models/content/word_model.dart';

void main() {
  group('OlChikiMultilingualHelper Character Transliteration', () {
    test('transliterates Ol Chiki characters to Bengali script', () {
      expect(OlChikiMultilingualHelper.toBengali('ᱚ'), 'অ');
      expect(OlChikiMultilingualHelper.toBengali('ᱞ'), 'ল');
      expect(OlChikiMultilingualHelper.toBengali('ᱵᱟᱵᱟ'), 'বাবা');
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

  group('OlChikiMultilingualHelper resolveBlockDisplay', () {
    test('resolves Bengali display for sentence block', () {
      final display = OlChikiMultilingualHelper.resolveBlockDisplay(
        textOlChiki: 'ᱤᱧ ᱨᱮᱸᱜᱮᱡ ᱮᱫ ᱤᱧᱟ',
        textLatin: 'In rengej ed inja – I am hungry',
        teachingLanguage: 'bn',
        scriptMode: 'both',
      );

      expect(display.scriptText, 'ᱤᱧ ᱨᱮᱸᱜᱮᱡ ᱮᱫ ᱤᱧᱟ');
      expect(display.subtitle, contains('আমার খিদে পেয়েছে'));
      expect(display.ctaText, 'শুনুন');
    });

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
      expect(word.localizedMeaning('or'), OlChikiMultilingualHelper.translateMeaning('Father', 'or'));

      expect(word.localizedSubtitle('bn'), 'বাবা – পিতা');
    });

    test('SentenceModel returns localized transliterations and meanings', () {
      final sentence = SentenceModel(
        id: 's1',
        sentenceOlChiki: 'ᱤᱧ ᱨᱮᱸᱜᱮᱡ ᱮᱫ ᱤᱧᱟ',
        sentenceLatin: 'In rengej ed inja',
        meaning: 'I am hungry',
      );

      expect(sentence.localizedMeaning('bn'), 'আমার খিদে পেয়েছে');
      expect(sentence.localizedMeaning('hi'), 'मुझे भूख लगी है');
      expect(sentence.localizedMeaning('or'), 'ମୋତେ ଭୋକ ଲାଗୁଛି');
      expect(sentence.localizedSubtitle('bn'), contains('আমার খিদে পেয়েছে'));
    });
  });
}

