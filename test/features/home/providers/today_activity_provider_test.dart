import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/home/presentation/providers/today_activity_provider.dart';
import 'package:itun/features/profile/presentation/providers/user_stats_provider.dart';
import 'package:itun/shared/providers/local_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final today = DateTime(2026, 11, 10, 18);

  Future<SharedPreferences> prefsWith([Map<String, Object> v = const {}]) {
    SharedPreferences.setMockInitialValues(v);
    return SharedPreferences.getInstance();
  }

  group('DailyMinutesLog', () {
    test('adds to today and reads it back', () async {
      final log = DailyMinutesLog(await prefsWith(), now: () => today);
      expect(log.today(), 0);
      expect(await log.add(5), 5);
      expect(await log.add(3), 8);
      expect(log.today(), 8);
      expect(log.forDay(DateTime(2026, 11, 9)), 0);
    });

    test('ignores non-positive minutes', () async {
      final log = DailyMinutesLog(await prefsWith(), now: () => today);
      expect(await log.add(0), 0);
      expect(await log.add(-4), 0);
    });

    test('prunes entries older than 30 days and junk keys', () async {
      final prefs = await prefsWith({
        'daily_minutes_2026-10-01': 9,
        'daily_minutes_2026-10-20': 4,
        'daily_minutes_garbage': 1,
        'unrelated': 2,
      });
      final log = DailyMinutesLog(prefs, now: () => today);
      await log.add(1);
      expect(prefs.getInt('daily_minutes_2026-10-01'), isNull);
      expect(prefs.getInt('daily_minutes_garbage'), isNull);
      expect(prefs.getInt('daily_minutes_2026-10-20'), 4);
      expect(prefs.getInt('unrelated'), 2);
    });
  });

  group('providers', () {
    Future<ProviderContainer> container([
      Map<String, Object> v = const {},
    ]) async {
      final prefs = await prefsWith(v);
      final c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          todayActivityClockProvider.overrideWithValue(() => today),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('progress and goal-met follow the daily goal', () async {
      final c = await container({
        'daily_goal_minutes': 10,
        'daily_minutes_2026-11-10': 4,
      });
      expect(c.read(todayMinutesProvider), 4);
      expect(c.read(dailyGoalProgressProvider), closeTo(0.4, 1e-9));
      expect(c.read(dailyGoalMetProvider), isFalse);

      await c.read(todayMinutesProvider.notifier).add(6);
      expect(c.read(todayMinutesProvider), 10);
      expect(c.read(dailyGoalProgressProvider), 1);
      expect(c.read(dailyGoalMetProvider), isTrue);
    });

    test('progress is capped at 1 and a zero goal counts as met', () async {
      final c = await container({
        'daily_goal_minutes': 5,
        'daily_minutes_2026-11-10': 50,
      });
      expect(c.read(dailyGoalProgressProvider), 1);
      c.read(dailyGoalMinutesProvider.notifier).state = 0;
      expect(c.read(dailyGoalProgressProvider), 1);
      expect(c.read(dailyGoalMetProvider), isTrue);
    });

    test('minutes published by the stats notifier land in the log', () async {
      final c = await container({'daily_goal_minutes': 10});
      c.listen(todayMinutesProvider, (_, _) {});
      expect(c.read(todayMinutesProvider), 0);

      c.read(learningMinutesRecordedProvider.notifier).state = (
        minutes: 5,
        seq: 1,
      );
      await Future<void>.delayed(Duration.zero);
      expect(c.read(todayMinutesProvider), 5);

      // Same amount again, new seq: still counted.
      c.read(learningMinutesRecordedProvider.notifier).state = (
        minutes: 5,
        seq: 2,
      );
      await Future<void>.delayed(Duration.zero);
      expect(c.read(todayMinutesProvider), 10);

      c.read(todayMinutesProvider.notifier).refresh();
      expect(c.read(todayMinutesProvider), 10);
    });
  });

  group('celebration flag', () {
    test('is per local day', () async {
      final prefs = await prefsWith();
      expect(dailyGoalCelebratedToday(prefs, now: today), isFalse);
      await markDailyGoalCelebrated(prefs, now: today);
      expect(dailyGoalCelebratedToday(prefs, now: today), isTrue);
      expect(
        dailyGoalCelebratedToday(
          prefs,
          now: today.add(const Duration(days: 1)),
        ),
        isFalse,
      );
    });
  });
}
