import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/content_models.dart';
import 'wrong_answer_shake.dart';

class QuizOptionTile extends StatelessWidget {
  final int index;
  final int currentQuestion;
  final QuizQuestion question;
  final bool isSelected;
  final bool isAnswered;
  final VoidCallback onTap;

  const QuizOptionTile({
    super.key,
    required this.index,
    required this.currentQuestion,
    required this.question,
    required this.isSelected,
    required this.isAnswered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCorrect = index == question.correctIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor;
    if (isAnswered) {
      if (isCorrect) {
        bgColor = AppColors.success;
      } else if (isSelected && !isCorrect) {
        bgColor = AppColors.error;
      } else {
        bgColor = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white;
      }
    } else {
      bgColor = isSelected
          ? AppColors.primary.withValues(alpha: 0.15)
          : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white);
    }

    return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PressableScale(
            enabled: !isAnswered,
            haptic: HapticIntensity.none,
            onTap: isAnswered ? null : onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.05)),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected && !isAnswered
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 15,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: (isAnswered && isCorrect)
                          ? Colors.white
                          : (isSelected
                                ? AppColors.primary
                                : Colors.transparent),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected || (isAnswered && isCorrect)
                            ? Colors.transparent
                            : (isDark ? Colors.white24 : Colors.black12),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + index),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: (isAnswered && isCorrect)
                              ? AppColors.success
                              : (isSelected
                                    ? Colors.white
                                    : (isDark
                                          ? Colors.white54
                                          : Colors.black45)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      question.optionsLatin[index],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: (isAnswered && (isCorrect || isSelected))
                            ? Colors.white
                            : (isDark ? Colors.white : Colors.black),
                      ),
                    ),
                  ),
                  if (isAnswered && isCorrect)
                    const Icon(Icons.check_circle_rounded, color: Colors.white),
                  if (isAnswered && isSelected && !isCorrect)
                    const Icon(Icons.cancel_rounded, color: Colors.white),
                ],
              ),
            ),
          ),
        )
        .animate(key: ValueKey('opt-$currentQuestion-$index-$isAnswered'))
        .fadeIn(
          delay: isAnswered ? Duration.zero : (index * 80).ms,
          duration: 300.ms,
        )
        .then()
        .swap(
          builder: (context, childWidget) {
            final child = childWidget ?? const SizedBox.shrink();
            if (!isAnswered) return child;
            if (isCorrect) {
              return child
                  .animate()
                  .scaleXY(
                    begin: 1.0,
                    end: 1.04,
                    duration: 180.ms,
                    curve: const Cubic(0.34, 1.56, 0.64, 1.0),
                  )
                  .then()
                  .scaleXY(begin: 1.0, end: 1 / 1.04, duration: 220.ms);
            }
            if (isSelected && !isCorrect) {
              return WrongAnswerShake(child: child);
            }
            return child;
          },
        );
  }
}
