// Honest streak: what Home shows is derived from the practice log at read
// time, never the stored counter alone. The stored `currentStreak` is only
// recomputed on practice writes, so after a missed day it would otherwise
// stay stale until the next practice silently drops it to 1.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/storage/hive_service.dart';
import '../../../profile/domain/entities/user_stats_entity.dart';
import '../../../profile/domain/streak_week_logic.dart';
import '../../../profile/presentation/providers/user_stats_provider.dart';
import 'mission_providers.dart';

/// Local clock for streak display decisions (at-risk hour). Test override.
final streakClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Hour of day (local) from which an unpracticed streak counts as at risk.
const int streakAtRiskHour = 17;

/// Streak the learner should see right now.
///
/// Uses [StreakWeekLogic.deriveStreak] over the practice-date log. The stored
/// counter is only trusted as a fallback when the learner was active today or
/// yesterday; an older `lastActiveDate` means the streak is over, so 0.
int deriveDisplayedStreak(UserStatsEntity stats, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final lastActive = DateTime.tryParse(stats.lastActiveDate);
  final lastActiveDay = lastActive == null
      ? null
      : DateTime(lastActive.year, lastActive.month, lastActive.day);
  final daysSinceActive = lastActiveDay == null
      ? null
      : today.difference(lastActiveDay).inDays;

  if (stats.practiceDates.isEmpty) {
    // No log: the counter is believable only for a recent lastActiveDate.
    if (daysSinceActive == null || daysSinceActive > 1) return 0;
    return stats.currentStreak;
  }

  final derived = StreakWeekLogic.deriveStreak(
    stats.practiceDates,
    asOf: today,
    lastActiveDate: stats.lastActiveDate,
    fallbackStreak: stats.currentStreak,
  );
  // deriveStreak keeps the fallback alive only for today/yesterday; a log
  // with no entry for either day yields 0 from the dates branch as well.
  return derived < 0 ? 0 : derived;
}

/// Streak shown on Home (0 while stats are loading).
final displayedStreakProvider = Provider<int>((ref) {
  final stats = ref.watch(userStatsProvider).valueOrNull;
  if (stats == null) return 0;
  return deriveDisplayedStreak(stats, ref.watch(streakClockProvider)());
});

/// Prefs key under which a lost streak is acknowledged once.
String streakLostAckKey(UserStatsEntity stats) =>
    'streak_lost_ack_${stats.currentStreak}_${stats.lastActiveDate}';

/// True once per lost streak: the stored counter still says > 0 but the
/// derived streak is 0, and the learner has not dismissed the notice yet.
final streakLostProvider = Provider<bool>((ref) {
  final stats = ref.watch(userStatsProvider).valueOrNull;
  if (stats == null || stats.currentStreak <= 0) return false;
  if (ref.watch(displayedStreakProvider) > 0) return false;
  final prefs = ref.watch(sharedPreferencesProvider);
  return !(prefs.getBool(streakLostAckKey(stats)) ?? false);
});

/// Dismisses the "streak reset" notice for this particular lost streak.
Future<void> acknowledgeStreakLost(
  SharedPreferences prefs,
  UserStatsEntity stats,
) => prefs.setBool(streakLostAckKey(stats), true);

/// Anything counted as practice today (lesson, quiz or bakhed).
final practicedTodayProvider = Provider<bool>((ref) {
  return ref.watch(lessonCompletedTodayProvider) ||
      ref.watch(quizTakenTodayProvider) ||
      ref.watch(bakhedListenedTodayProvider);
});

/// Streak alive, nothing practiced yet today, and the day is getting late.
final streakAtRiskProvider = Provider<bool>((ref) {
  if (ref.watch(displayedStreakProvider) <= 0) return false;
  if (ref.watch(practicedTodayProvider)) return false;
  return ref.watch(streakClockProvider)().hour >= streakAtRiskHour;
});
