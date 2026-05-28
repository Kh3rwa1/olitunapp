import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/rhymes/domain/rhyme_model.dart';
import 'package:itun/shared/models/content_models.dart';

void main() {
  group('RhymeModel', () {
    test('parses admin rows with optional content fields omitted', () {
      final model = RhymeModel.fromJson({
        'id': 'rhyme_1',
        'titleOlChiki': 'ᱵᱟᱠᱷᱮᱫ',
        'titleLatin': 'Bakhed',
        'audioUrl': 'https://example.com/audio.mp3',
        'thumbnailUrl': 'https://example.com/thumb.png',
        'category': 'Sohrai',
        'tags': ['Got Puja', 'kids'],
      });

      expect(model.id, 'rhyme_1');
      expect(model.titleLatin, 'Bakhed');
      expect(model.contentOlChiki, '');
      expect(model.contentLatin, '');
      expect(model.category, 'Sohrai');
      expect(model.tags, ['Got Puja', 'kids']);
    });

    test('parses canonical category ids', () {
      final model = RhymeModel.fromJson({
        r'$id': 'rhyme_2',
        'titleOlChiki': 'ᱵᱟᱠᱷᱮᱫ',
        'titleLatin': 'Bakhed',
        'contentOlChiki': '',
        'contentLatin': 'Story text',
        'categoryId': 'cat_sohrai',
      });

      expect(model.id, 'rhyme_2');
      expect(model.categoryId, 'cat_sohrai');
    });

    test('serializes legacy labels and canonical ids for compatibility', () {
      final json = RhymeModel(
        id: 'rhyme_3',
        titleOlChiki: 'ᱵᱟᱠᱷᱮᱫ',
        titleLatin: 'Bakhed',
        contentOlChiki: '',
        contentLatin: 'Story text',
        categoryId: 'cat_sohrai',
        category: 'Sohrai',
        tags: ['Got Puja'],
      ).toJson();

      expect(json['categoryId'], 'cat_sohrai');
      expect(json['category'], 'Sohrai');
      expect(json['tags'], ['Got Puja']);
    });

    test('toRhymeModel maps audioUrl and thumbnailUrl correctly', () {
      final now = DateTime.now();

      // Case 1: Rhyme has top-level audioUrl and heroMedia is an image
      final item1 = ContentItem(
        id: 'r1',
        kind: ContentKind.rhyme,
        categoryId: 'cat_sohrai',
        title: 'Title Latin',
        titleOlChiki: 'Title Ol',
        subtitle: 'Content Latin',
        olChiki: 'Content Ol',
        audioUrl: 'https://example.com/audio.mp3',
        heroMedia: const ContentMedia(
          url: 'https://example.com/thumb.png',
          fileId: 'thumb1',
          kind: ContentMediaKind.image,
        ),
        blocks: const [],
        updatedAt: now,
      );

      final rhyme1 = item1.toRhymeModel();
      expect(rhyme1.audioUrl, 'https://example.com/audio.mp3');
      expect(rhyme1.thumbnailUrl, 'https://example.com/thumb.png');

      // Case 2: Rhyme has no top-level audioUrl, but heroMedia is audio
      final item2 = ContentItem(
        id: 'r2',
        kind: ContentKind.rhyme,
        categoryId: 'cat_sohrai',
        title: 'Title Latin',
        heroMedia: const ContentMedia(
          url: 'https://example.com/hero_audio.mp3',
          fileId: 'audio1',
          kind: ContentMediaKind.audio,
        ),
        blocks: const [],
        updatedAt: now,
      );

      final rhyme2 = item2.toRhymeModel();
      expect(rhyme2.audioUrl, 'https://example.com/hero_audio.mp3');
      expect(rhyme2.thumbnailUrl, isNull);

      // Case 3: Rhyme has no top-level audioUrl, but has an audio block in blocks
      final item3 = ContentItem(
        id: 'r3',
        kind: ContentKind.rhyme,
        categoryId: 'cat_sohrai',
        title: 'Title Latin',
        blocks: const [
          AudioBlock(
            id: 'b1',
            order: 0,
            media: ContentMedia(
              url: 'https://example.com/block_audio.mp3',
              fileId: 'audio2',
              kind: ContentMediaKind.audio,
            ),
          ),
        ],
        updatedAt: now,
      );

      final rhyme3 = item3.toRhymeModel();
      expect(rhyme3.audioUrl, 'https://example.com/block_audio.mp3');
    });

    test(
      'toRhymeModel preserves category name instead of substituting document ID',
      () {
        final now = DateTime.now();

        // Case 1: given a ContentItem with category: "Sohrai", expect RhymeModel.category == "Sohrai"
        final item1 = ContentItem(
          id: 'r1',
          kind: ContentKind.rhyme,
          categoryId: 'cat_sohrai',
          category: 'Sohrai',
          title: 'Title Latin',
          blocks: const [],
          updatedAt: now,
        );
        final rhyme1 = item1.toRhymeModel();
        expect(rhyme1.categoryId, 'cat_sohrai');
        expect(rhyme1.category, 'Sohrai');

        // Case 2: given a ContentItem with category: null, expect RhymeModel.category == null
        final item2 = ContentItem(
          id: 'r2',
          kind: ContentKind.rhyme,
          categoryId: 'cat_sohrai',
          title: 'Title Latin',
          blocks: const [],
          updatedAt: now,
        );
        final rhyme2 = item2.toRhymeModel();
        expect(rhyme2.categoryId, 'cat_sohrai');
        expect(rhyme2.category, isNull);
      },
    );
  });
}
