// The one-glance reason to come back today: honest streak, daily-goal ring
// and due reviews, right under the greeting. Every number is derived from
// real learner state (see displayed_streak_provider / today_activity_provider);
// a streak of 0 says so instead of showing a stale counter.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/providers/local_settings_provider.dart';
import '../../../review/data/review_store_notifier.dart';
import '../providers/displayed_streak_provider.dart';
import '../providers/today_activity_provider.dart';

class TodayStrip extends ConsumerWidget {
  const TodayStrip({super.key, this.onTap});

  /// Defaults to opening the progress tab.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final streak = ref.watch(displayedStreakProvider);
    final minutes = ref.watch(todayMinutesProvider);
    final goal = ref.watch(dailyGoalMinutesProvider);
    final progress = ref.watch(dailyGoalProgressProvider);
    final goalMet = ref.watch(dailyGoalMetProvider);
    final due = ref.watch(dueReviewCountProvider);

    final ink = isDark ? Colors.white : AppColors.webInk;
    final muted = isDark ? Colors.white60 : AppColors.webSlate;
    final streakColor = streak > 0 ? AppColors.amberEmber : muted;

    return Semantics(
      button: true,
      label: l10n.todayStripSemantics(streak, minutes, goal, due),
      child: InkWell(
        onTap: onTap ?? () => context.push('/profile'),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            // Flat surface, no border: the strip is information, not a card
            // competing with the action cards below it.
            color: isDark
                ? AppColors.darkSurfaceElevated
                : AppColors.lightSurfaceVariant,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.local_fire_department_rounded,
                  color: streakColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 8),
              // FittedBox(scaleDown) instead of an ellipsis: "1 day str…"
              // is worse than a slightly smaller label on narrow phones.
              Expanded(
                child: ExcludeSemantics(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        streak > 0
                            ? l10n.todayStripStreak(streak)
                            : l10n.todayStripStartStreak,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (due > 0) ...[
                ExcludeSemantics(
                  child: _Pill(
                    icon: Icons.replay_rounded,
                    label: l10n.todayStripReviewsDue(due),
                    color: AppColors.primary,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              ExcludeSemantics(
                child: _GoalRing(
                  progress: progress,
                  label: goalMet
                      ? l10n.todayStripGoalDone
                      : l10n.todayStripGoal(minutes, goal),
                  met: goalMet,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalRing extends StatelessWidget {
  const _GoalRing({
    required this.progress,
    required this.label,
    required this.met,
    required this.isDark,
  });

  final double progress;
  final String label;
  final bool met;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = met ? AppColors.primary : AppColors.emeraldDeep;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 26,
          height: 26,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 3.5,
                strokeCap: StrokeCap.round,
                color: color,
                backgroundColor: color.withValues(alpha: isDark ? 0.22 : 0.14),
              ),
              if (met)
                Icon(Icons.check_rounded, size: 14, color: color)
              else
                Icon(Icons.timer_outlined, size: 13, color: color),
            ],
          ),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : AppColors.webSlate,
          ),
        ),
      ],
    );
  }
}
