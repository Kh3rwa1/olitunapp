import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/minimum_tap_target.dart';
import '../../../../shared/providers/providers.dart';
import '../../../quiz/presentation/providers/mistake_provider.dart';
import '../providers/mission_providers.dart';

class NextBestActionCard extends ConsumerWidget {
  const NextBestActionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Watch statistics and learning status
    final statsAsync = ref.watch(userStatsProvider);
    final mistakes = ref.watch(mistakeProvider);

    final isAuthAsync = ref.watch(isAuthenticatedProvider);
    final isGuest = isAuthAsync.value == false;
    final stats = statsAsync.value;
    final streak = stats?.currentStreak ?? 0;

    // Determine the state and copy
    String badgeText = '';
    String title = '';
    String subtitle = '';
    String ctaText = '';
    VoidCallback onTap = () {};
    IconData icon = Icons.star_rounded;
    Color color = AppColors.primary;

    final hasCompletedAlphabet = (stats?.completedLessons.any((id) => id.contains('alphabet')) ?? false) ||
        (stats?.practicedLetters.isNotEmpty ?? false);
    final hasCompletedNumbers = stats?.completedLessons.any((id) => id.contains('number')) ?? false;
    final showStartHere = !hasCompletedAlphabet || !hasCompletedNumbers;

    if (isGuest || showStartHere) {
      badgeText = 'START HERE';
      title = 'Learn your first Ol Chiki letters';
      subtitle = 'Begin with the basic alphabet and unlock Santali writing.';
      ctaText = 'Begin Lesson';
      icon = Icons.menu_book_rounded;
      color = AppColors.primary;
      onTap = () {
        if (!hasCompletedAlphabet && hasCompletedNumbers) {
          context.push('/letter/standalone/all');
        } else if (hasCompletedAlphabet && !hasCompletedNumbers) {
          context.push('/number/standalone/all');
        } else {
          final route = (DateTime.now().millisecondsSinceEpoch % 2 == 0)
              ? '/letter/standalone/all'
              : '/number/standalone/all';
          context.push(route);
        }
      };
    } else if (mistakes.isNotEmpty) {
      badgeText = 'PRACTICE NEEDED';
      title = 'Transform mistakes into wisdom';
      subtitle =
          'You have ${mistakes.length} question${mistakes.length > 1 ? "s" : ""} to review and master.';
      ctaText = 'Review Mistakes';
      icon = Icons.psychology_rounded;
      color = AppColors.duoOrange;
      onTap = () {
        context.push('/mistakes');
      };
    } else if (streak > 0 &&
        !(ref.watch(lessonCompletedTodayProvider) ||
            ref.watch(quizTakenTodayProvider))) {
      badgeText = 'STREAK RISK';
      title = 'Keep your daily momentum';
      subtitle =
          'One quick quiz or lesson will secure your $streak day streak today.';
      ctaText = 'Quick Review';
      icon = Icons.local_fire_department_rounded;
      color = AppColors.duoOrange;
      onTap = () {
        context.push('/quizzes');
      };
    } else if (!ref.watch(bakhedListenedTodayProvider)) {
      badgeText = 'TRY BAKHED';
      title = 'Listen to a cultural rhyme';
      subtitle = 'Immerse yourself in beautiful Santali oral poetry for 30s.';
      ctaText = 'Listen Now';
      icon = Icons.music_note_rounded;
      color = AppColors.duoBlue;
      onTap = () {
        context.push('/bakhed');
      };
    } else {
      // Default: Active learning
      badgeText = 'CONTINUE LEARNING';
      title = 'Next step in your journey';
      subtitle = 'Consistent daily practice creates strong roots. Keep going!';
      ctaText = 'Continue';
      icon = Icons.play_arrow_rounded;
      color = AppColors.primary;
      onTap = () {
        context.push('/categories');
      };
    }

    return Container(
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
              Container(
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
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: color,
                  ),
                ),
              ),
              Icon(icon, color: color, size: 24),
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
                  foregroundColor: Colors.white,
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
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
