import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/rhymes/domain/rhyme_model.dart';

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
  });
}
