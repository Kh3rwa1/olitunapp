import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/rhymes/domain/rhyme_catalog.dart';
import 'package:itun/features/rhymes/domain/rhyme_model.dart';

RhymeModel _rhyme(
  String id, {
  String? category,
  List<String> tags = const [],
  bool isFeatured = false,
}) {
  return RhymeModel(
    id: id,
    titleOlChiki: 'ᱚ',
    titleLatin: 't-$id',
    contentOlChiki: '',
    contentLatin: '',
    category: category,
    tags: tags,
    isFeatured: isFeatured,
  );
}

void main() {
  group('collectCategories', () {
    test('deduplicates case-insensitively, keeps first-seen display name', () {
      final cats = RhymeCatalog.collectCategories([
        _rhyme('a', category: 'Sohrai'),
        _rhyme('b', category: 'sohrai'),
        _rhyme('c', category: 'SOHRAI '),
        _rhyme('d', category: 'Baha'),
      ]);
      expect(cats.length, 2);
      expect(cats[0].id, 'sohrai');
      expect(cats[0].nameLatin, 'Sohrai'); // first-seen casing preserved
      expect(cats[1].id, 'baha');
    });

    test('skips null/blank categories and preserves first-seen order', () {
      final cats = RhymeCatalog.collectCategories([
        _rhyme('a', category: 'Baha'),
        _rhyme('b'),
        _rhyme('c', category: '  '),
        _rhyme('d', category: 'Sohrai'),
      ]);
      expect(cats.map((c) => c.id), ['baha', 'sohrai']);
    });
  });

  group('filterRhymes', () {
    test('category match is case-insensitive', () {
      final list = [
        _rhyme('a', category: 'Sohrai'),
        _rhyme('b', category: 'baha'),
      ];
      final out = RhymeCatalog.filterRhymes(
        list,
        categoryId: 'sohrai',
        categoryName: 'Sohrai',
      );
      expect(out.map((r) => r.id), ['a']);
    });

    test('tag filter is exact', () {
      final list = [
        _rhyme('a', tags: ['kids']),
        _rhyme('b'),
      ];
      expect(RhymeCatalog.filterRhymes(list, tag: 'kids').map((r) => r.id), [
        'a',
      ]);
    });

    test('no filters returns everything', () {
      final list = [_rhyme('a'), _rhyme('b')];
      expect(RhymeCatalog.filterRhymes(list).length, 2);
    });
  });

  group('selectFeatured', () {
    test('prefers the isFeatured item', () {
      final list = [_rhyme('a'), _rhyme('b', isFeatured: true), _rhyme('c')];
      final result = RhymeCatalog.selectFeatured(list);
      expect(result.featured?.id, 'b');
      expect(result.grid.map((r) => r.id), ['a', 'c']);
    });

    test('falls back to first item and excludes it from grid', () {
      final list = [_rhyme('a'), _rhyme('b')];
      final result = RhymeCatalog.selectFeatured(list);
      expect(result.featured?.id, 'a');
      expect(result.grid.map((r) => r.id), ['b']);
    });

    test('single item: featured set, grid empty', () {
      final result = RhymeCatalog.selectFeatured([_rhyme('a')]);
      expect(result.featured?.id, 'a');
      expect(result.grid, isEmpty);
    });

    test('empty list: both empty', () {
      final result = RhymeCatalog.selectFeatured([]);
      expect(result.featured, isNull);
      expect(result.grid, isEmpty);
    });
  });
}
