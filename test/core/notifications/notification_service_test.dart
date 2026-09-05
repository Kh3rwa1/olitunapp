import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/notifications/notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(tz.initializeTimeZones);

  group('NotificationService', () {
    test('singleton instance is non-null and constants are defined', () {
      final service = NotificationService.instance;
      expect(service, isNotNull);
      expect(NotificationService.streakReminderNotificationId, equals(101));
      expect(NotificationService.morningReminderNotificationId, equals(102));
      expect(NotificationService.afternoonReminderNotificationId, equals(103));
      expect(NotificationService.nightStreakSaverNotificationId, equals(104));
      expect(NotificationService.inactivityReminderNotificationId, equals(105));
      expect(
        NotificationService.allReminderNotificationIds,
        containsAll([101, 102, 103, 104, 105]),
      );
      expect(
        NotificationService.reminderChannelId,
        equals('com.olitun.app.channel.reminders'),
      );
      expect(
        NotificationService.reminderChannelName,
        equals('Daily Study Reminders'),
      );
      expect(NotificationService.reminderChannelDescription, isNotEmpty);
    });

    test('NotificationFrequency extension returns expected properties', () {
      expect(NotificationFrequency.high.remindersPerDay, equals(4));
      expect(NotificationFrequency.high.label, contains('High'));
      expect(NotificationFrequency.high.description, isNotEmpty);

      expect(NotificationFrequency.balanced.remindersPerDay, equals(2));
      expect(NotificationFrequency.balanced.label, contains('Balanced'));
      expect(NotificationFrequency.balanced.description, isNotEmpty);

      expect(NotificationFrequency.once.remindersPerDay, equals(1));
      expect(NotificationFrequency.once.label, contains('Relaxed'));
      expect(NotificationFrequency.once.description, isNotEmpty);
    });

    test(
      'nextInstanceOfTime schedules for today when target is in the future',
      () {
        final service = NotificationService.instance;
        final location = tz.getLocation('UTC');
        tz.setLocalLocation(location);

        // Current time: 10:00 UTC
        final now = tz.TZDateTime(location, 2026, 9, 4, 10);
        // Target time: 20:00 UTC (future)
        final next = service.nextInstanceOfTime(20, 0, now);

        expect(next.year, equals(2026));
        expect(next.month, equals(9));
        expect(next.day, equals(4));
        expect(next.hour, equals(20));
        expect(next.minute, equals(0));
      },
    );

    test(
      'nextInstanceOfTime schedules for tomorrow when target has already passed today',
      () {
        final service = NotificationService.instance;
        final location = tz.getLocation('UTC');
        tz.setLocalLocation(location);

        // Current time: 21:30 UTC
        final now = tz.TZDateTime(location, 2026, 9, 4, 21, 30);
        // Target time: 20:00 UTC (past)
        final next = service.nextInstanceOfTime(20, 0, now);

        expect(next.year, equals(2026));
        expect(next.month, equals(9));
        expect(next.day, equals(5)); // Next day
        expect(next.hour, equals(20));
        expect(next.minute, equals(0));
      },
    );

    test(
      'nextInstanceOfTime handles exact time without producing past timestamps',
      () {
        final service = NotificationService.instance;
        final location = tz.getLocation('UTC');
        tz.setLocalLocation(location);

        final now = tz.TZDateTime(location, 2026, 9, 4, 20);
        final next = service.nextInstanceOfTime(20, 0, now);
        expect(next.hour, equals(20));
        expect(next.minute, equals(0));
        expect(next.isBefore(now), isFalse);
      },
    );

    test(
      'safe execution of schedule, suppress, and cancel in test environment',
      () async {
        final service = NotificationService.instance;
        expect(service.scheduleDailyStreakReminder, returnsNormally);
        expect(service.scheduleAllReminders, returnsNormally);
        expect(service.suppressTodayReminderIfPracticed, returnsNormally);
        expect(service.cancelDailyReminder, returnsNormally);
        expect(service.cancelAllReminders, returnsNormally);
        expect(await service.requestPermission(), isFalse);
      },
    );
  });
}
