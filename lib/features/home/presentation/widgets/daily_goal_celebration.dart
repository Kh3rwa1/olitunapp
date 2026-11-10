// Once-per-day acknowledgement when today's minutes reach the daily goal:
// a small toast plus the `daily_goal_met` event. Honest by construction —
// it only fires on a real transition of dailyGoalMetProvider.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/storage/hive_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/providers/local_settings_provider.dart';
import '../providers/today_activity_provider.dart';

/// Call from a widget's `build` (uses `ref.listen`). Shows the toast and
/// logs the event the first time the goal is met on a given day.
void listenForDailyGoalCelebration(BuildContext context, WidgetRef ref) {
  ref.listen<bool>(dailyGoalMetProvider, (previous, next) {
    if (!next || previous == true) return;
    celebrateDailyGoalIfNeeded(context, ref);
  });
}

/// Runs the celebration if today's goal is met and not yet celebrated.
/// Returns true when it ran.
Future<bool> celebrateDailyGoalIfNeeded(
  BuildContext context,
  WidgetRef ref,
) async {
  if (!ref.read(dailyGoalMetProvider)) return false;
  final goal = ref.read(dailyGoalMinutesProvider);
  // A zero goal is "met" by definition; celebrating it would be noise.
  if (goal <= 0) return false;
  final prefs = ref.read(sharedPreferencesProvider);
  if (dailyGoalCelebratedToday(prefs)) return false;
  await markDailyGoalCelebrated(prefs);
  final minutes = ref.read(todayMinutesProvider);
  unawaited(
    ref
        .read(learningAnalyticsServiceProvider)
        .track(
          LearningAnalyticsEvents.dailyGoalMet,
          source: 'home',
          metadata: {'goalMinutes': goal, 'minutes': minutes},
        ),
  );
  if (!context.mounted) return true;
  final l10n = AppLocalizations.of(context);
  if (l10n == null) return true;
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.primaryDark,
      content: Row(
        children: [
          const Icon(Icons.emoji_events_rounded, color: AppColors.goldSoft),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.dailyGoalMetToast(minutes),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );
  return true;
}
