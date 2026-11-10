import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/providers.dart';
import '../../../quiz/presentation/providers/mistake_provider.dart';
import '../providers/mission_providers.dart';
import '../providers/displayed_streak_provider.dart';
import '../../../practice/daily/presentation/daily_practice_screen.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import 'package:itun/features/profile/presentation/providers/profile_providers.dart';

class NextBestActionCard extends ConsumerWidget {
  final String? nextLessonId;
  const NextBestActionCard({super.key, this.nextLessonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    // Watch only the stats fields this card decides on, so unrelated stats
    // updates (XP, quiz history, sync flags) don't rebuild it.
    final stats = ref.watch(
      userStatsProvider.select((async) {
        final s = async.value;
        return (
          lessons: s?.completedLessons,
          totalStars: s?.totalStars ?? 0,
          alphabetProgress: s?.alphabetProgress ?? 0.0,
        );
      }),
    );
    final mistakeCount = ref.watch(mistakeProvider.select((m) => m.length));

    // Honest streak (derived from practice dates), not the stored counter.
    final streak = ref.watch(displayedStreakProvider);
    final streakAtRisk = ref.watch(streakAtRiskProvider);

    // Determine the state and copy
    String badgeText = l10n.continueLearning;
    String title = l10n.continueLearning;
    String subtitle = l10n.readyToLearn;
    String ctaText = l10n.continueButton;
    VoidCallback onTap = () {};
    IconData icon = Icons.star_rounded;

    final lessons = stats.lessons;
    final hasAnyProgress =
        (lessons?.isNotEmpty ?? false) || streak > 0 || stats.totalStars > 0;
    final completedAlphabet =
        lessons != null && lessons.any((id) => id.contains('alphabet'));
    final hasCompletedAlphabet =
        stats.alphabetProgress >= 1 || completedAlphabet;

    final lastOpenedId = ref.watch(lastOpenedLessonIdProvider)?.trim();
    final isResumingIncompleteLesson =
        lastOpenedId != null &&
        lastOpenedId.isNotEmpty &&
        (lessons == null || !lessons.contains(lastOpenedId)) &&
        nextLessonId == lastOpenedId;

    // 0. Late in the day with a live streak and nothing practiced yet: the
    // streak is the most time-sensitive thing on screen, so it goes first.
    if (streakAtRisk) {
      badgeText = l10n.nbaBadgeStreakRisk;
      title = l10n.nbaTitleStreakRisk;
      subtitle = l10n.nbaSubStreakRisk(streak);
      ctaText = l10n.nbaCtaDailyPractice;
      icon = Icons.local_fire_department_rounded;
      onTap = () {
        context.push(dailyPracticeRoute);
      };
    } else if (isResumingIncompleteLesson) {
      // 1. User left a lesson mid-way or couldn't complete it: resume directly.
      badgeText = l10n.resumeJourney;
      title = l10n.continueLearning;
      subtitle = l10n.readyToLearn;
      ctaText = l10n.continueButton;
      icon = Icons.play_arrow_rounded;
      onTap = () {
        context.push('/lesson/$lastOpenedId');
      };
    } else if (!hasAnyProgress && !hasCompletedAlphabet) {
      // 2. "Start here" is exclusively for true newcomers on their first visit.
      // Once the learner completes the alphabet (or has any progress), "Start here"
      // is permanently retired and will never appear again.
      badgeText = l10n.nbaBadgeStartHere;
      title = l10n.nbaTitleFirstLetters;
      subtitle = l10n.nbaSubFirstLetters;
      ctaText = l10n.nbaCtaBeginLesson;
      icon = Icons.menu_book_rounded;
      onTap = () {
        if (nextLessonId != null && nextLessonId!.isNotEmpty) {
          context.push('/lesson/$nextLessonId');
        } else {
          context.push('/letter/standalone/all');
        }
      };
    } else if (mistakeCount > 0) {
      // 3. User has quiz mistakes to review.
      badgeText = l10n.nbaBadgeMistakes;
      title = l10n.nbaTitleMistakes;
      subtitle = l10n.nbaSubMistakes(mistakeCount);
      ctaText = l10n.nbaCtaReviewMistakes;
      icon = Icons.psychology_rounded;
      onTap = () {
        context.push('/mistakes');
      };
    } else if (!hasCompletedAlphabet) {
      // 4. Returning learner mid-alphabet: frame as next step, never a stuck "start here".
      badgeText = l10n.nbaBadgeNextStep;
      title = l10n.nbaTitleFirstLetters;
      subtitle = l10n.nbaSubFirstLetters;
      ctaText = l10n.nbaCtaBeginLesson;
      icon = Icons.menu_book_rounded;
      onTap = () {
        if (nextLessonId != null && nextLessonId!.isNotEmpty) {
          context.push('/lesson/$nextLessonId');
        } else {
          context.push('/letter/standalone/all');
        }
      };
    } else if (streak > 0 &&
        !(ref.watch(lessonCompletedTodayProvider) ||
            ref.watch(quizTakenTodayProvider))) {
      // 5. Streak risk: nudge to keep the habit alive.
      badgeText = l10n.nbaBadgeStreakRisk;
      title = l10n.nbaTitleStreakRisk;
      subtitle = l10n.nbaSubStreakRisk(streak);
      ctaText = l10n.nbaCtaDailyPractice;
      icon = Icons.local_fire_department_rounded;
      onTap = () {
        context.push(dailyPracticeRoute);
      };
    } else if (nextLessonId != null && nextLessonId!.isNotEmpty) {
      // 6. Active learning progression: continue directly to next curriculum lesson.
      badgeText = l10n.resumeJourney;
      title = l10n.continueLearning;
      subtitle = l10n.readyToLearn;
      ctaText = l10n.continueButton;
      icon = Icons.play_arrow_rounded;
      onTap = () {
        context.push('/lesson/$nextLessonId');
      };
    } else if (!ref.watch(quizTakenTodayProvider)) {
      // 7. Curriculum finished, no practice yet today: daily practice is the
      // reason to open the app (content never runs out).
      badgeText = l10n.dailyPracticeBadge;
      title = l10n.nbaTitleDailyPractice;
      subtitle = l10n.nbaSubDailyPractice;
      ctaText = l10n.nbaCtaDailyPractice;
      icon = Icons.bolt_rounded;
      onTap = () {
        context.push(dailyPracticeRoute);
      };
    } else {
      // 8. Completed current catalogue and practiced today.
      badgeText = l10n.nbaBadgeAllDone;
      title = l10n.nbaTitleAllDone;
      subtitle = l10n.nbaSubAllDonePractice;
      ctaText = l10n.nbaCtaDailyPractice;
      icon = Icons.celebration_rounded;
      onTap = () {
        context.push(dailyPracticeRoute);
      };
    }

    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: isDark
            ? const LinearGradient(
                colors: [AppColors.emeraldTeal, AppColors.emeraldPine],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.28),
            blurRadius: 28,
            offset: const Offset(0, 14),
            spreadRadius: -12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  badgeText.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              height: 1.15,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 18),
          // One tappable for one action: a lone ElevatedButton carries the
          // button semantics itself. Wrapping it in another tappable would
          // announce two nested buttons for the same CTA to screen readers.
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.emeraldInk,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                shadowColor: Colors.transparent,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ctaText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15.5,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 19),
                ],
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
