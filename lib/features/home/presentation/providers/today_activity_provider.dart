// Daily goal: minutes learned today against the goal picked in onboarding
// (`dailyGoalMinutesProvider`). Minutes come from a small per-day log in
// SharedPreferences that every learning-minute write also bumps.
//
// What counts as a minute: only minutes the app already records as real
// learning time — a lesson's `estimatedMinutes` on first completion (via
// `UserStatsNotifier.completeLesson` → `learningMinutesSinkProvider`) and
// any session (review, daily practice) that calls `DailyMinutesLog.add`
// with its measured elapsed minutes. Nothing is estimated here.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/storage/hive_service.dart';
import '../../../../shared/providers/local_settings_provider.dart';
import '../../../profile/presentation/providers/user_stats_provider.dart';

/// Local clock for "today". Test override.
final todayActivityClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Per-day learning minutes in prefs: `daily_minutes_<yyyy-MM-dd>` (local).
class DailyMinutesLog {
  DailyMinutesLog(this._prefs, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const String keyPrefix = 'daily_minutes_';
  static const int retentionDays = 30;

  final SharedPreferences _prefs;
  final DateTime Function() _now;

  static String dateKey(DateTime d) {
    final local = DateTime(d.year, d.month, d.day);
    return local.toIso8601String().substring(0, 10);
  }

  String get todayKey => dateKey(_now());

  /// Minutes logged on [day] (local date).
  int forDay(DateTime day) => _prefs.getInt('$keyPrefix${dateKey(day)}') ?? 0;

  int today() => _prefs.getInt('$keyPrefix$todayKey') ?? 0;

  /// Adds [minutes] to today and prunes entries older than [retentionDays].
  Future<int> add(int minutes) async {
    if (minutes <= 0) return today();
    final key = '$keyPrefix$todayKey';
    final total = (_prefs.getInt(key) ?? 0) + minutes;
    await _prefs.setInt(key, total);
    await prune();
    return total;
  }

  /// Removes log entries older than [retentionDays] (also unparsable keys).
  Future<void> prune() async {
    final cutoff = DateTime(
      _now().year,
      _now().month,
      _now().day,
    ).subtract(const Duration(days: retentionDays));
    for (final key in _prefs.getKeys().toList()) {
      if (!key.startsWith(keyPrefix)) continue;
      final parsed = DateTime.tryParse(key.substring(keyPrefix.length));
      if (parsed == null || parsed.isBefore(cutoff)) {
        await _prefs.remove(key);
      }
    }
  }
}

final dailyMinutesLogProvider = Provider<DailyMinutesLog>((ref) {
  return DailyMinutesLog(
    ref.watch(sharedPreferencesProvider),
    now: ref.watch(todayActivityClockProvider),
  );
});

/// Today's learned minutes. Re-read with [refreshTodayMinutes] after a write.
final todayMinutesProvider = NotifierProvider<TodayMinutesNotifier, int>(
  TodayMinutesNotifier.new,
);

class TodayMinutesNotifier extends Notifier<int> {
  @override
  int build() {
    // Minutes recorded through the stats notifier (lesson completion) land
    // here as well; `seq` makes equal consecutive amounts still notify.
    ref.listen<LearningMinutesRecord>(learningMinutesRecordedProvider, (
      previous,
      next,
    ) {
      if (next.minutes > 0 && next.seq != (previous?.seq ?? 0)) {
        add(next.minutes);
      }
    });
    return ref.watch(dailyMinutesLogProvider).today();
  }

  /// Adds measured minutes (review / daily practice sessions call this).
  Future<void> add(int minutes) async {
    state = await ref.read(dailyMinutesLogProvider).add(minutes);
  }

  void refresh() => state = ref.read(dailyMinutesLogProvider).today();
}

/// 0..1 progress towards the daily goal.
final dailyGoalProgressProvider = Provider<double>((ref) {
  final goal = ref.watch(dailyGoalMinutesProvider);
  if (goal <= 0) return 1;
  final minutes = ref.watch(todayMinutesProvider);
  return (minutes / goal).clamp(0, 1).toDouble();
});

final dailyGoalMetProvider = Provider<bool>((ref) {
  final goal = ref.watch(dailyGoalMinutesProvider);
  return goal <= 0 || ref.watch(todayMinutesProvider) >= goal;
});

const String _goalCelebratedKey = 'daily_goal_celebrated_date';

/// True when the goal-met celebration already ran today.
bool dailyGoalCelebratedToday(SharedPreferences prefs, {DateTime? now}) =>
    prefs.getString(_goalCelebratedKey) ==
    DailyMinutesLog.dateKey(now ?? DateTime.now());

Future<void> markDailyGoalCelebrated(
  SharedPreferences prefs, {
  DateTime? now,
}) => prefs.setString(
  _goalCelebratedKey,
  DailyMinutesLog.dateKey(now ?? DateTime.now()),
);
