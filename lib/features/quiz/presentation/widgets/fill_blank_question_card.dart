import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/content_models.dart';

class FillBlankQuestionCard extends StatelessWidget {
  final QuizQuestion question;
  final int? selectedAnswer;
  final bool isAnswered;

  const FillBlankQuestionCard({
    super.key,
    required this.question,
    required this.selectedAnswer,
    required this.isAnswered,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final parts = question.blankSentenceOlChiki?.split('___') ?? ['', ''];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.quizDarkCard, AppColors.quizDarkCardAlt]
              : [AppColors.quizLightSuccessSurface, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.05 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              question.promptOlChiki,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white60 : Colors.black54,
                letterSpacing: 0.5,
              ),
            ),
          ),
          if (question.promptLatin != null) ...[
            const SizedBox(height: 6),
            Text(
              question.promptLatin!,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 36),

          // Premium Duolingo Mascot Speech Bubble representation
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Image.asset(
                      'assets/images/olitun_mascot.png',
                      fit: BoxFit.contain,
                      cacheWidth: (56 * MediaQuery.devicePixelRatioOf(context)).round(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.quizDarkBubble
                        : AppColors.quizLightBubble,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (parts.isNotEmpty && parts[0].trim().isNotEmpty)
                        Text(
                          parts[0].trim(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'OlChiki',
                          ),
                        ),

                      // Blank/Pulsing Slot or Filled option
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selectedAnswer != null
                              ? (isAnswered
                                    ? (selectedAnswer == question.correctIndex
                                          ? AppColors.success
                                          : AppColors.error)
                                    : AppColors.primary)
                              : (isDark
                                    ? AppColors.quizDarkCardAlt
                                    : Colors.white),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedAnswer != null
                                ? Colors.transparent
                                : AppColors.primary,
                            style: selectedAnswer != null
                                ? BorderStyle.none
                                : BorderStyle.solid,
                            width: 2,
                          ),
                          boxShadow: selectedAnswer != null
                              ? [
                                  BoxShadow(
                                    color:
                                        (isAnswered
                                                ? (selectedAnswer ==
                                                          question.correctIndex
                                                      ? AppColors.success
                                                      : AppColors.error)
                                                : AppColors.primary)
                                            .withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          selectedAnswer != null
                              ? question.optionsOlChiki[selectedAnswer!]
                              : ' ── ', // Empty blank line placeholder
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'OlChiki',
                            color: selectedAnswer != null
                                ? Colors.white
                                : AppColors.primary,
                          ),
                        ),
                      ),

                      if (parts.length > 1 && parts[1].trim().isNotEmpty)
                        Text(
                          parts[1].trim(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'OlChiki',
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (question.blankSentenceLatin != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.black.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Translation: "${question.blankSentenceLatin}"',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 450.ms).scale(begin: const Offset(0.96, 0.96));
  }
}
