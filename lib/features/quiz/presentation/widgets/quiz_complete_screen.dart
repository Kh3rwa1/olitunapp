import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/motion/motion.dart';
import '../../../../shared/models/content_models.dart';
import '../../../../shared/providers/local_settings_provider.dart';
import '../../domain/quiz_scoring_rules.dart';
import 'mistake_review_card.dart';
import '../../../../core/ads/widgets/native_ad_widget.dart';
import '../../../../core/ads/widgets/banner_ad_widget.dart';
import 'quiz_complete_actions.dart';
import 'quiz_complete_bento_stats.dart';
import 'quiz_complete_mistakes_sheet.dart';
import 'quiz_complete_trophy.dart';

class QuizCompleteScreen extends ConsumerWidget {
  final int score;
  final int totalQuestions;
  final int bestCombo;
  final int bonusStars;
  final List<int> incorrectQuestionIndices;
  final List<QuizQuestion> questions;

  const QuizCompleteScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.bestCombo,
    required this.bonusStars,
    required this.incorrectQuestionIndices,
    required this.questions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final percentage = totalQuestions > 0
        ? (score / totalQuestions * 100).round()
        : 0;
    final isPassing = QuizScoringRules.isPassing(score, totalQuestions);
    final totalStars = QuizScoringRules.calculateStars(
      score,
      bonusStars: bonusStars,
    );
    final reduceEffects = ref.watch(reduceVisualEffectsProvider);

    void showMistakesSheet() {
      showQuizMistakesSheet(
        context: context,
        isDark: isDark,
        incorrectQuestionIndices: incorrectQuestionIndices,
        questions: questions,
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.quizDarkBackground : Colors.white,
      bottomNavigationBar: const BannerAdWidget(
        placement: 'quiz_complete_bottom',
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        // Circular trophy reward visualizer
                        QuizCompleteTrophy(
                          isPassing: isPassing,
                          reduceEffects: reduceEffects,
                        ),
                        const SizedBox(height: 28),
                        Text(
                          isPassing
                              ? AppLocalizations.of(context)!.wellDone
                              : AppLocalizations.of(context)!.keepPracticing,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppColors.pureBlack,
                            letterSpacing: -0.5,
                          ),
                        ).animate().fadeIn(duration: 400.ms),
                        const SizedBox(height: 6),
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.youScored(score, totalQuestions),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
                        const SizedBox(height: 28),

                        // Bento Stats Grid
                        QuizCompleteBentoStats(
                          isDark: isDark,
                          score: score,
                          totalQuestions: totalQuestions,
                          percentage: percentage,
                          isPassing: isPassing,
                          totalStars: totalStars,
                          bestCombo: bestCombo,
                        ),
                        const SizedBox(height: 24),

                        // Mistakes Review Trigger
                        if (incorrectQuestionIndices.isNotEmpty)
                          MistakeReviewCard(
                            mistakeCount: incorrectQuestionIndices.length,
                            onTap: showMistakesSheet,
                            ctaLabel: 'Review Mistakes',
                            animationIndex: 5,
                          ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1),

                        const SizedBox(height: 16),
                        const RepaintBoundary(
                          child: NativeAdWidget(
                            placement: 'quiz_complete_native',
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                QuizCompleteActions(
                  isPassing: isPassing,
                  score: score,
                  totalQuestions: totalQuestions,
                  percentage: percentage,
                  totalStars: totalStars,
                ).animate().fadeIn(delay: 500.ms),
              ],
            ),
          ),
          if (isPassing) const Positioned.fill(child: ConfettiBurst()),
        ],
      ),
    );
  }
}
