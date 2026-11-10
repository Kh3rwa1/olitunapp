import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/home/presentation/providers/displayed_streak_provider.dart';
import 'package:itun/features/home/presentation/providers/today_activity_provider.dart';
import 'package:itun/features/home/presentation/widgets/home_header.dart';
import 'package:itun/features/home/presentation/widgets/home_skeletons.dart';
import 'package:itun/features/home/presentation/widgets/today_strip.dart';
import 'package:itun/features/profile/presentation/providers/profile_providers.dart';
import 'package:itun/features/review/data/review_store_notifier.dart';
import 'package:itun/shared/providers/local_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'habit_test_support.dart';

void main() {
  final now = DateTime(2026, 11, 10, 8);

  testWidgets('header shows greeting, subtitle and the Today strip', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      routerHost(
        child: HomeHeader(
          userName: 'Asha',
          isDark: false,
          isNewcomer: true,
          now: now,
        ),
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

    expect(find.text('Johar, Asha!'), findsOneWidget);
    expect(find.textContaining('GOOD MORNING'), findsOneWidget);
    expect(find.byType(TodayStrip), findsOneWidget);
    expect(find.text('Start a streak today'), findsOneWidget);
  });

  test('monthName maps and clamps', () {
    expect(HomeHeader.monthName(1), 'Jan');
    expect(HomeHeader.monthName(11), 'Nov');
    expect(HomeHeader.monthName(99), 'Dec');
  });

  testWidgets('skeletons render in both themes', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              HomeStatsSkeleton(isDark: false),
              Expanded(child: HomeGridSkeleton(isDark: true)),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(HomeStatsSkeleton), findsOneWidget);
    expect(find.byType(HomeGridSkeleton), findsOneWidget);
  });
}
