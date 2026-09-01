import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'package:itun/core/theme/app_colors.dart';
import 'package:itun/shared/models/content/quiz_model.dart';
import '../lesson_block_widgets.dart';
import 'lesson_block_glass_card.dart';

/// Call-to-action view for embedded inline quiz blocks inside a lesson.
class LessonBlockQuizCTA extends StatelessWidget {
  const LessonBlockQuizCTA({
    super.key,
    required this.quizId,
    required this.quiz,
    required this.accentColor,
    required this.isDark,
    required this.maxHeight,
    required this.onDismiss,
    this.isDismissed = false,
  });

  final String quizId;
  final QuizModel quiz;
  final Color accentColor;
  final bool isDark;
  final double maxHeight;
  final VoidCallback onDismiss;
  final bool isDismissed;

  @override
  Widget build(BuildContext context) {
    final isAccentLight =
        ThemeData.estimateBrightnessForColor(accentColor) == Brightness.light;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: maxHeight),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: LessonBlockGlassCard(
              themeColor: accentColor,
              isDark: isDark,
              radius: 28,
              padding: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Celebration Icon Header
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      isDismissed
                          ? Icons.check_circle_outline_rounded
                          : Icons.emoji_events_rounded,
                      color: accentColor,
                      size: 38,
                    ),
                  ).animate().scale(
                    duration: 400.ms,
                    curve: Curves.easeOutBack,
                  ),
                  const SizedBox(height: 24),
                  // Title / Prompt
                  Text(
                    isDismissed ? 'Lesson Completed!' : 'Ready to test yourself?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isDismissed
                        ? 'Great job! You can retake "${quiz.title ?? 'the quiz'}" anytime or finish the lesson.'
                        : 'Great job! Take "${quiz.title ?? 'the quiz'}" now to test your knowledge.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? Colors.white70
                          : AppColors.textSecondaryLight,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Primary Action Button
                  if (isDismissed) ...[
                    Tactile3DButton(
                      color: accentColor,
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/');
                        }
                      },
                      child: Text(
                        'FINISH LESSON',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: isAccentLight ? Colors.black : Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.push('/quiz/$quizId'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Take Quiz Now',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white70
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ] else ...[
                    Tactile3DButton(
                      color: accentColor,
                      onPressed: () {
                        context.push('/quiz/$quizId');
                      },
                      child: Text(
                        'TAKE THE QUIZ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: isAccentLight ? Colors.black : Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: onDismiss,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Skip for now',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white70
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
