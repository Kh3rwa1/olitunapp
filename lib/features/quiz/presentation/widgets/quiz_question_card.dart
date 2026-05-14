import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/content_models.dart';

class QuizQuestionCard extends StatelessWidget {
  final QuizQuestion question;

  const QuizQuestionCard({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
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
          Text(
            question.promptOlChiki,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              fontFamily: 'OlChiki',
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          if (question.promptLatin != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                question.promptLatin!,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }
}
