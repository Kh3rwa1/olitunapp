import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/accessibility/learning_semantics.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/content_models.dart';

class QuizQuestionCard extends StatelessWidget {
  final QuizQuestion question;
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback? onPlayAudio;

  const QuizQuestionCard({
    super.key,
    required this.question,
    this.isPlaying = false,
    this.isLoading = false,
    this.onPlayAudio,
  });

  @override
  Widget build(BuildContext context) {
    final isLongPrompt =
        question.promptOlChiki.length > 12 ||
        question.promptOlChiki.contains(' ');

    final hasAudio =
        (question.audioUrl != null && question.audioUrl!.trim().isNotEmpty) ||
        onPlayAudio != null;

    Widget promptWidget = Text(
      question.promptOlChiki,
      style: TextStyle(
        fontSize: isLongPrompt ? 32 : 48,
        fontWeight: FontWeight.w900,
        fontFamily: 'OlChiki',
        color: Colors.white,
        height: 1.3,
      ),
      textAlign: TextAlign.center,
    );

    if (!isLongPrompt) {
      promptWidget = FittedBox(fit: BoxFit.scaleDown, child: promptWidget);
    }

    return Semantics(
      key: const ValueKey('quiz-question-semantics'),
      container: true,
      label: LearningSemantics.quizQuestion(
        prompt: question.promptOlChiki,
        latin: question.promptLatin,
      ),
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              promptWidget,
              if (question.promptLatin != null &&
                  question.promptLatin!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    question.promptLatin!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (hasAudio) ...[
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: onPlayAudio,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isPlaying
                          ? Colors.white.withValues(alpha: 0.28)
                          : Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isPlaying
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: isPlaying
                          ? [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.3),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isLoading)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        else
                          Icon(
                            isPlaying
                                ? Icons.volume_up_rounded
                                : Icons.play_circle_outline_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        const SizedBox(width: 8),
                        Text(
                          isPlaying ? 'PLAYING...' : 'TAP TO LISTEN',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    .animate(
                      target: isPlaying ? 1 : 0,
                    )
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.05, 1.05),
                      duration: 600.ms,
                      curve: Curves.easeInOut,
                    ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }
}
