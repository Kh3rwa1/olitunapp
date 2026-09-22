import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/presentation/animations/scale_button.dart';
import '../../../domain/entities/lesson_entity.dart';

/// Quiz CTA block that navigates to the quiz screen.
class DynamicQuizBlock extends StatelessWidget {
  final LessonBlockEntity block;
  final Color accentColor;
  final LinearGradient brandGradient;

  const DynamicQuizBlock({
    super.key,
    required this.block,
    required this.accentColor,
    required this.brandGradient,
  });

  @override
  Widget build(BuildContext context) {
    final quizRefId =
        (block.data?['quizId'] ?? block.data?['quizRefId']) as String?;
    return ScaleButton(
      onPressed: () {
        if (quizRefId != null) {
          context.push('/quiz/$quizRefId');
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: brandGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.quiz_rounded, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Take a Quiz',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Test your knowledge now!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
