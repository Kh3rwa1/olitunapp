import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../shared/providers/providers.dart';
import 'mission_providers.dart';

class DailyMissionsObserver extends ProviderObserver {
  const DailyMissionsObserver();

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (provider == lessonCompletedTodayProvider ||
        provider == quizTakenTodayProvider ||
        provider == bakhedListenedTodayProvider ||
        provider == quickWinCompletedTodayProvider) {
      final lesson = container.read(lessonCompletedTodayProvider);
      final quiz = container.read(quizTakenTodayProvider);
      final bakhed = container.read(bakhedListenedTodayProvider);
      final quick = container.read(quickWinCompletedTodayProvider);

      if (lesson || quiz || bakhed || quick) {
        final notificationsEnabled = container.read(
          notificationsEnabledProvider,
        );
        if (notificationsEnabled) {
          final hour = container.read(reminderHourProvider);
          final minute = container.read(reminderMinuteProvider);
          NotificationService.instance.suppressTodayReminderIfPracticed(
            hour: hour,
            minute: minute,
          );
        }
      }

      final completedCount =
          (lesson ? 1 : 0) +
          (quiz ? 1 : 0) +
          (bakhed ? 1 : 0) +
          (quick ? 1 : 0);

      if (completedCount == 4) {
        container
            .read(userStatsProvider.notifier)
            .recordDailyMissionsCompletedToday();
      }
    }
  }
}
