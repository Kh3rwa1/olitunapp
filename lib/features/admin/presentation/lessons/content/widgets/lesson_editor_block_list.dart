import 'package:flutter/material.dart';

import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'lesson_block_card.dart';

class LessonEditorBlockList extends StatelessWidget {
  final ScrollController? scrollController;
  final List<LessonBlockEntity> blocks;
  final int? hoveredOrFocusedIndex;
  final bool isDark;
  final bool isWide;
  final String? categoryId;
  final String? categorySlug;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(int index, LessonBlockEntity block) onEditBlock;
  final ValueChanged<int> onDeleteBlock;
  final ValueChanged<int>? onSelectBlock;

  const LessonEditorBlockList({
    super.key,
    this.scrollController,
    required this.blocks,
    required this.hoveredOrFocusedIndex,
    required this.isDark,
    required this.isWide,
    required this.categoryId,
    required this.categorySlug,
    required this.onReorder,
    required this.onEditBlock,
    required this.onDeleteBlock,
    this.onSelectBlock,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      scrollController: scrollController,
      padding: EdgeInsets.fromLTRB(isWide ? 32 : 16, 12, isWide ? 32 : 16, 100),
      itemCount: blocks.length,
      buildDefaultDragHandles: false,
      // ignore: deprecated_member_use
      onReorder: onReorder,
      proxyDecorator: (child, index, animation) {
        return Material(
          elevation: 8,
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final block = blocks[index];
        final isHighlighted = index == hoveredOrFocusedIndex;

        return Container(
          // Value-keyed (no index suffix): keeps editor state bound to its
          // block across reorders. LessonBlockEntity has no stable id, so
          // the Equatable hashCode (stable per content within a session)
          // is used instead.
          key: ValueKey('block_${block.hashCode}'),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: isHighlighted
                ? [
                    BoxShadow(
                      color: const Color(0xFF2ECC71).withValues(alpha: 0.35),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: GestureDetector(
            onTap: () {
              onSelectBlock?.call(index);
              onEditBlock(index, block);
            },
            child: LessonBlockCard(
              index: index,
              block: block,
              isDark: isDark,
              onEdit: () => onEditBlock(index, block),
              onDelete: () => onDeleteBlock(index),
              categoryId: categoryId,
              categorySlug: categorySlug,
            ),
          ),
        );
      },
    );
  }
}
