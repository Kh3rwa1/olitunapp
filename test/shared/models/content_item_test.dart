import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/shared/models/content_models.dart';

void main() {
  group('ContentKind & ContentMediaKind Serialization', () {
    test('ContentKind fromString', () {
      expect(ContentKind.fromString('letter'), ContentKind.letter);
      expect(ContentKind.fromString('NUMBER'), ContentKind.number);
      expect(ContentKind.fromString('Lesson'), ContentKind.lesson);
      expect(() => ContentKind.fromString('unknown'), throwsArgumentError);
    });

    test('ContentMediaKind fromString', () {
      expect(ContentMediaKind.fromString('image'), ContentMediaKind.image);
      expect(ContentMediaKind.fromString('VIDEO'), ContentMediaKind.video);
      expect(() => ContentMediaKind.fromString('unknown'), throwsArgumentError);
    });
  });

  group('ContentMedia Model Tests', () {
    test('toJson & fromJson round-trip', () {
      const media = ContentMedia(
        url: 'https://test.com/img.png',
        fileId: 'f123',
        kind: ContentMediaKind.image,
        caption: 'Hello Cover',
        durationSeconds: 120,
      );

      final json = media.toJson();
      final decoded = ContentMedia.fromJson(json);

      expect(decoded.url, media.url);
      expect(decoded.fileId, media.fileId);
      expect(decoded.kind, media.kind);
      expect(decoded.caption, media.caption);
      expect(decoded.durationSeconds, media.durationSeconds);
    });
  });

  group('ContentBlock hierarchy Serialization Tests', () {
    test('TextBlock serialization', () {
      const block = TextBlock(id: 'b1', order: 0, markdown: '# Santali');
      final json = block.toJson();
      expect(json['type'], 'text');
      expect(json['markdown'], '# Santali');

      final parsed = ContentBlock.fromJson(json) as TextBlock;
      expect(parsed.id, 'b1');
      expect(parsed.markdown, '# Santali');
    });

    test('ImageBlock serialization', () {
      const block = ImageBlock(
        id: 'b2',
        order: 1,
        media: ContentMedia(
          url: 'https://img.webp',
          fileId: 'img',
          kind: ContentMediaKind.image,
        ),
        caption: 'Beautiful flower',
      );
      final json = block.toJson();
      expect(json['type'], 'image');
      expect(json['caption'], 'Beautiful flower');

      final parsed = ContentBlock.fromJson(json) as ImageBlock;
      expect(parsed.media.url, 'https://img.webp');
      expect(parsed.caption, 'Beautiful flower');
    });

    test('QuizBlock serialization', () {
      const block = QuizBlock(id: 'b3', order: 2, quizId: 'q456');
      final json = block.toJson();
      expect(json['type'], 'quiz');
      expect(json['quizId'], 'q456');

      final parsed = ContentBlock.fromJson(json) as QuizBlock;
      expect(parsed.quizId, 'q456');
    });
  });

  group('ContentItem Validation Invariant Tests', () {
    test(
      'legacy letter without tracing can load but cannot be saved as-is',
      () {
        final item = ContentItem.fromJson({
          'kind': 'letter',
          'category_id': 'cat1',
          'title': 'Letter A',
          'updatedAt': DateTime.now().toIso8601String(),
          'blocks': '[]',
          'tracing': null,
        });

        expect(item.tracing, isNull);
        expect(
          () => ContentItem.validate(item.kind, item.tracing),
          throwsA(isA<ContentValidationException>()),
        );
      },
    );

    test('Instantiating letter kind with valid tracing config succeeds', () {
      final item = ContentItem.fromJson({
        'kind': 'letter',
        'category_id': 'cat1',
        'title': 'Letter A',
        'updatedAt': DateTime.now().toIso8601String(),
        'blocks': '[]',
        'tracing': jsonEncode({
          'glyph': 'ᱚ',
          'strokes': [],
          'guide': 'dotted',
          'strokeWidth': 12.0,
          'tolerance': 0.6,
          'showDirectionArrows': true,
          'playAudioOnComplete': true,
          'requiredCompletions': 1,
        }),
      });

      expect(item.title, 'Letter A');
      expect(item.kind, ContentKind.letter);
      expect(item.tracing, isNotNull);
      expect(item.tracing!.glyph, 'ᱚ');
    });

    test('Instantiating lesson kind with null tracing succeeds', () {
      final item = ContentItem.fromJson({
        'kind': 'lesson',
        'category_id': 'cat_lesson',
        'title': 'Intro Santali',
        'updatedAt': DateTime.now().toIso8601String(),
        'blocks': '[]',
        'tracing': null,
      });

      expect(item.title, 'Intro Santali');
      expect(item.kind, ContentKind.lesson);
      expect(item.tracing, isNull);
    });
  });

  group('ContentItem Appwrite Collection Contracts', () {
    const tracing = TracingConfig(glyph: 'ᱚ', strokes: []);

    ContentItem item(
      ContentKind kind, {
      String subtitle = 'Summary',
      ContentMedia? heroMedia,
    }) {
      return ContentItem(
        id: 'item_1',
        kind: kind,
        categoryId: 'cat_1',
        title: 'Latin title',
        titleOlChiki: 'ᱚ',
        subtitle: subtitle,
        olChiki: 'ᱚ',
        heroMedia: heroMedia,
        blocks: const [TextBlock(id: 'b1', order: 0, markdown: 'Body')],
        tracing: kind == ContentKind.letter || kind == ContentKind.number
            ? tracing
            : null,
        isPublished: true,
        tags: const ['tag'],
        updatedAt: DateTime(2026),
      );
    }

    test('lesson summary maps to description, never subtitle', () {
      final payload = item(ContentKind.lesson).toAppwrite();

      expect(payload['description'], 'Summary');
      expect(payload['titleLatin'], 'Latin title');
      expect(payload['isActive'], isTrue);
      expect(payload.containsKey('subtitle'), isFalse);
    });

    test('letter uses declared media and example word attributes', () {
      final payload = item(
        ContentKind.letter,
        heroMedia: const ContentMedia(
          url: 'https://example.com/a.json',
          fileId: 'file_1',
          kind: ContentMediaKind.lottie,
        ),
      ).toAppwrite();

      expect(payload['exampleWordLatin'], 'Summary');
      expect(payload['animationUrl'], 'https://example.com/a.json');
      expect(payload.containsKey('exampleWord'), isFalse);
      expect(payload.containsKey('lottieUrl'), isFalse);
    });

    test('word and sentence do not write nonexistent usageExample', () {
      for (final kind in [ContentKind.word, ContentKind.sentence]) {
        final payload = item(kind).toAppwrite();

        expect(payload['meaning'], 'Summary');
        expect(payload['isActive'], isTrue);
        expect(payload.containsKey('usageExample'), isFalse);
        expect(payload['blocks'], isA<String>());
      }
    });

    test('known collection type parses deployed keys without a kind field', () {
      final lesson = ContentItem.fromJson(
        {
          'categoryId': 'cat_1',
          'titleLatin': 'Greetings',
          'titleOlChiki': 'ᱡᱚᱦᱟᱨ',
          'description': 'Introduction',
          'isActive': true,
          'blocks': '[]',
        },
        'lesson_1',
        ContentKind.lesson,
      );
      final word = ContentItem.fromJson(
        {
          'wordLatin': 'johar',
          'wordOlChiki': 'ᱡᱚᱦᱟᱨ',
          'meaning': 'hello',
          'category': 'cat_words',
          'isActive': true,
          'blocks': '[]',
        },
        'word_1',
        ContentKind.word,
      );

      expect(lesson.kind, ContentKind.lesson);
      expect(lesson.subtitle, 'Introduction');
      expect(word.kind, ContentKind.word);
      expect(word.title, 'johar');
      expect(word.olChiki, 'ᱡᱚᱦᱟᱨ');
      expect(word.subtitle, 'hello');
      expect(word.categoryId, 'cat_words');
      expect(word.isPublished, isTrue);
    });
  });
}
