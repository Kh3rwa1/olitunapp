import 'dart:math' as math;

import 'entities/user_stats_entity.dart';

/// How the streak header should present itself.
enum StreakHeaderState { active, idle }

/// Pure helpers behind the profile streak calendar.
///
/// Kept free of Flutter imports so the week anchoring, activity resolution
/// and state machine are unit-testable in isolation.
class StreakWeekLogic {
  StreakWeekLogic._();

  /// Returns the calendar week (Monday-anchored) containing [today],
  /// exactly 7 entries from Monday to Sunday. Days after [today] are
  /// future days of the current week.
  static List<DateTime> calendarWeek(DateTime today) {
    final day = DateTime(today.year, today.month, today.day);
    final monday = day.subtract(Duration(days: day.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  /// Whether the learner was active on [day].
  ///
  /// Sources, in order of reliability:
  /// 1. [UserStatsEntity.practiceDates] — every practice/lesson/typing
  ///    session records its local date here.
  /// 2. [UserStatsEntity.quizHistory] — quiz completions carry timestamps.
  /// 3. [UserStatsEntity.lastActiveDate] — fallback for "today" when a
  ///    positive streak confirms activity.
  static bool isDayActive(UserStatsEntity stats, DateTime day) {
    final key = dateKey(day);
    if (stats.practiceDates.contains(key)) return true;

    for (final result in stats.quizHistory.values) {
      final completed = DateTime.tryParse(result.completedAt)?.toLocal();
      if (completed != null && dateKey(completed) == key) return true;
    }

    return stats.lastActiveDate == key && stats.currentStreak > 0;
  }

  /// Number of active days within [days].
  static int activeCountInWeek(UserStatsEntity stats, List<DateTime> days) {
    return days.where((d) => isDayActive(stats, d)).length;
  }

  /// Header presentation state: celebrate only when there is something
  /// real to celebrate.
  static StreakHeaderState headerState({
    required int streak,
    required int activeCount,
  }) {
    if (streak > 0 || activeCount > 0) return StreakHeaderState.active;
    return StreakHeaderState.idle;
  }

  /// Local-date key (`yyyy-MM-dd`) used across stats fields.
  static String dateKey(DateTime d) => d.toIso8601String().substring(0, 10);

  /// Derives the current active streak dynamically from consecutive dates in [practiceDates]
  /// while preserving continuity when advancing from a prior streak.
  ///
  /// A streak is active if the learner completed practice activity today OR yesterday
  /// (in which case today is still available to extend the streak).
  /// Consecutive preceding days in [practiceDates] are counted backwards.
  /// If neither today nor yesterday has a practice entry, the streak is broken (0).
  static int deriveStreak(
    Set<String> practiceDates, {
    DateTime? asOf,
    String? lastActiveDate,
    int fallbackStreak = 0,
  }) {
    final now = asOf ?? DateTime.now();
    final todayKey = dateKey(now);
    final yesterdayKey = dateKey(now.subtract(const Duration(days: 1)));

    // 1. Calculate consecutive days from practiceDates
    int streakFromDates = 0;
    if (practiceDates.isNotEmpty) {
      DateTime? cursor;
      if (practiceDates.contains(todayKey)) {
        cursor = DateTime(now.year, now.month, now.day);
      } else if (practiceDates.contains(yesterdayKey)) {
        final yesterday = now.subtract(const Duration(days: 1));
        cursor = DateTime(yesterday.year, yesterday.month, yesterday.day);
      }

      if (cursor != null) {
        while (practiceDates.contains(dateKey(cursor!))) {
          streakFromDates++;
          cursor = cursor.subtract(const Duration(days: 1));
        }
      }
    }

    // 2. Evaluate prior/fallback streak continuity
    int streakFromPrior = 0;
    if (lastActiveDate != null &&
        lastActiveDate.isNotEmpty &&
        fallbackStreak > 0) {
      final parsedLastDay = DateTime.tryParse(lastActiveDate);
      if (parsedLastDay != null) {
        final lastDay = DateTime(
          parsedLastDay.year,
          parsedLastDay.month,
          parsedLastDay.day,
        );
        final today = DateTime(now.year, now.month, now.day);
        final diff = today.difference(lastDay).inDays;
        if (diff == 0) {
          streakFromPrior = fallbackStreak;
        } else if (diff == 1 && practiceDates.contains(todayKey)) {
          // Practiced today and last active was yesterday: advance streak
          streakFromPrior = fallbackStreak + 1;
        } else if (diff == 1) {
          // Last active yesterday, haven't practiced today yet: streak still alive
          streakFromPrior = fallbackStreak;
        }
      }
    }

    if (practiceDates.isEmpty) {
      return fallbackStreak;
    }

    return math.max<int>(streakFromDates, streakFromPrior);
  }
}
