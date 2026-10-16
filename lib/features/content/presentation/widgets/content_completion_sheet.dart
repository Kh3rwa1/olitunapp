import 'package:flutter/material.dart';

import 'package:itun/core/theme/app_colors.dart';
import 'package:itun/features/quiz/domain/lesson_quiz_recommender.dart';

import '../../../../l10n/generated/app_localizations.dart';

/// Shows the non-dismissible completion celebration sheet for a finished
/// content item, with a quiz CTA when [recommendation] is available.
///
/// [onStartQuiz] and [onStepBack] run after the sheet has closed itself and
/// must navigate with the caller's (detail screen) context. [bonusAction] is
/// an optional extra button shown above the back action.
Future<void> showContentCompletionSheet(
  BuildContext context, {
  LessonQuizRecommendation? recommendation,
  required ValueChanged<String> onStartQuiz,
  required VoidCallback onStepBack,
  Widget? bonusAction,
}) {
  return showModalBottomSheet<void>(
    useRootNavigator: true,
    context: context,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (_) => ContentCompletionSheet(
      recommendation: recommendation,
      onStartQuiz: onStartQuiz,
      onStepBack: onStepBack,
      bonusAction: bonusAction,
    ),
  );
}

/// Body of the content completion sheet (trophy, copy, quiz/back actions).
class ContentCompletionSheet extends StatelessWidget {
  const ContentCompletionSheet({
    super.key,
    this.recommendation,
    required this.onStartQuiz,
    required this.onStepBack,
    this.bonusAction,
  });

  final LessonQuizRecommendation? recommendation;
  final ValueChanged<String> onStartQuiz;
  final VoidCallback onStepBack;
  final Widget? bonusAction;

  @override
  Widget build(BuildContext context) {
    final recommendation = this.recommendation;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recommendedQuiz = recommendation?.quiz;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.quizDarkCardAlt : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: AppColors.largeShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: AppColors.primary,
              size: 44,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            recommendedQuiz == null
                ? 'Practice Complete!'
                : 'Ready for a Quiz?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            recommendedQuiz == null
                ? 'Superb! You finished this module successfully.'
                : recommendation!.isRetake
                ? 'Nice work. Retake "${recommendedQuiz.title ?? 'this quiz'}" now to sharpen your score.'
                : 'Great finish. Start "${recommendedQuiz.title ?? 'this quiz'}" now while the lesson is fresh.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15),
          ),
          if (recommendation != null) ...[
            const SizedBox(height: 10),
            Text(
              recommendation.reason,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (recommendedQuiz != null) ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onStartQuiz(recommendedQuiz.id);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.quiz_rounded),
                label: Text(
                  AppLocalizations.of(context)!.startQuiz2,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (bonusAction case final bonusAction?) ...[
            bonusAction,
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () {
                // Close sheet and step back to the lesson screen.
                Navigator.pop(context);
                onStepBack();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.white : Colors.black87,
                side: BorderSide(
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                recommendedQuiz == null ? 'Back to Lessons' : 'Maybe Later',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
