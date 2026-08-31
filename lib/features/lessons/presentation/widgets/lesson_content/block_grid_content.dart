import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/lesson_entity.dart';
import 'dynamic_block_grid_cell.dart';
import 'empty_content_placeholder.dart';
import 'lesson_content_helpers.dart';

/// Dynamic grid builder that renders the lesson's blocks directly to ensure
/// the grid view matches the list view item count perfectly (1:1 alignment).
class BlockGridContent extends ConsumerWidget {
  final String lessonId;
  final List<LessonBlockEntity> blocks;
  final String categoryId;

  const BlockGridContent({
    super.key,
    required this.lessonId,
    required this.blocks,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cleanCategory = categoryId.toLowerCase();
    final isAlphabet =
        cleanCategory.contains('alphabet') || cleanCategory.contains('letter');
    final isNumber = cleanCategory.contains('number');
    final isSentence =
        cleanCategory.contains('sentence') || cleanCategory.contains('phrase');

    if (blocks.isEmpty) {
      return EmptyContentPlaceholder(
        message: 'No items in this lesson. Add content blocks in admin.',
        isDark: isDark,
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: getResponsiveCrossAxisCount(context),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: isAlphabet
            ? 0.9
            : (isNumber ? 0.85 : (isSentence ? 0.82 : 0.85)),
      ),
      itemCount: blocks.length,
      itemBuilder: (context, index) {
        final block = blocks[index];
        return DynamicBlockGridCell(
          lessonId: lessonId,
          block: block,
          isAlphabet: isAlphabet,
          isNumber: isNumber,
          isSentence: isSentence,
        );
      },
    );
  }
}
