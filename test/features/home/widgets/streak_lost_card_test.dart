import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/analytics/analytics_service.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/home/presentation/providers/displayed_streak_provider.dart';
import 'package:itun/features/home/presentation/widgets/streak_lost_card.dart';
import 'package:itun/features/profile/presentation/providers/profile_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'habit_test_support.dart';

void main() {
  final now = DateTime(2026, 11, 10, 9);

  testWidgets('shows once for a lost streak, logs, dismisses for good', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final analytics = RecordingAnalyticsService(prefs);
    final stats = statsWith(
      streak: 6,
      lastActiveDate: dateKey(now.subtract(const Duration(days: 3))),
      practiceDates: {dateKey(now.subtract(const Duration(days: 3)))},
    );
    await tester.pumpWidget(
      routerHost(
        child: const StreakLostCard(),
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          learningAnalyticsServiceProvider.overrideWithValue(analytics),
          userStatsProvider.overrideWith(() => FixedStatsNotifier(stats)),
          streakClockProvider.overrideWithValue(() => now),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your 6-day streak reset'), findsOneWidget);
    expect(analytics.names, [LearningAnalyticsEvents.streakLostSeen]);
    expect(analytics.events.single.meta['lostStreak'], 6);

    await tester.tap(find.byTooltip('Dismiss'));
    await tester.pumpAndSettle();

    expect(find.text('Your 6-day streak reset'), findsNothing);
    expect(prefs.getBool(streakLostAckKey(stats)), isTrue);
    // Logged once, not again on rebuild.
    expect(analytics.names.length, 1);
  });

  testWidgets('start again dismisses and opens daily practice', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final stats = statsWith(
      streak: 2,
      lastActiveDate: dateKey(now.subtract(const Duration(days: 5))),
      practiceDates: {dateKey(now.subtract(const Duration(days: 5)))},
    );
    await tester.pumpWidget(
      routerHost(
        child: const StreakLostCard(),
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          learningAnalyticsServiceProvider.overrideWithValue(
            RecordingAnalyticsService(prefs),
          ),
          userStatsProvider.overrideWith(() => FixedStatsNotifier(stats)),
          streakClockProvider.overrideWithValue(() => now),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start again'));
    await tester.pumpAndSettle();

    expect(find.text('route-placeholder'), findsOneWidget);
    expect(prefs.getBool(streakLostAckKey(stats)), isTrue);
  });

  testWidgets('hidden while the streak is alive', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final stats = statsWith(
      streak: 3,
      lastActiveDate: dateKey(now),
      practiceDates: {dateKey(now)},
    );
    await tester.pumpWidget(
      routerHost(
        child: const StreakLostCard(),
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          learningAnalyticsServiceProvider.overrideWithValue(
            RecordingAnalyticsService(prefs),
          ),
          userStatsProvider.overrideWith(() => FixedStatsNotifier(stats)),
          streakClockProvider.overrideWithValue(() => now),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SizedBox), findsWidgets);
    expect(find.textContaining('streak reset'), findsNothing);
  });
}
