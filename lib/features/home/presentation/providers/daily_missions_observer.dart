import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../shared/providers/providers.dart';
import 'mission_providers.dart';

/// Suppresses today's habit reminders once the learner has practiced —
/// a reminder to practice is pointless (and naggy) after real practice.
///
/// The former "4/4 daily missions" gamification was retired with the
/// TodayMissionCard; the practice flags themselves remain because
/// NextBestActionCard and quiz/lesson/rhyme flows still set and read them.
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
        provider == bakhedListenedTodayProvider) {
      final practiced =
          container.read(lessonCompletedTodayProvider) ||
          container.read(quizTakenTodayProvider) ||
          container.read(bakhedListenedTodayProvider);

      if (practiced) {
        final notificationsEnabled = container.read(
          notificationsEnabledProvider,
        );
        if (notificationsEnabled) {
          final hour = container.read(reminderHourProvider);
          final minute = container.read(reminderMinuteProvider);
          final frequency = container.read(notificationFrequencyProvider);
          NotificationService.instance.suppressTodayReminderIfPracticed(
            hour: hour,
            minute: minute,
            frequency: frequency,
          );
        }
      }
    }
  }
}
