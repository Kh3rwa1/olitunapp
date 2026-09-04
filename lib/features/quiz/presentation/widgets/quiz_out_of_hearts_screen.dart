import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/content_models.dart';
import '../../domain/quiz_scoring_rules.dart';
import '../providers/quiz_session_notifier.dart';
import '../../../../core/ads/rewarded_ad_manager.dart';
import '../../../../core/ads/widgets/native_ad_widget.dart';
import '../../../../core/ads/widgets/banner_ad_widget.dart';

class QuizOutOfHeartsScreen extends ConsumerWidget {
  final int score;
  final int totalQuestions;
  final int bonusStars;
  final List<int> incorrectQuestionIndices;
  final List<QuizQuestion> questions;
  final String quizId;

  const QuizOutOfHeartsScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.bonusStars,
    required this.incorrectQuestionIndices,
    required this.questions,
    required this.quizId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalStars = QuizScoringRules.calculateStars(
      score,
      bonusStars: bonusStars,
    );

    void showMistakesSheet() {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        barrierColor: Colors.black.withValues(alpha: 0.7),
        builder: (sheetContext) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            padding: EdgeInsets.fromLTRB(
              24,
              28,
              24,
              24 + MediaQuery.of(sheetContext).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F141C) : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Review Mistakes',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppColors.pureBlack,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Close review sheet',
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Review what you got incorrect to build your mastery! Laha se!',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: incorrectQuestionIndices.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final qIdx = incorrectQuestionIndices[index];
                      if (qIdx >= questions.length || qIdx < 0) {
                        return const SizedBox.shrink();
                      }
                      final q = questions[qIdx];
                      final correctAns = q.optionsLatin.length > q.correctIndex
                          ? q.optionsLatin[q.correctIndex]
                          : '';
                      final correctAnsOlChiki =
                          q.optionsOlChiki.length > q.correctIndex
                          ? q.optionsOlChiki[q.correctIndex]
                          : '';
                      final showSeparateOlChiki =
                          correctAnsOlChiki.isNotEmpty &&
                          correctAnsOlChiki.trim() != correctAns.trim();

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B).withValues(alpha: 0.3)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${index + 1}.',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.error,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (q.promptOlChiki.isNotEmpty)
                                        Text(
                                          q.promptOlChiki,
                                          style: const TextStyle(
                                            fontFamily: 'OlChiki',
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      if (q.promptLatin != null)
                                        Text(
                                          q.promptLatin!,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isDark
                                                ? Colors.white60
                                                : Colors.black54,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.success.withValues(
                                    alpha: 0.25,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: AppColors.success,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Correct:',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? AppColors.brandTextDark
                                              : AppColors.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  if (showSeparateOlChiki) ...[
                                    Text(
                                      correctAnsOlChiki,
                                      style: TextStyle(
                                        fontFamily: 'OlChiki',
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.pureBlack,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                  ],
                                  Text(
                                    correctAns,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black87,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.quizDarkBackground : Colors.white,
      bottomNavigationBar: const BannerAdWidget(
        placement: 'quiz_out_of_hearts_bottom',
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const Spacer(),
              // Mascot visualizer with broken heart badge
              Center(
                child: SizedBox(
                  width: 136,
                  height: 136,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 124,
                        height: 124,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.error.withValues(alpha: 0.12)
                              : AppColors.error.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.25),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.error.withValues(alpha: 0.12),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Image.asset(
                              'assets/images/olitun_mascot.png',
                              fit: BoxFit.contain,
                              cacheWidth:
                                  (124 * MediaQuery.devicePixelRatioOf(context))
                                      .round(),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.quizDarkBackground
                                  : Colors.white,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.heart_broken_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 28),

              Text(
                'Out of Hearts!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppColors.pureBlack,
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 12),

              Text(
                'You answered $score/$totalQuestions correctly and earned $totalStars stars so far. Keep practicing to build your strength!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
              const Spacer(),

              const RepaintBoundary(
                child: NativeAdWidget(placement: 'quiz_out_of_hearts_native'),
              ),
              const SizedBox(height: 16),

              // Rewarded ad to refill hearts
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final rewarded = ref.read(rewardedAdManagerProvider);
                    final shown = await rewarded.show(
                      context: context,
                      placement: 'quiz_out_of_hearts',
                      rewardType: RewardType.hearts,
                      amount: 3,
                      onRewardGranted: () {
                        ref
                            .read(quizSessionNotifierProvider(quizId).notifier)
                            .reset();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Hearts Refilled! ❤️❤️❤️'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                    );
                    if (!shown && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Rewarded ad is cooling down. Please try regular reset.',
                          ),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                  label: const Text(
                    'Watch Ad to Refill Hearts (Free)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isDark
                        ? AppColors.error.withValues(alpha: 0.08)
                        : AppColors.error.withValues(alpha: 0.05),
                    side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms).scale(),
              const SizedBox(height: 12),

              // Try again CTA
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref
                        .read(quizSessionNotifierProvider(quizId).notifier)
                        .reset();
                  },
                  icon: const Icon(Icons.replay_rounded, size: 20),
                  label: const Text(
                    'Try Again',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 350.ms).scale(),
              const SizedBox(height: 12),

              // Review mistakes CTA (if any)
              if (incorrectQuestionIndices.isNotEmpty) ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: showMistakesSheet,
                    icon: Icon(
                      Icons.history_edu_rounded,
                      size: 20,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    label: Text(
                      'Review Mistakes',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: isDark ? Colors.white : AppColors.pureBlack,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms).scale(),
                const SizedBox(height: 12),
              ],

              // Back to quizzes CTA
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () => context.pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: isDark ? Colors.white60 : Colors.black54,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Back to Quizzes',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ).animate().fadeIn(delay: 450.ms),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
