import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../shared/providers/providers.dart';
import '../../../profile/domain/streak_week_logic.dart';
import '../../../profile/presentation/providers/user_stats_provider.dart';
import '../../../review/data/review_store_notifier.dart';
import 'mission_providers.dart';

/// Honest [ReminderContext] from live learner state: the streak derived
/// from practice dates (never the stale stored counter), due reviews, and
/// today's practice flags. Null until stats have loaded.
final liveReminderContextProvider = Provider<ReminderContext?>((ref) {
  final stats = ref.watch(userStatsProvider).valueOrNull;
  if (stats == null) return null;
  final now = ref.watch(missionClockProvider)();
  final streak = StreakWeekLogic.deriveStreak(
    stats.practiceDates,
    asOf: now,
    lastActiveDate: stats.lastActiveDate,
    fallbackStreak: stats.currentStreak,
  );
  final practicedToday =
      ref.watch(lessonCompletedTodayProvider) ||
      ref.watch(quizTakenTodayProvider) ||
      ref.watch(bakhedListenedTodayProvider);
  DateTime? lastPractice;
  if (practicedToday) {
    lastPractice = DateTime(now.year, now.month, now.day);
  } else {
    final dates = stats.practiceDates
        .map(DateTime.tryParse)
        .whereType<DateTime>();
    for (final d in dates) {
      if (lastPractice == null || d.isAfter(lastPractice)) lastPractice = d;
    }
    final lastActive = DateTime.tryParse(stats.lastActiveDate);
    if (lastActive != null &&
        (lastPractice == null || lastActive.isAfter(lastPractice))) {
      lastPractice = lastActive;
    }
  }
  return ReminderContext(
    streak: streak,
    dueReviews: ref.watch(dueReviewCountProvider),
    practicedToday: practicedToday,
    lastPracticeAt: lastPractice,
  );
});

/// Keeps [reminderContextProvider] current and re-arms the reminders with
/// honest copy whenever the context really changes. Startup (main.dart)
/// schedules with an empty context before stats exist; this corrects it
/// once per distinct state, so a stale "protect your streak" never fires
/// for a learner with no streak. Watch once from Home (or the app root).
final reminderSyncProvider = Provider<void>((ref) {
  void sync(ReminderContext? previous, ReminderContext? next) {
    if (next == null || next == previous) return;
    ref.read(reminderContextProvider.notifier).state = next;
    if (!ref.read(notificationsEnabledProvider)) return;
    unawaited(
      NotificationService.instance.scheduleAllReminders(
        frequency: ref.read(notificationFrequencyProvider),
        hour: ref.read(reminderHourProvider),
        minute: ref.read(reminderMinuteProvider),
        context: next,
      ),
    );
  }

  ref.listen<ReminderContext?>(liveReminderContextProvider, sync);
  // Initial pass after build: a provider may not mutate another while
  // it is being initialised.
  Future.microtask(() => sync(null, ref.read(liveReminderContextProvider)));
});
