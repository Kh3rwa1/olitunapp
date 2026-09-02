import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/presentation/widgets/admin_lesson_block_text.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';

LessonEntity _lessonWith(List<LessonBlockEntity> blocks) => LessonEntity(
  id: 'lesson_1',
  categoryId: 'cat_1',
  titleOlChiki: 'ᱪᱮᱫᱼᱟᱢ',
  titleLatin: 'Lesson',
  blocks: blocks,
);

void main() {
  group('adminTextRowFromLessonBlock', () {
    test('returns null when a block has no text at all', () {
      final row = adminTextRowFromLessonBlock(
        const LessonBlockEntity(type: 'image'),
        0,
      );
      expect(row, isNull);
    });

    test('prefers block-level Ol Chiki and latin text fields', () {
      final row = adminTextRowFromLessonBlock(
        const LessonBlockEntity(
          type: 'text',
          textOlChiki: 'ᱚᱞ',
          textLatin: 'script',
        ),
        2,
      );
      expect(row, isNotNull);
      expect(row!.index, 2);
      expect(row.olChiki, 'ᱚᱞ');
      expect(row.latin, 'script');
      expect(row.meaning, 'script');
    });

    test('falls back to legacy data map keys for ol chiki and latin', () {
      final row = adminTextRowFromLessonBlock(
        const LessonBlockEntity(
          type: 'text',
          data: {'wordOlChiki': 'ᱡᱚᱦᱟᱨ', 'wordLatin': 'johar'},
        ),
        0,
      );
      expect(row!.olChiki, 'ᱡᱚᱦᱟᱨ');
      expect(row.latin, 'johar');
    });

    test('splits latin dash text into latin and meaning parts', () {
      final row = adminTextRowFromLessonBlock(
        const LessonBlockEntity(
          type: 'text',
          data: {'text': 'johar - hello greeting'},
        ),
        0,
      );
      expect(row!.latin, 'johar');
      expect(row.meaning, 'hello greeting');
    });

    test('explicit meaning in data wins over dash splitting', () {
      final row = adminTextRowFromLessonBlock(
        const LessonBlockEntity(
          type: 'text',
          data: {'textLatin': 'johar - hello', 'meaning': 'a greeting'},
        ),
        0,
      );
      expect(row!.latin, 'johar - hello');
      expect(row.meaning, 'a greeting');
    });

    test('collects media urls from block fields and data map', () {
      final row = adminTextRowFromLessonBlock(
        const LessonBlockEntity(
          type: 'text',
          textOlChiki: 'ᱚ',
          imageUrl: 'https://x/img.png',
          audioUrl: 'https://x/a.mp3',
          data: {'lottieUrl': 'https://x/anim.json'},
        ),
        0,
      );
      expect(row!.imageUrl, 'https://x/img.png');
      expect(row.audioUrl, 'https://x/a.mp3');
      expect(row.animationUrl, 'https://x/anim.json');
    });

    test('trims whitespace-only values to empty and skips empty blocks', () {
      final row = adminTextRowFromLessonBlock(
        const LessonBlockEntity(type: 'text', data: {'text': '   '}),
        0,
      );
      expect(row, isNull);
    });
  });

  test('adminTextRowsFromLessonBlocks keeps only text rows in order', () {
    final rows = adminTextRowsFromLessonBlocks(
      _lessonWith([
        const LessonBlockEntity(type: 'image'),
        const LessonBlockEntity(type: 'text', textOlChiki: 'ᱯᱩᱭᱞᱩ'),
        const LessonBlockEntity(
          type: 'text',
          data: {'text': 'second - meaning'},
        ),
      ]),
    );
    expect(rows, hasLength(2));
    expect(rows[0].index, 1);
    expect(rows[0].olChiki, 'ᱯᱩᱭᱞᱩ');
    expect(rows[1].index, 2);
    expect(rows[1].meaning, 'meaning');
  });
}
