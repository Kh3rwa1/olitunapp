import 'package:flutter/material.dart';

import 'package:itun/core/theme/app_colors.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/features/lessons/presentation/widgets/dynamic_block_builder.dart';

class LessonMockupPreview extends StatelessWidget {
  final String lessonId;
  final List<LessonBlockEntity> blocks;
  final ScrollController previewScrollController;
  final int? hoveredOrFocusedIndex;
  final bool isDark;
  final ValueChanged<int> onBlockTapped;

  const LessonMockupPreview({
    super.key,
    required this.lessonId,
    required this.blocks,
    required this.previewScrollController,
    required this.hoveredOrFocusedIndex,
    required this.isDark,
    required this.onBlockTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      alignment: Alignment.center,
      child: Container(
        // Outer Device Mockup Container
        width: 320,
        height: 600,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F1A24) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(44),
          border: Border.all(
            color: isDark ? const Color(0xFF1C2C3E) : Colors.black87,
            width: 12,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.2),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Status bar area mimic with Speaker notch / camera cutout
            Container(
              height: 32,
              color: isDark ? const Color(0xFF0A0E14) : Colors.white,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 0,
                    child: Container(
                      width: 120,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.signal_cellular_4_bar_rounded,
                          size: 11,
                          color: isDark ? Colors.white60 : Colors.black45,
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.battery_std_rounded,
                          size: 11,
                          color: isDark ? Colors.white60 : Colors.black45,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 16,
                    child: Text(
                      '9:41',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white60 : Colors.black45,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Inner Mock phone AppBar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0A0E14) : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: const LinearProgressIndicator(
                        value: 0.45,
                        minHeight: 8,
                        backgroundColor: Color(0xFFE5E7EB),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        color: Colors.red,
                        size: 14,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '5',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Main Mock Content Viewport
            Expanded(
              child: Container(
                color: isDark ? const Color(0xFF0A0E14) : Colors.white,
                child: blocks.isEmpty
                    ? _buildMockupEmptyState(isDark)
                    : ListView.builder(
                        controller: previewScrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 20,
                        ),
                        itemCount: blocks.length,
                        itemBuilder: (context, index) {
                          final block = blocks[index];
                          final isHighlighted = index == hoveredOrFocusedIndex;

                          return GestureDetector(
                            onTap: () => onBlockTapped(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF152232)
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isHighlighted
                                      ? const Color(0xFF2ECC71)
                                      : (isDark
                                            ? Colors.white12
                                            : Colors.black.withValues(
                                                alpha: 0.05,
                                              )),
                                  width: isHighlighted ? 2.5 : 1,
                                ),
                                boxShadow: isHighlighted
                                    ? [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF2ECC71,
                                          ).withValues(alpha: 0.4),
                                          blurRadius: 12,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: isDark ? 0.15 : 0.03,
                                          ),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                              ),
                              child: IgnorePointer(
                                child: DynamicBlockBuilder(
                                  lessonId: lessonId,
                                  block: block,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMockupEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('📝', style: TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Content Yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create blocks on the left editor panel. They will instantly render here in real-time!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white30 : Colors.black45,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
