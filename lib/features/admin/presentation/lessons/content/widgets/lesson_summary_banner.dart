import 'package:flutter/material.dart';

import 'package:itun/core/theme/app_colors.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';

class LessonSummaryBanner extends StatelessWidget {
  final List<LessonBlockEntity> blocks;
  final bool isDark;
  final bool isWide;

  const LessonSummaryBanner({
    super.key,
    required this.blocks,
    required this.isDark,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    final blockTypes = <String, int>{};
    for (final b in blocks) {
      blockTypes[b.type] = (blockTypes[b.type] ?? 0) + 1;
    }

    return Container(
      margin: EdgeInsets.fromLTRB(isWide ? 32 : 16, 12, isWide ? 32 : 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : AppColors.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: isDark
                ? Colors.white30
                : AppColors.primary.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.4)
                      : Colors.black45,
                ),
                children: [
                  TextSpan(
                    text:
                        '${blocks.length} block${blocks.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  if (blockTypes.isNotEmpty) ...[
                    const TextSpan(text: '  •  '),
                    TextSpan(
                      text: blockTypes.entries
                          .map((e) => '${e.value} ${e.key}')
                          .join(', '),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LessonEmptyBlocksState extends StatelessWidget {
  final bool isDark;
  final VoidCallback onAddFirstBlock;

  const LessonEmptyBlocksState({
    super.key,
    required this.isDark,
    required this.onAddFirstBlock,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.dashboard_customize_rounded,
              size: 36,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No content blocks yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Add Block" below to start building\nyour lesson content.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.3),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onAddFirstBlock,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text(
              'Add Your First Block',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
