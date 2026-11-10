import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/analytics/analytics_service.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/home/presentation/providers/today_activity_provider.dart';
import 'package:itun/features/home/presentation/widgets/daily_goal_celebration.dart';
import 'package:itun/l10n/generated/app_localizations.dart';
import 'package:itun/shared/providers/local_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'habit_test_support.dart';

class _Host extends ConsumerWidget {
  const _Host({required this.onRef});
  final void Function(WidgetRef ref, BuildContext context) onRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    listenForDailyGoalCelebration(context, ref);
    onRef(ref, context);
    return const SizedBox.shrink();
  }
}

void main() {
  final now = DateTime(2026, 11, 10, 20);

  testWidgets('celebrates once when the goal is reached, then stays quiet', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final analytics = RecordingAnalyticsService(prefs);
    late WidgetRef capturedRef;
    late BuildContext capturedContext;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          learningAnalyticsServiceProvider.overrideWithValue(analytics),
          todayActivityClockProvider.overrideWithValue(() => now),
          dailyGoalMinutesProvider.overrideWith((ref) => 5),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: _Host(
              onRef: (ref, context) {
                capturedRef = ref;
                capturedContext = context;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Below goal: nothing.
    expect(
      await celebrateDailyGoalIfNeeded(capturedContext, capturedRef),
      isFalse,
    );

    // Crossing the goal triggers the listener exactly once.
    await capturedRef.read(todayMinutesProvider.notifier).add(5);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Daily goal met'), findsOneWidget);
    expect(analytics.names, [LearningAnalyticsEvents.dailyGoalMet]);
    expect(analytics.events.single.meta, {'goalMinutes': 5, 'minutes': 5});
    expect(dailyGoalCelebratedToday(prefs, now: now), isTrue);

    // Already celebrated today: no second toast or event.
    expect(
      await celebrateDailyGoalIfNeeded(capturedContext, capturedRef),
      isFalse,
    );
    expect(analytics.names.length, 1);
  });

  testWidgets('a zero goal never celebrates', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final analytics = RecordingAnalyticsService(prefs);
    late WidgetRef capturedRef;
    late BuildContext capturedContext;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          learningAnalyticsServiceProvider.overrideWithValue(analytics),
          todayActivityClockProvider.overrideWithValue(() => now),
          dailyGoalMinutesProvider.overrideWith((ref) => 0),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: _Host(
              onRef: (ref, context) {
                capturedRef = ref;
                capturedContext = context;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(
      await celebrateDailyGoalIfNeeded(capturedContext, capturedRef),
      isFalse,
    );
    expect(analytics.names, isEmpty);
  });
}
