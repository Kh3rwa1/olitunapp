import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/minimum_tap_target.dart';
import '../../../../shared/providers/providers.dart';
import '../../../quiz/presentation/providers/mistake_provider.dart';
import '../providers/mission_providers.dart';
import '../../../../../l10n/generated/app_localizations.dart';

class NextBestActionCard extends ConsumerWidget {
  final String? nextLessonId;
  const NextBestActionCard({super.key, this.nextLessonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    // Watch statistics and learning status
    final statsAsync = ref.watch(userStatsProvider);
    final mistakes = ref.watch(mistakeProvider);

    final isAuthAsync = ref.watch(isAuthenticatedProvider);
    final isGuest = isAuthAsync.value == false;
    final stats = statsAsync.value;
    final streak = stats?.currentStreak ?? 0;

    // Determine the state and copy
    String badgeText = l10n.continueLearning;
    String title = l10n.continueLearning;
    String subtitle = l10n.readyToLearn;
    String ctaText = l10n.continueButton;
    VoidCallback onTap = () {};
    IconData icon = Icons.star_rounded;
    Color color = AppColors.primary;

    final lessons = stats?.completedLessons;
    final completedAlphabet =
        lessons != null && lessons.any((id) => id.contains('alphabet'));
    final hasCompletedAlphabet =
        (stats?.alphabetProgress ?? 0) >= 1 || completedAlphabet;

    final completedNumbers =
        lessons != null && lessons.any((id) => id.contains('number'));
    final hasCompletedNumbers =
        (stats?.numbersProgress ?? 0) >= 1 || completedNumbers;

    if (isGuest || !hasCompletedAlphabet) {
      badgeText = l10n.nbaBadgeStartHere;
      title = l10n.nbaTitleFirstLetters;
      subtitle = l10n.nbaSubFirstLetters;
      ctaText = l10n.nbaCtaBeginLesson;
      icon = Icons.menu_book_rounded;
      color = AppColors.primary;
      onTap = () {
        context.push('/letter/standalone/all');
      };
    } else if (!hasCompletedNumbers) {
      badgeText = l10n.nbaBadgeNextStep;
      title = l10n.nbaTitleNumbers;
      subtitle = l10n.nbaSubNumbers;
      ctaText = l10n.nbaCtaPracticeNumbers;
      icon = Icons.pin_rounded;
      color = AppColors.brandBlue;
      onTap = () {
        context.push('/number/standalone/all');
      };
    } else if (mistakes.isNotEmpty) {
      badgeText = l10n.nbaBadgeMistakes;
      title = l10n.nbaTitleMistakes;
      subtitle = l10n.nbaSubMistakes(mistakes.length);
      ctaText = l10n.nbaCtaReviewMistakes;
      icon = Icons.psychology_rounded;
      color = AppColors.accentOchre;
      onTap = () {
        context.push('/mistakes');
      };
    } else if (streak > 0 &&
        !(ref.watch(lessonCompletedTodayProvider) ||
            ref.watch(quizTakenTodayProvider))) {
      badgeText = l10n.nbaBadgeStreakRisk;
      title = l10n.nbaTitleStreakRisk;
      subtitle = l10n.nbaSubStreakRisk(streak);
      ctaText = l10n.nbaCtaQuickReview;
      icon = Icons.local_fire_department_rounded;
      color = AppColors.accentOchre;
      onTap = () {
        context.push('/quizzes');
      };
    } else if (!ref.watch(bakhedListenedTodayProvider)) {
      badgeText = l10n.nbaBadgeTryBakhed;
      title = l10n.nbaTitleTryBakhed;
      subtitle = l10n.nbaSubTryBakhed;
      ctaText = l10n.nbaCtaListenNow;
      icon = Icons.music_note_rounded;
      color = AppColors.brandBlue;
      onTap = () {
        context.push('/bakhed');
      };
    } else if (nextLessonId == null &&
        hasCompletedAlphabet &&
        hasCompletedNumbers) {
      // Learner has exhausted the current catalogue — celebrate instead of
      // telling them to start over.
      badgeText = l10n.nbaBadgeAllDone;
      title = l10n.nbaTitleAllDone;
      subtitle = l10n.nbaSubAllDone;
      ctaText = l10n.nbaCtaExploreBakhed;
      icon = Icons.celebration_rounded;
      color = AppColors.accentGold;
      onTap = () {
        context.push('/bakhed');
      };
    } else {
      // Default: Active learning — the learner is mid-journey. Reuse
      // localized "resume" copy (present in every shipped locale) instead of
      // hardcoded English so non-English learners get the same next action.
      badgeText = l10n.resumeJourney;
      title = l10n.continueLearning;
      subtitle = l10n.readyToLearn;
      ctaText = l10n.continueButton;
      icon = Icons.play_arrow_rounded;
      color = AppColors.primary;
      onTap = () {
        if (nextLessonId != null && nextLessonId!.isNotEmpty) {
          context.push('/lesson/$nextLessonId');
        } else {
          context.push('/letter/standalone/all');
        }
      };
    }

    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: isDark
            ? LinearGradient(
                colors: [
                  const Color(0xFF1E293B).withValues(alpha: 0.8),
                  const Color(0xFF0F172A).withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.9),
                  AppColors.primary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.primary.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeText,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              BreathingPulse(
                maxScale: 1.12,
                period: const Duration(milliseconds: 2600),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: MinimumTapTarget(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      ctaText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 18)
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .slideX(
                          begin: -0.35,
                          end: 0,
                          duration: 900.ms,
                          curve: Curves.easeInOut,
                        ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return card;
    return card
        .animate()
        .fadeIn(duration: 420.ms, curve: Curves.easeOutCubic)
        .slideY(
          begin: 0.08,
          end: 0,
          duration: 420.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
