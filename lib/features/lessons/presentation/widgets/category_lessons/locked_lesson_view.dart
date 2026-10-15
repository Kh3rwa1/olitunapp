import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import 'locked_lesson_overlay.dart';

/// Full-screen progression guard for direct lesson deep links.
class LockedLessonView extends StatelessWidget {
  const LockedLessonView({
    super.key,
    required this.isDark,
    required this.blockingLessonTitle,
    required this.blockingLessonId,
    required this.onBack,
  });

  final bool isDark;
  final String? blockingLessonTitle;
  final String? blockingLessonId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.quizDarkBackground
          : AppColors.lightBackground,
      // A soft glow ties the card to the page instead of floating on white.
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 0.9,
            colors: [
              AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.12),
              AppColors.primary.withValues(alpha: 0),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: LockedLessonCard(
                blockingLessonTitle: blockingLessonTitle,
                onPrimary: () {
                  final targetId = blockingLessonId;
                  if (targetId != null && targetId.isNotEmpty) {
                    context.push('/lesson/$targetId/block/0');
                  } else {
                    onBack();
                  }
                },
                onSecondary: onBack,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
