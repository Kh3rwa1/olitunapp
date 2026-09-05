import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/notifications/notification_service.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/shared/providers/notification_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Notification Providers', () {
    test(
      'notificationsEnabledProvider defaults to true when unconfigured',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(container.dispose);

        expect(container.read(notificationsEnabledProvider), isTrue);
      },
    );

    test(
      'notificationsEnabledProvider respects stored false preference',
      () async {
        SharedPreferences.setMockInitialValues({
          'notifications_enabled': false,
        });
        final prefs = await SharedPreferences.getInstance();
        final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(container.dispose);

        expect(container.read(notificationsEnabledProvider), isFalse);
      },
    );

    test(
      'notificationsEnabledProvider toggles and persists preference',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(container.dispose);

        await container
            .read(notificationsEnabledProvider.notifier)
            .toggle(false);
        expect(container.read(notificationsEnabledProvider), isFalse);
        expect(prefs.getBool('notifications_enabled'), isFalse);

        await container
            .read(notificationsEnabledProvider.notifier)
            .toggle(true);
        expect(container.read(notificationsEnabledProvider), isTrue);
        expect(prefs.getBool('notifications_enabled'), isTrue);
      },
    );

    test('reminderHourProvider defaults to 20 and updates properly', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(reminderHourProvider), equals(20));

      await container.read(reminderHourProvider.notifier).setHour(19);
      expect(container.read(reminderHourProvider), equals(19));
      expect(prefs.getInt('reminder_hour'), equals(19));
    });

    test('reminderMinuteProvider defaults to 0 and updates properly', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(reminderMinuteProvider), equals(0));

      await container.read(reminderMinuteProvider.notifier).setMinute(30);
      expect(container.read(reminderMinuteProvider), equals(30));
      expect(prefs.getInt('reminder_minute'), equals(30));
    });

    test(
      'notificationFrequencyProvider defaults to high and updates properly',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(container.dispose);

        expect(
          container.read(notificationFrequencyProvider),
          equals(NotificationFrequency.high),
        );

        await container
            .read(notificationFrequencyProvider.notifier)
            .setFrequency(NotificationFrequency.balanced);
        expect(
          container.read(notificationFrequencyProvider),
          equals(NotificationFrequency.balanced),
        );
        expect(prefs.getString('notification_frequency'), equals('balanced'));

        await container
            .read(notificationFrequencyProvider.notifier)
            .setFrequency(NotificationFrequency.once);
        expect(
          container.read(notificationFrequencyProvider),
          equals(NotificationFrequency.once),
        );
        expect(prefs.getString('notification_frequency'), equals('once'));
      },
    );

    test(
      'notificationFrequencyProvider reads existing stored preference',
      () async {
        SharedPreferences.setMockInitialValues({
          'notification_frequency': 'once',
        });
        final prefs = await SharedPreferences.getInstance();
        final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(container.dispose);

        expect(
          container.read(notificationFrequencyProvider),
          equals(NotificationFrequency.once),
        );
      },
    );
  });
}
