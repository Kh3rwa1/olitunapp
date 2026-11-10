import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/home/presentation/providers/displayed_streak_provider.dart';
import 'package:itun/features/home/presentation/providers/today_activity_provider.dart';
import 'package:itun/features/home/presentation/widgets/today_strip.dart';
import 'package:itun/features/profile/presentation/providers/profile_providers.dart';
import 'package:itun/features/review/data/review_store_notifier.dart';
import 'package:itun/shared/providers/local_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'habit_test_support.dart';

void main() {
  final now = DateTime(2026, 11, 10, 18);

  Future<(SharedPreferences, RecordingAnalyticsService)> prefsWith(
    Map<String, Object> values,
  ) async {
    SharedPreferences.setMockInitialValues(values);
    final prefs = await SharedPreferences.getInstance();
    return (prefs, RecordingAnalyticsService(prefs));
  }

  testWidgets('shows honest streak, goal progress and due reviews', (
    tester,
  ) async {
    final (prefs, _) = await prefsWith({
      '${DailyMinutesLog.keyPrefix}${dateKey(now)}': 3,
    });
    final yesterday = now.subtract(const Duration(days: 1));
    final stats = statsWith(
      streak: 4,
      lastActiveDate: dateKey(yesterday),
      practiceDates: {
        for (var i = 1; i <= 4; i++) dateKey(now.subtract(Duration(days: i))),
      },
    );
    await tester.pumpWidget(
      routerHost(
        child: const TodayStrip(),
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          userStatsProvider.overrideWith(() => FixedStatsNotifier(stats)),
          streakClockProvider.overrideWithValue(() => now),
          todayActivityClockProvider.overrideWithValue(() => now),
          dailyGoalMinutesProvider.overrideWith((ref) => 5),
          dueReviewCountProvider.overrideWithValue(2),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('4 day streak'), findsOneWidget);
    expect(find.text('3 / 5 min'), findsOneWidget);
    expect(find.text('2 due'), findsOneWidget);
  });

  testWidgets('a stale stored streak shows as "start a streak", never fake', (
    tester,
  ) async {
    final (prefs, _) = await prefsWith({});
    final stats = statsWith(
      streak: 9,
      lastActiveDate: dateKey(now.subtract(const Duration(days: 4))),
      practiceDates: {dateKey(now.subtract(const Duration(days: 4)))},
    );
    await tester.pumpWidget(
      routerHost(
        child: const TodayStrip(),
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          userStatsProvider.overrideWith(() => FixedStatsNotifier(stats)),
          streakClockProvider.overrideWithValue(() => now),
          todayActivityClockProvider.overrideWithValue(() => now),
          dailyGoalMinutesProvider.overrideWith((ref) => 5),
          dueReviewCountProvider.overrideWithValue(0),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Start a streak today'), findsOneWidget);
    expect(find.textContaining('9 day'), findsNothing);
    expect(find.textContaining('due'), findsNothing);
  });

  testWidgets('goal met shows the done label and tap opens progress', (
    tester,
  ) async {
    final (prefs, _) = await prefsWith({
      '${DailyMinutesLog.keyPrefix}${dateKey(now)}': 7,
    });
    await tester.pumpWidget(
      routerHost(
        child: const TodayStrip(),
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          userStatsProvider.overrideWith(() => FixedStatsNotifier(statsWith())),
          streakClockProvider.overrideWithValue(() => now),
          todayActivityClockProvider.overrideWithValue(() => now),
          dailyGoalMinutesProvider.overrideWith((ref) => 5),
          dueReviewCountProvider.overrideWithValue(0),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Goal done'), findsOneWidget);
    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();
    expect(find.text('profile-placeholder'), findsOneWidget);
  });
}
