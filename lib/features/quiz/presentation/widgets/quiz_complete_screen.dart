import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/motion/motion.dart';
import '../../../../shared/models/content_models.dart';
import '../../../../shared/providers/local_settings_provider.dart';
import '../../domain/quiz_scoring_rules.dart';
import 'mistake_review_card.dart';
import '../../../../core/ads/interstitial_ad_manager.dart';
import '../../../../core/ads/rewarded_ad_manager.dart';
import '../../../../core/ads/widgets/native_ad_widget.dart';
import '../../../../core/ads/widgets/banner_ad_widget.dart';
import '../../../../shared/widgets/sharing/share_card_payload.dart';
import '../../../../shared/widgets/sharing/social_share_modal.dart';

bool get _isTesting {
  try {
    final binding = WidgetsBinding.instance.runtimeType.toString();
    if (binding.contains('Test') || binding.contains('Integration')) {
      return true;
    }
  } catch (_) {}
  if (!kIsWeb) {
    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) return true;
    } catch (_) {}
  }
  return false;
}

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

    Widget buildBentoCard({
      required Widget child,
      required Color backgroundColor,
      required Color borderColor,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      );
    }

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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
                      final q = questions[qIdx];
                      final correctAns = q.optionsLatin[q.correctIndex];
                      final correctAnsOlChiki =
                          q.optionsOlChiki.length > q.correctIndex
                          ? q.optionsOlChiki[q.correctIndex]
                          : '';

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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.success,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Correct:',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? AppColors.brandTextDark
                                          : AppColors.brandTextLight,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (correctAnsOlChiki.isNotEmpty) ...[
                                    Text(
                                      correctAnsOlChiki,
                                      style: const TextStyle(
                                        fontFamily: 'OlChiki',
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text('•'),
                                    const SizedBox(width: 6),
                                  ],
                                  Expanded(
                                    child: Text(
                                      correctAns,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
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
                        Center(
                          child: Builder(
                            builder: (context) {
                              final trophy = Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  gradient: isPassing
                                      ? AppColors.premiumGreen
                                      : AppColors.premiumOrange,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (isPassing
                                                  ? AppColors.success
                                                  : AppColors.warning)
                                              .withValues(alpha: 0.35),
                                      blurRadius: 30,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isPassing
                                      ? Icons.emoji_events_rounded
                                      : Icons.refresh_rounded,
                                  size: 64,
                                  color: Colors.white,
                                ),
                              );

                              if (_isTesting || reduceEffects) {
                                return trophy;
                              }

                              return trophy
                                  .animate(
                                    onPlay: (c) => c.repeat(reverse: true),
                                  )
                                  .scale(
                                    begin: const Offset(1.0, 1.0),
                                    end: const Offset(1.06, 1.06),
                                    duration: 1200.ms,
                                    curve: Curves.easeInOutSine,
                                  );
                            },
                          ),
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
                        GridView.count(
                          shrinkWrap: true,
                          crossAxisCount: 2,
                          childAspectRatio: 1.25,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            // 1. Score Bento
                            buildBentoCard(
                              backgroundColor: AppColors.primary.withValues(
                                alpha: 0.10,
                              ),
                              borderColor: AppColors.primary.withValues(
                                alpha: 0.20,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.analytics_rounded,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Score',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$score / $totalQuestions',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.pureBlack,
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(delay: 200.ms).scale(),

                            // 2. Accuracy Bento
                            buildBentoCard(
                              backgroundColor:
                                  (isPassing
                                          ? AppColors.success
                                          : AppColors.error)
                                      .withValues(alpha: 0.10),
                              borderColor:
                                  (isPassing
                                          ? AppColors.success
                                          : AppColors.error)
                                      .withValues(alpha: 0.20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.track_changes_rounded,
                                    color: isPassing
                                        ? AppColors.success
                                        : AppColors.error,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Accuracy',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$percentage%',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: isPassing
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(delay: 250.ms).scale(),

                            // 3. Stars Bento
                            buildBentoCard(
                              backgroundColor: AppColors.accentGold.withValues(
                                alpha: 0.10,
                              ),
                              borderColor: AppColors.accentGold.withValues(
                                alpha: 0.20,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: AppColors.accentGold,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Stars Earned',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '+$totalStars',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.accentGoldDark,
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(delay: 300.ms).scale(),

                            // 4. Streak Bento
                            buildBentoCard(
                              backgroundColor: AppColors.accentOchre.withValues(
                                alpha: 0.10,
                              ),
                              borderColor: AppColors.accentOchre.withValues(
                                alpha: 0.20,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.local_fire_department_rounded,
                                    color: AppColors.accentOchre,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Max Combo',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$bestCombo',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.accentOchreDark,
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(delay: 350.ms).scale(),
                          ],
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Rewarded Bonus Stars Action
                      Consumer(
                        builder: (context, ref, _) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final rewarded = ref.read(
                                    rewardedAdManagerProvider,
                                  );
                                  final shown = await rewarded.show(
                                    context: context,
                                    placement: 'quiz_reward_bonus_stars',
                                    rewardType: RewardType.stars,
                                    amount: 50,
                                    onRewardGranted: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            'Bonus 50 Stars Earned! ⭐',
                                          ),
                                          backgroundColor: AppColors.success,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                  if (!shown && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          'Rewarded ad is cooling down. Try again later.',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(
                                  Icons.stars_rounded,
                                  color: AppColors.accentGoldDark,
                                  size: 22,
                                ),
                                label: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Watch Ad for +50 Bonus Stars',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accentGoldDark,
                                    ),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  side: const BorderSide(
                                    color: AppColors.accentGold,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      if (isPassing) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                SocialShareModal.show(
                                  context,
                                  payload: ShareCardPayload.quizResult(
                                    score: score,
                                    total: totalQuestions,
                                    percentage: percentage,
                                    stars: totalStars,
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.share_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              label: const Text(
                                'Share Achievement',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {
                            unawaited(
                              ref
                                  .read(interstitialAdManagerProvider)
                                  .showIfAllowed(context, 'quiz_complete'),
                            );
                            context.go('/');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.continueButton,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
