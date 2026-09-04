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
        expect(service.suppressTodayReminderIfPracticed, returnsNormally);
        expect(service.cancelDailyReminder, returnsNormally);
        expect(await service.requestPermission(), isFalse);
      },
    );
  });
}
