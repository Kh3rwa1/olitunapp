import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/theme/app_colors.dart';
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

    final lessons = stats?.completedLessons;
    final hasAnyProgress =
        (lessons?.isNotEmpty ?? false) ||
        streak > 0 ||
        (stats?.totalStars ?? 0) > 0;
    final completedAlphabet =
        lessons != null && lessons.any((id) => id.contains('alphabet'));
    final hasCompletedAlphabet =
        (stats?.alphabetProgress ?? 0) >= 1 || completedAlphabet;

    final completedNumbers =
        lessons != null && lessons.any((id) => id.contains('number'));
    final hasCompletedNumbers =
        (stats?.numbersProgress ?? 0) >= 1 || completedNumbers;

    // "Start here" is only for true newcomers. Returning learners with
    // progress elsewhere (streak, stars, other lessons) get the honest
    // "next step" framing instead of a permanently stuck start card.
    if (!hasAnyProgress && (isGuest || !hasCompletedAlphabet)) {
      badgeText = l10n.nbaBadgeStartHere;
      title = l10n.nbaTitleFirstLetters;
      subtitle = l10n.nbaSubFirstLetters;
      ctaText = l10n.nbaCtaBeginLesson;
      icon = Icons.menu_book_rounded;
      onTap = () {
        context.push('/letter/standalone/all');
      };
    } else if (!hasCompletedAlphabet) {
      badgeText = l10n.nbaBadgeNextStep;
      title = l10n.nbaTitleFirstLetters;
      subtitle = l10n.nbaSubFirstLetters;
      ctaText = l10n.nbaCtaBeginLesson;
      icon = Icons.menu_book_rounded;
      onTap = () {
        context.push('/letter/standalone/all');
      };
    } else if (!hasCompletedNumbers) {
      badgeText = l10n.nbaBadgeNextStep;
      title = l10n.nbaTitleNumbers;
      subtitle = l10n.nbaSubNumbers;
      ctaText = l10n.nbaCtaPracticeNumbers;
      icon = Icons.pin_rounded;
      onTap = () {
        context.push('/number/standalone/all');
      };
    } else if (mistakes.isNotEmpty) {
      badgeText = l10n.nbaBadgeMistakes;
      title = l10n.nbaTitleMistakes;
      subtitle = l10n.nbaSubMistakes(mistakes.length);
      ctaText = l10n.nbaCtaReviewMistakes;
      icon = Icons.psychology_rounded;
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
      onTap = () {
        context.push('/quizzes');
      };
    } else if (!ref.watch(bakhedListenedTodayProvider)) {
      badgeText = l10n.nbaBadgeTryBakhed;
      title = l10n.nbaTitleTryBakhed;
      subtitle = l10n.nbaSubTryBakhed;
      ctaText = l10n.nbaCtaListenNow;
      icon = Icons.music_note_rounded;
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF0E9F6E), Color(0xFF0B3B24)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFF1EE088), Color(0xFF00C767)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.3 : 0.35),
            blurRadius: 32,
            offset: const Offset(0, 16),
            spreadRadius: -12,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: -10,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Giant watermark glyph
          Positioned(
            right: -12,
            bottom: -24,
            child: IgnorePointer(
              child: Text(
                'ᱚᱞ',
                style: TextStyle(
                  fontFamily: 'OlChiki',
                  fontSize: 120,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Text(
                        badgeText.toUpperCase(),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.3,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: BreathingPulse(
                      maxScale: 1.1,
                      period: const Duration(milliseconds: 2600),
                      child: Icon(icon, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.15,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Color(0x40000000),
                      offset: Offset(0, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.88),
                ),
              ),
              const SizedBox(height: 20),
              // One tappable for one action: a lone ElevatedButton carries the
              // button semantics itself. Wrapping it in another tappable would
              // announce two nested buttons for the same CTA to screen readers.
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF03543F),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
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
                      const Icon(Icons.arrow_forward_rounded, size: 19)
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
            ],
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
