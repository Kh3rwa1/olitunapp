import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/categories/domain/entities/category_entity.dart';

class PaywallCourseDetails extends StatelessWidget {
  final CategoryEntity category;
  final bool isDark;

  const PaywallCourseDetails({
    super.key,
    required this.category,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final hasDescription =
        category.courseDescription != null &&
        category.courseDescription!.trim().isNotEmpty;
    final hasOutcome =
        category.courseOutcome != null &&
        category.courseOutcome!.trim().isNotEmpty;

    if (!hasDescription && !hasOutcome) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasDescription) ...[
          Text(
            'About this course',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.87)
                  : Colors.black87,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            category.courseDescription!,
            style: AppTypography.bodySmall.copyWith(
              height: 1.5,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (hasOutcome) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : AppColors.primary.withValues(alpha: 0.04),
              borderRadius: AppRadius.borderXl,
              border: Border.all(
                color: isDark
                    ? Colors.white10
                    : AppColors.primary.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.insights_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Course Outcome',
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  category.courseOutcome!,
                  style: AppTypography.bodySmall.copyWith(
                    height: 1.4,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ],
    );
  }
}
