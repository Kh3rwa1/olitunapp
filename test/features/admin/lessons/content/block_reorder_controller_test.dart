import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/presentation/lessons/content/controllers/block_reorder_controller.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';

LessonBlockEntity _block(String text) {
  return LessonBlockEntity(type: 'text', textLatin: text);
}

void main() {
  group('reorderLessonBlocks', () {
    test('moves a block down using ReorderableListView indexes', () {
      final blocks = [_block('a'), _block('b'), _block('c')];

      final reordered = reorderLessonBlocks(blocks, 0, 3);

      expect(reordered.map((block) => block.textLatin), ['b', 'c', 'a']);
      expect(blocks.map((block) => block.textLatin), ['a', 'b', 'c']);
    });

    test('moves a block up', () {
      final blocks = [_block('a'), _block('b'), _block('c')];

      final reordered = reorderLessonBlocks(blocks, 2, 0);

      expect(reordered.map((block) => block.textLatin), ['c', 'a', 'b']);
    });

    test('rejects invalid indexes', () {
      final blocks = [_block('a')];

      expect(() => reorderLessonBlocks(blocks, -1, 0), throwsRangeError);
      expect(() => reorderLessonBlocks(blocks, 0, 2), throwsRangeError);
    });
  });
}
