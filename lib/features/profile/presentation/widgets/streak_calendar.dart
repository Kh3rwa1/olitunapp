import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/local_settings_provider.dart';
import '../../domain/entities/user_stats_entity.dart';

class StreakCalendar extends ConsumerWidget {
  final UserStatsEntity stats;

  const StreakCalendar({super.key, required this.stats});

  /// Checks if a given date was active based on quiz history or last active date.
  bool _isDayActive(DateTime day) {
    final targetStr = _formatDateKey(day);

    // 1. Explicitly check last active date
    if (stats.lastActiveDate == targetStr) {
      return stats.currentStreak > 0;
    }

    // 2. Check if a quiz was completed on this day
    for (final result in stats.quizHistory.values) {
      final completedDate = DateTime.tryParse(result.completedAt)?.toLocal();
      if (completedDate != null) {
        final compStr = _formatDateKey(completedDate);
        if (compStr == targetStr) {
          return true;
        }
      }
    }

    return false;
  }

  String _formatDateKey(DateTime date) {
    return date.toIso8601String().substring(0, 10);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceEffects = ref.watch(reduceVisualEffectsProvider);

    // Generate past 7 days ending with today
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last7Days = List.generate(7, (i) {
      return today.subtract(Duration(days: 6 - i));
    });

    final activeCount = last7Days.where(_isDayActive).length;

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
              // Header Row
              Row(
                children: [
                  Flexible(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.duoOrange.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child:
                              const Icon(
                                    Icons.local_fire_department_rounded,
                                    color: AppColors.duoOrange,
                                    size: 20,
                                  )
                                  .animate(
                                    onPlay: reduceEffects
                                        ? null
                                        : (c) => c.repeat(),
                                  )
                                  .shimmer(
                                    duration: 2000.ms,
                                    color: Colors.white,
                                  ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Weekly Streak Active',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Keep learning to grow your flame!',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Streak badge pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.duoOrange, AppColors.duoYellow],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.duoOrange.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${stats.currentStreak} DAYS',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Horizontal grid strip of the past 7 days
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  final day = last7Days[index];
                  final isActive = _isDayActive(day);
                  final isToday =
                      day.year == today.year &&
                      day.month == today.month &&
                      day.day == today.day;

                  final dayName = index == 6
                      ? 'Today'
                      : _getShortDayName(day.weekday);
                  final dayNum = day.day.toString();

                  return Expanded(
                    child: PressableScale(
                      scale: 0.9,
                      onTap: () {
                        // Tap gives feedback and shows message
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.duoOrange.withValues(
                                  alpha: isDark ? 0.12 : 0.08,
                                )
                              : (isToday
                                    ? (isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.black.withValues(
                                              alpha: 0.03,
                                            ))
                                    : Colors.transparent),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isActive
                                ? AppColors.duoOrange.withValues(alpha: 0.4)
                                : (isToday
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
                              dayName,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: isToday
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isActive
                                    ? AppColors.duoOrange
                                    : (isToday
                                          ? (isDark
                                                ? Colors.white
                                                : Colors.black87)
                                          : (isDark
                                                ? Colors.white38
                                                : Colors.black38)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Inner visual element
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive
                                    ? Colors.transparent
                                    : (isDark
                                          ? const Color(0xFF1E1E1E)
                                          : const Color(0xFFF1F3F5)),
                                border: Border.all(
                                  color: isActive
                                      ? Colors.transparent
                                      : (isToday
                                            ? AppColors.primary.withValues(
                                                alpha: 0.5,
                                              )
                                            : Colors.transparent),
                                  width: 1.5,
                                ),
                                boxShadow: isActive
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
                                child: isActive
                                    ? const Icon(
                                            Icons.local_fire_department_rounded,
                                            color: AppColors.duoOrange,
                                            size: 20,
                                          )
                                          .animate(
                                            onPlay: reduceEffects
                                                ? null
                                                : (c) => c.repeat(),
                                          )
                                          .scale(
                                            duration: 1000.ms,
                                            begin: const Offset(0.9, 0.9),
                                            end: const Offset(1.1, 1.1),
                                            curve: Curves.easeInOut,
                                          )
                                          .then()
                                          .scale(
                                            duration: 1000.ms,
                                            begin: const Offset(1.1, 1.1),
                                            end: const Offset(0.9, 0.9),
                                            curve: Curves.easeInOut,
                                          )
                                    : Text(
                                        dayNum,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 11,
                                          fontWeight: isToday
                                              ? FontWeight.w800
                                              : FontWeight.w700,
                                          color: isToday
                                              ? (isDark
                                                    ? Colors.white
                                                    : Colors.black87)
                                              : (isDark
                                                    ? Colors.white24
                                                    : Colors.black26),
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

              const SizedBox(height: 16),
              // Footer quick status text
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
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
                        'You practiced $activeCount of the last 7 days. Keep the momentum!',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  String _getShortDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'M';
      case DateTime.tuesday:
        return 'T';
      case DateTime.wednesday:
        return 'W';
      case DateTime.thursday:
        return 'T';
      case DateTime.friday:
        return 'F';
      case DateTime.saturday:
        return 'S';
      case DateTime.sunday:
        return 'S';
      default:
        return '';
    }
  }
}
