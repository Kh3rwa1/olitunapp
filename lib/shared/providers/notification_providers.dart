import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/storage/hive_service.dart';

const String _notificationsEnabledKey = 'notifications_enabled';
const String _reminderHourKey = 'reminder_hour';
const String _reminderMinuteKey = 'reminder_minute';
const String _notificationFrequencyKey = 'notification_frequency';

/// Provider for whether daily study notifications are enabled.
final notificationsEnabledProvider =
    NotifierProvider<NotificationsEnabledNotifier, bool>(
      NotificationsEnabledNotifier.new,
    );

class NotificationsEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  Future<void> toggle(bool enabled) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_notificationsEnabledKey, enabled);
    state = enabled;

    if (enabled) {
      final hour = ref.read(reminderHourProvider);
      final minute = ref.read(reminderMinuteProvider);
      final frequency = ref.read(notificationFrequencyProvider);
      await NotificationService.instance.requestPermission();
      await NotificationService.instance.scheduleAllReminders(
        frequency: frequency,
        hour: hour,
        minute: minute,
      );
    } else {
      await NotificationService.instance.cancelAllReminders();
    }
  }
}

/// Provider for the preferred daily reminder hour (0-23, 24-hour format).
final reminderHourProvider = NotifierProvider<ReminderHourNotifier, int>(
  ReminderHourNotifier.new,
);

class ReminderHourNotifier extends Notifier<int> {
  @override
  int build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getInt(_reminderHourKey) ?? 20; // Default: 8:00 PM
  }

  Future<void> setHour(int hour) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_reminderHourKey, hour);
    state = hour;

    if (ref.read(notificationsEnabledProvider)) {
      final minute = ref.read(reminderMinuteProvider);
      final frequency = ref.read(notificationFrequencyProvider);
      await NotificationService.instance.scheduleAllReminders(
        frequency: frequency,
        hour: hour,
        minute: minute,
      );
    }
  }
}

/// Provider for the preferred daily reminder minute (0-59).
final reminderMinuteProvider = NotifierProvider<ReminderMinuteNotifier, int>(
  ReminderMinuteNotifier.new,
);

class ReminderMinuteNotifier extends Notifier<int> {
  @override
  int build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getInt(_reminderMinuteKey) ?? 0;
  }

  Future<void> setMinute(int minute) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_reminderMinuteKey, minute);
    state = minute;

    if (ref.read(notificationsEnabledProvider)) {
      final hour = ref.read(reminderHourProvider);
      final frequency = ref.read(notificationFrequencyProvider);
      await NotificationService.instance.scheduleAllReminders(
        frequency: frequency,
        hour: hour,
        minute: minute,
      );
    }
  }
}

/// Provider for notification frequency preference (once, balanced, high).
final notificationFrequencyProvider =
    NotifierProvider<NotificationFrequencyNotifier, NotificationFrequency>(
      NotificationFrequencyNotifier.new,
    );

class NotificationFrequencyNotifier extends Notifier<NotificationFrequency> {
  @override
  NotificationFrequency build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final val = prefs.getString(_notificationFrequencyKey);
    return NotificationFrequency.values.firstWhere(
      (f) => f.name == val,
      orElse: () => NotificationFrequency.high,
    );
  }

  Future<void> setFrequency(NotificationFrequency frequency) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_notificationFrequencyKey, frequency.name);
    state = frequency;

    if (ref.read(notificationsEnabledProvider)) {
      final hour = ref.read(reminderHourProvider);
      final minute = ref.read(reminderMinuteProvider);
      await NotificationService.instance.scheduleAllReminders(
        frequency: frequency,
        hour: hour,
        minute: minute,
      );
    }
  }
}
