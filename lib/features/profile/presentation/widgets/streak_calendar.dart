// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/local_settings_provider.dart';
import '../../domain/entities/user_stats_entity.dart';
import '../../domain/streak_week_logic.dart';

class StreakCalendar extends ConsumerWidget {
  final UserStatsEntity stats;

  const StreakCalendar({super.key, required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceEffects = ref.watch(reduceVisualEffectsProvider);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final week = StreakWeekLogic.calendarWeek(today);
    final activeCount = StreakWeekLogic.activeCountInWeek(stats, week);
    final headerState = StreakWeekLogic.headerState(
      streak: stats.currentStreak,
      activeCount: activeCount,
    );
    final isActive = headerState == StreakHeaderState.active;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder.withValues(alpha: 0.5)
              : AppColors.lightBorder.withValues(alpha: 0.7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.duoOrange.withValues(alpha: 0.15)
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04)),
                  shape: BoxShape.circle,
                ),
                child: isActive
                    ? const Icon(
                        Icons.local_fire_department_rounded,
                        color: AppColors.duoOrange,
                        size: 20,
                      ).animate(
                        onPlay: reduceEffects ? null : (c) => c.repeat(),
                      ).shimmer(duration: 2000.ms, color: Colors.white)
                    : Icon(
                        Icons.local_fire_department_outlined,
                        color: isDark ? Colors.white38 : Colors.black38,
                        size: 20,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      // Honest state machine: never claim "Active" at zero.
                      isActive ? 'Weekly Streak Active' : 'Start Your Streak',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isActive
                          ? 'Keep learning to grow your flame!'
                          : 'Complete any activity to light your flame!',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        // Bumped from black38/white38 for WCAG AA contrast.
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _StreakBadge(count: stats.currentStreak, isDark: isDark),
            ],
          ),

          const SizedBox(height: 20),

          // Calendar week strip: Monday-anchored, today ringed, future days
          // dimmed. Every column uses a single-letter label so nothing wraps.
          Semantics(
            label:
                'This week: practiced $activeCount of ${_daysElapsed(week, today)} days',
            child: Row(
              children: List.generate(7, (index) {
                final day = week[index];
                final isFuture = day.isAfter(today);
                final isToday = day == today;
                final isActiveDay = !isFuture && StreakWeekLogic.isDayActive(stats, day);

                return Expanded(
                  child: Semantics(
                    label:
                        '${_fullDayName(day.weekday)}, ${_monthDay(day)}'
                        '${isFuture ? ', upcoming' : isActiveDay ? ', practiced' : ', not practiced'}',
                    button: false,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isActiveDay
                            ? AppColors.duoOrange.withValues(
                                alpha: isDark ? 0.12 : 0.08,
                              )
                            : (isToday && !isFuture
                                  ? (isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.black.withValues(alpha: 0.03))
                                  : Colors.transparent),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActiveDay
                              ? AppColors.duoOrange.withValues(alpha: 0.4)
                              : (isToday && !isFuture
                                    ? (isDark
                                          ? Colors.white30
                                          : Colors.black12)
                                    : Colors.transparent),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _weekdayLetter(day.weekday),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10.5,
                              fontWeight:
                                  isToday ? FontWeight.w800 : FontWeight.w600,
                              color: _labelColor(
                                isDark: isDark,
                                isActive: isActiveDay,
                                isToday: isToday,
                                isFuture: isFuture,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActiveDay
                                  ? Colors.transparent
                                  : (isFuture
                                        ? Colors.transparent
                                        : (isDark
                                              ? const Color(0xFF1E1E1E)
                                              : const Color(0xFFF1F3F5))),
                              border: Border.all(
                                color: isActiveDay
                                    ? Colors.transparent
                                    : (isToday && !isFuture
                                          ? AppColors.primary.withValues(
                                              alpha: 0.5,
                                            )
                                          : Colors.transparent),
                                width: 1.5,
                              ),
                              boxShadow: isActiveDay
                                  ? [
                                      BoxShadow(
                                        color: AppColors.duoOrange.withValues(
                                          alpha: 0.35,
                                        ),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: isActiveDay
                                  ? const Icon(
                                      Icons.local_fire_department_rounded,
                                      color: AppColors.duoOrange,
                                      size: 20,
                                    ).animate(
                                      onPlay: reduceEffects
                                          ? null
                                          : (c) => c.repeat(),
                                    ).scale(
                                      duration: 1000.ms,
                                      begin: const Offset(0.9, 0.9),
                                      end: const Offset(1.1, 1.1),
                                      curve: Curves.easeInOut,
                                    ).then().scale(
                                      duration: 1000.ms,
                                      begin: const Offset(1.1, 1.1),
                                      end: const Offset(0.9, 0.9),
                                      curve: Curves.easeInOut,
                                    )
                                  : Text(
                                      '${day.day}',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 11,
                                        fontWeight: isToday
                                            ? FontWeight.w800
                                            : FontWeight.w700,
                                        color: isFuture
                                            ? (isDark
                                                  ? Colors.white24
                                                  : Colors.black26)
                                            : (isToday
                                                  ? (isDark
                                                        ? Colors.white
                                                        : Colors.black87)
                                                  : (isDark
                                                        ? Colors.white24
                                                        : Colors.black26)),
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.stars_rounded,
                  color: AppColors.duoYellow,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    isActive
                        ? 'You practiced $activeCount of ${_daysElapsed(week, today)} days this week. Keep it up!'
                        : 'No practice yet this week — pick any activity to begin!',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 450.ms)
        .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic);
  }

  int _daysElapsed(List<DateTime> week, DateTime today) {
    return week.where((d) => !d.isAfter(today)).length;
  }

  Color _labelColor({
    required bool isDark,
    required bool isActive,
    required bool isToday,
    required bool isFuture,
  }) {
    if (isActive) return AppColors.duoOrange;
    if (isFuture) return isDark ? Colors.white24 : Colors.black26;
    if (isToday) return isDark ? Colors.white : Colors.black87;
    return isDark ? Colors.white54 : Colors.black45;
  }

  String _weekdayLetter(int weekday) {
    // Single letters keep all seven columns visually identical; "today" is
    // communicated by the ring + bold weight instead of a longer word that
    // would wrap on narrow screens.
    return ['M', 'T', 'W', 'T', 'F', 'S', 'S'][weekday - 1];
  }

  String _fullDayName(int weekday) {
    return [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ][weekday - 1];
  }

  String _monthDay(DateTime d) {
    return 'August ${d.day}'.replaceFirst('August', _monthName(d.month));
  }

  String _monthName(int m) {
    return [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ][m - 1];
  }
}

/// Gradient pill when streaking; quiet neutral chip at zero so an empty
/// streak never reads as an achievement.
class _StreakBadge extends StatelessWidget {
  final int count;
  final bool isDark;

  const _StreakBadge({required this.count, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final active = count > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: active
            ? const LinearGradient(
                colors: [AppColors.duoOrange, AppColors.duoYellow],
              )
            : null,
        color: active ? null : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppColors.duoOrange.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (active) ...[
            const Icon(Icons.bolt_rounded, color: Colors.white, size: 14),
            const SizedBox(width: 4),
          ],
          Text(
            '$count DAYS',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: active
                  ? Colors.white
                  : (isDark ? Colors.white54 : Colors.black45),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
