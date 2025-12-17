import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/bubble_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/animated_buttons.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/models/content_models.dart';

class CategoryLessonsScreen extends ConsumerWidget {
  final String categoryId;

  const CategoryLessonsScreen({
    super.key,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final lessons = ref.watch(lessonsByCategoryProvider(categoryId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final category = categories.when(
      data: (list) => list.where((c) => c.id == categoryId).firstOrNull,
      loading: () => null,
      error: (_, __) => null,
    );

    return BubbleBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: CircleIconButton(
            icon: Icons.arrow_back_rounded,
            onPressed: () => context.pop(),
          ),
          title: category != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.titleLatin),
                    if (category.titleOlChiki.isNotEmpty)
                      Text(
                        category.titleOlChiki,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'OlChiki',
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                  ],
                )
              : null,
        ),
        body: SafeArea(
          child: lessons.when(
            data: (lessonList) {
              if (lessonList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 64,
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      Text(
                        'No lessons yet',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingS),
                      Text(
                        'Check back soon for new content!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                itemCount: lessonList.length,
                itemBuilder: (context, index) {
                  final lesson = lessonList[index];
                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppConstants.spacingM,
                    ),
                    child: _LessonCard(
                      lesson: lesson,
                      index: index + 1,
                      onTap: () => context.pushNamed(
                        'lessonDetail',
                        pathParameters: {'lessonId': lesson.id},
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const ShimmerLessonList(itemCount: 5),
            error: (error, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: AppConstants.spacingM),
                  Text('Failed to load lessons: $error'),
                  const SizedBox(height: AppConstants.spacingM),
                  SecondaryButton(
                    text: 'Retry',
                    
                    onPressed: () => ref.refresh(lessonsByCategoryProvider(categoryId)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final LessonModel lesson;
  final int index;
  final VoidCallback? onTap;

  const _LessonCard({
    required this.lesson,
    required this.index,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Row(
        children: [
          // Lesson number
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                index.toString(),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppConstants.spacingM),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.titleLatin,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (lesson.titleOlChiki.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    lesson.titleOlChiki,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'OlChiki',
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                ],
                const SizedBox(height: AppConstants.spacingXS),
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${lesson.estimatedMinutes} min',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingM),
                    _buildLevelBadge(context, lesson.level),
                  ],
                ),
              ],
            ),
          ),

          // Arrow
          Icon(
            Icons.play_circle_filled_rounded,
            size: 32,
            color: AppColors.primaryCyan,
          ),
        ],
      ),
    );
  }

  Widget _buildLevelBadge(BuildContext context, String level) {
    Color color;
    switch (level) {
      case 'beginner':
        color = AppColors.success;
        break;
      case 'intermediate':
        color = AppColors.accentOrange;
        break;
      case 'advanced':
        color = AppColors.accentCoral;
        break;
      default:
        color = AppColors.primaryCyan;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        level.substring(0, 1).toUpperCase() + level.substring(1),
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
