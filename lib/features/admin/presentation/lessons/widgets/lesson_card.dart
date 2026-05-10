import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../lessons/domain/entities/lesson_entity.dart';
import '../../../../../shared/widgets/gamified_card.dart';

class LessonCard extends StatelessWidget {
  final LessonEntity lesson;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const LessonCard({
    super.key,
    required this.lesson,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GamifiedCard(
        color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
        borderRadius: 20,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.premiumCyan,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.titleOlChiki,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${lesson.blocks.length} CONTENT BLOCKS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onEdit,
              icon: Icon(
                Icons.edit_note_rounded,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
              tooltip: 'Edit Details',
            ),
            IconButton(
              onPressed: () => context.go('/admin/lessons/content/${lesson.id}'),
              icon: Icon(
                Icons.playlist_add_rounded,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              tooltip: 'Edit Content',
            ),
            IconButton(
              onPressed: onDelete,
              icon: Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error.withValues(alpha: 0.8),
              ),
              tooltip: 'Delete Lesson',
            ),
          ],
        ),
      ),
    );
  }
}
