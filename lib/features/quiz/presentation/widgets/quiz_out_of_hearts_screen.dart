import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'quiz_complete_mistakes_sheet.dart';
import '../../../../core/presentation/layout/responsive_layout.dart';
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
      showQuizMistakesSheet(
        context: context,
        isDark: isDark,
        incorrectQuestionIndices: incorrectQuestionIndices,
        questions: questions,
      );
    }

    final isDesktopWeb =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;

    void onTryAgain() {
      ref.read(quizSessionNotifierProvider(quizId).notifier).reset();
    }

    final shortcuts = <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.enter): onTryAgain,
      const SingleActivator(LogicalKeyboardKey.numpadEnter): onTryAgain,
      const SingleActivator(LogicalKeyboardKey.space): onTryAgain,
    };

    return CallbackShortcuts(
      bindings: shortcuts,
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: isDark ? AppColors.quizDarkBackground : Colors.white,
          bottomNavigationBar: const BannerAdWidget(
            placement: 'quiz_out_of_hearts_bottom',
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: ResponsiveLayout.maxNarrowWidth(context),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
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
                                    color: AppColors.error.withValues(
                                      alpha: 0.25,
                                    ),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.error.withValues(
                                        alpha: 0.12,
                                      ),
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
                                          (124 *
                                                  MediaQuery.devicePixelRatioOf(
                                                    context,
                                                  ))
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
                                        color: Colors.black.withValues(
                                          alpha: 0.15,
                                        ),
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
                      ).animate().scale(
                        duration: 600.ms,
                        curve: Curves.easeOutBack,
                      ),
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
                        child: NativeAdWidget(
                          placement: 'quiz_out_of_hearts_native',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Rewarded ad to refill hearts
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final rewarded = ref.read(
                              rewardedAdManagerProvider,
                            );
                            final shown = await rewarded.show(
                              context: context,
                              placement: 'quiz_out_of_hearts',
                              rewardType: RewardType.hearts,
                              amount: 3,
                              onRewardGranted: () {
                                ref
                                    .read(
                                      quizSessionNotifierProvider(
                                        quizId,
                                      ).notifier,
                                    )
                                    .reset();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Hearts Refilled! ❤️❤️❤️',
                                    ),
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
                                .read(
                                  quizSessionNotifierProvider(quizId).notifier,
                                )
                                .reset();
                          },
                          icon: const Icon(Icons.replay_rounded, size: 20),
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Try Again',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              if (isDesktopWeb) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Enter ↵',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
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
                                color: isDark
                                    ? Colors.white
                                    : AppColors.pureBlack,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: isDark
                                    ? Colors.white24
                                    : Colors.grey.shade300,
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
                            foregroundColor: isDark
                                ? Colors.white60
                                : Colors.black54,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Back to Quizzes',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 450.ms),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
