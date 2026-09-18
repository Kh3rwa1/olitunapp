import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/lessons/data/models/lesson_model.dart';

void main() {
  group('LessonBlockModel.fromJson normalization', () {
    test('canonical fields pass through verbatim', () {
      final block = LessonBlockModel.fromJson({
        'type': 'sentence',
        'textOlChiki': 'ᱥᱮᱸᱫᱨᱟ',
        'textLatin': 'Sendra katha',
        'textHindi': 'कुछ अर्थ',
        'textBengali': 'কিছু অর্থ',
        'textOdia': 'କିଛି ଅର୍ଥ',
        'audioUrl': 'https://example.com/a.mp3',
        'data': {'meaning_hi': 'कुछ अर्थ'},
      });

      expect(block.textOlChiki, 'ᱥᱮᱸᱫᱨᱟ');
      expect(block.textLatin, 'Sendra katha');
      expect(block.textHindi, 'कुछ अर्थ');
      expect(block.textBengali, 'কিছু অর্থ');
      expect(block.textOdia, 'କିଛି ଅର୍ଥ');
      expect(block.dataMalformed, isFalse);
    });

    test('legacy snake_case aliases are normalized explicitly', () {
      final block = LessonBlockModel.fromJson({
        'type': 'sentence',
        'text_ol_chiki': 'ᱥᱮᱸᱫᱨᱟ',
        'text_latin': 'Sendra katha',
        'text_hindi': 'कुछ अर्थ',
        'text_bengali': 'কিছু অর্থ',
        'text_odia': 'କିଛି ଅର୍ଥ',
        'audio_url': 'https://example.com/a.mp3',
        'image_url': 'https://example.com/i.png',
      });

      expect(block.textOlChiki, 'ᱥᱮᱸᱫᱨᱟ');
      expect(block.textLatin, 'Sendra katha');
      expect(block.textHindi, 'कुछ अर्थ');
      expect(block.textBengali, 'কিছু অর্থ');
      expect(block.textOdia, 'କିଛି ଅର୍ଥ');
      expect(block.audioUrl, 'https://example.com/a.mp3');
      expect(block.imageUrl, 'https://example.com/i.png');
    });

    test('Ol Chiki content is never guessed as Latin', () {
      final block = LessonBlockModel.fromJson({
        'type': 'sentence',
        'content': 'ᱥᱮᱸᱫᱨᱟ ᱠᱟᱛᱷᱟ',
      });

      expect(block.textOlChiki, 'ᱥᱮᱸᱫᱨᱟ ᱠᱟᱛᱷᱟ');
      expect(block.textLatin, isNull);
    });

    test('plain Latin content becomes textLatin only', () {
      final block = LessonBlockModel.fromJson({
        'type': 'sentence',
        'text': 'Sendra katha',
      });

      expect(block.textLatin, 'Sendra katha');
      expect(block.textOlChiki, isNull);
    });

    test('canonical fields win over legacy content', () {
      final block = LessonBlockModel.fromJson({
        'type': 'sentence',
        'textOlChiki': 'ᱥᱮᱸᱫᱨᱟ',
        'textLatin': 'Sendra katha',
        'content': 'stale content',
      });

      expect(block.textOlChiki, 'ᱥᱮᱸᱫᱨᱟ');
      expect(block.textLatin, 'Sendra katha');
    });

    test('malformed data string fails closed with a flag, not a throw', () {
      final block = LessonBlockModel.fromJson({
        'type': 'sentence',
        'textOlChiki': 'ᱥᱮᱸᱫᱨᱟ',
        'textLatin': 'Sendra katha',
        'data': '{not valid json',
      });

      expect(block.data, isNull);
      expect(block.dataMalformed, isTrue);
    });

    test('non-map data JSON fails closed with a flag', () {
      final block = LessonBlockModel.fromJson({
        'type': 'sentence',
        'textOlChiki': 'ᱥᱮᱸᱫᱨᱟ',
        'textLatin': 'Sendra katha',
        'data': '["a", "list"]',
      });

      expect(block.data, isNull);
      expect(block.dataMalformed, isTrue);
    });

    test('sentence attribution aliases normalize to sourceSentenceId', () {
      for (final alias in [
        'sourceSentenceId',
        'sentenceId',
        'sourceSentence',
        'sentence_id',
      ]) {
        final block = LessonBlockModel.fromJson({
          'type': 'sentence',
          'textOlChiki': 'ᱥᱮᱸᱫᱨᱟ',
          'textLatin': 'Sendra katha',
          'data': {'meaning_hi': 'कुछ अर्थ', alias: 'sent_7'},
        });

        expect(
          block.data?['sourceSentenceId'],
          'sent_7',
          reason: 'alias $alias',
        );
        expect(block.data?['meaning_hi'], 'कुछ अर्थ');
      }
    });

    test('explicit canonical ids are preserved, not overwritten', () {
      final block = LessonBlockModel.fromJson({
        'type': 'sentence',
        'textOlChiki': 'ᱥᱮᱸᱫᱨᱟ',
        'textLatin': 'Sendra katha',
        'data': {'sourceSentenceId': 'sent_canonical', 'sentenceId': 'sent_x'},
      });

      expect(block.data?['sourceSentenceId'], 'sent_canonical');
    });

    test('malformed lesson blocks JSON yields zero blocks, not a throw', () {
      final model = LessonModel.fromJson({
        'id': 'lesson_conv3',
        'categoryId': 'cat_sentences',
        'titleOlChiki': 'ᱱᱟᱦᱟᱜ ᱨᱚᱲ',
        'titleLatin': 'Modern Conversational Exchanges III',
        'blocks': '[not valid json',
      });

      expect(model.blocks, isEmpty);
    });

    test('non-map block entries are skipped', () {
      final model = LessonModel.fromJson({
        'id': 'lesson_conv3',
        'categoryId': 'cat_sentences',
        'titleOlChiki': 'ᱱᱟᱦᱟᱜ ᱨᱚᱲ',
        'titleLatin': 'Modern Conversational Exchanges III',
        'blocks': [
          'just a string',
          42,
          {
            'type': 'sentence',
            'textOlChiki': 'ᱥᱮᱸᱫᱨᱟ',
            'textLatin': 'Sendra katha',
          },
        ],
      });

      expect(model.blocks, hasLength(1));
      expect(model.blocks.single.textOlChiki, 'ᱥᱮᱸᱫᱨᱟ');
    });

    test('dataMalformed survives a toJson round trip', () {
      const block = LessonBlockModel(
        type: 'sentence',
        textOlChiki: 'ᱥᱮᱸᱫᱨᱟ',
        textLatin: 'Sendra katha',
        dataMalformed: true,
      );

      final revived = LessonBlockModel.fromJson(block.toJson());
      expect(revived.dataMalformed, isTrue);
      expect(revived.textOlChiki, 'ᱥᱮᱸᱫᱨᱟ');
    });
  });
}
