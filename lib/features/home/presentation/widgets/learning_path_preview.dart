import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/localized_content.dart';
import '../../../../shared/widgets/minimum_tap_target.dart';
import '../../../lessons/domain/entities/lesson_entity.dart';

class LearningPathPreview extends ConsumerWidget {
  final List<LessonEntity> lessons;
  final Set<String> completedLessonIds;
  final String? currentLessonId;
  final String scriptMode;

  const LearningPathPreview({
    super.key,
    required this.lessons,
    required this.completedLessonIds,
    required this.currentLessonId,
    required this.scriptMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (lessons.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Take up to 4 lessons to show a clean path preview
    final previewLessons = lessons.take(4).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.map_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Learning Path',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'PATH',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: isDark
                        ? AppColors.brandTextDark
                        : AppColors.brandTextLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: previewLessons.length,
            itemBuilder: (context, index) {
              final lesson = previewLessons[index];
              final isCompleted = completedLessonIds.contains(lesson.id);
              final isCurrent =
                  currentLessonId == lesson.id ||
                  (currentLessonId == null && index == 0 && !isCompleted);
              final isLocked =
                  !isCompleted &&
                  !isCurrent &&
                  index > 0 &&
                  !completedLessonIds.contains(previewLessons[index - 1].id);

              final title = primaryLocalizedText(
                olChiki: lesson.titleOlChiki,
                latin: lesson.titleLatin,
                scriptMode: scriptMode,
              );

              return _buildPathItem(
                context: context,
                title: title,
                isCompleted: isCompleted,
                isCurrent: isCurrent,
                isLocked: isLocked,
                isLast: index == previewLessons.length - 1,
                isDark: isDark,
                lessonId: lesson.id,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPathItem({
    required BuildContext context,
    required String title,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLocked,
    required bool isLast,
    required bool isDark,
    required String lessonId,
  }) {
    Color iconColor;
    Color bgColor;
    IconData icon;

    if (isCompleted) {
      iconColor = Colors.white;
      bgColor = AppColors.primary;
      icon = Icons.check_rounded;
    } else if (isCurrent) {
      iconColor = Colors.white;
      bgColor = isDark ? AppColors.brandTextDark : AppColors.brandTextLight;
      icon = Icons.play_arrow_rounded;
    } else {
      iconColor = isDark ? Colors.white30 : Colors.black38;
      bgColor = isDark ? Colors.white10 : Colors.black12;
      icon = isLocked
          ? Icons.lock_rounded
          : Icons.radio_button_unchecked_rounded;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Node & Connector
          Column(
            children: [
              MinimumTapTarget(
                onTap: isLocked
                    ? null
                    : () => context.push('/lessons/$lessonId'),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      if (isCurrent)
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Center(child: Icon(icon, color: iconColor, size: 16)),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 3,
                    color: isCompleted
                        ? AppColors.primary.withValues(alpha: 0.5)
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.black12),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: GestureDetector(
                onTap: isLocked
                    ? null
                    : () => context.push('/lessons/$lessonId'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppColors.primary.withValues(
                            alpha: isDark ? 0.1 : 0.05,
                          )
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCurrent
                          ? AppColors.primary.withValues(alpha: 0.3)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: isLocked
                                    ? (isDark ? Colors.white30 : Colors.black38)
                                    : (isDark
                                          ? Colors.white
                                          : const Color(0xFF1E293B)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      else if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (isDark
                                        ? AppColors.brandTextDark
                                        : AppColors.brandTextLight)
                                    .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Current',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.brandTextDark
                                  : AppColors.brandTextLight,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
