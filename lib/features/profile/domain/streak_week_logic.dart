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
  static String dateKey(DateTime d) =>
      d.toIso8601String().substring(0, 10);
}
