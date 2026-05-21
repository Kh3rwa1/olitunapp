import '../../../../../lessons/domain/entities/lesson_entity.dart';

List<LessonBlockEntity> reorderLessonBlocks(
  List<LessonBlockEntity> blocks,
  int oldIndex,
  int newIndex,
) {
  if (oldIndex < 0 || oldIndex >= blocks.length) {
    throw RangeError.index(oldIndex, blocks, 'oldIndex');
  }
  if (newIndex < 0 || newIndex > blocks.length) {
    throw RangeError.index(newIndex, blocks, 'newIndex');
  }

  final reordered = List<LessonBlockEntity>.from(blocks);
  final targetIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
  final item = reordered.removeAt(oldIndex);
  reordered.insert(targetIndex, item);
  return reordered;
}
