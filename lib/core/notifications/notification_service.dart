import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../logging/app_logger.dart';

/// Frequency of habit and streak study reminders throughout the day.
enum NotificationFrequency {
  /// Single reminder per day at user's preferred time.
  once,

  /// 2 reminders per day: Morning kickstart (9:00 AM) and Evening study.
  balanced,

  /// 4 reminders per day: Morning (9:00 AM), Midday (2:30 PM), Evening, and Night streak saver (9:45 PM).
  high,
}

extension NotificationFrequencyX on NotificationFrequency {
  String get label {
    switch (this) {
      case NotificationFrequency.high:
        return 'High (4x daily)';
      case NotificationFrequency.balanced:
        return 'Balanced (2x daily)';
      case NotificationFrequency.once:
        return 'Relaxed (1x daily)';
    }
  }

  String get description {
    switch (this) {
      case NotificationFrequency.high:
        return 'Morning, Midday, Evening & Night streak saver';
      case NotificationFrequency.balanced:
        return 'Morning boost & Evening study reminder';
      case NotificationFrequency.once:
        return 'Single daily reminder at your preferred time';
    }
  }

  int get remindersPerDay {
    switch (this) {
      case NotificationFrequency.high:
        return 4;
      case NotificationFrequency.balanced:
        return 2;
      case NotificationFrequency.once:
        return 1;
    }
  }
}

/// Service responsible for managing local habit and streak reminders.
/// Operates 100% offline and respects user privacy without transmitting tokens.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const int streakReminderNotificationId = 101;
  static const int morningReminderNotificationId = 102;
  static const int afternoonReminderNotificationId = 103;
  static const int nightStreakSaverNotificationId = 104;
  static const int inactivityReminderNotificationId = 105;

  static const List<int> allReminderNotificationIds = [
    streakReminderNotificationId,
    morningReminderNotificationId,
    afternoonReminderNotificationId,
    nightStreakSaverNotificationId,
    inactivityReminderNotificationId,
  ];

  static const String reminderChannelId = 'com.olitun.app.channel.reminders';
  static const String reminderChannelName = 'Daily Study Reminders';
  static const String reminderChannelDescription =
      'Reminders to practice Ol Chiki and maintain your daily learning streak.';

  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      reminderChannelId,
      reminderChannelName,
      channelDescription: reminderChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Whether notification services are initialized and available.
  bool get isInitialized => _isInitialized;

  /// Initializes the local notification plugin and configures device timezone.
  /// Safe to call on any platform; gracefully no-ops on unsupported targets or in tests.
  Future<void> initialize() async {
    if (_isInitialized) return;

    if (kIsWeb) {
      AppLogger.debug(
        'NotificationService: Local notifications not supported on Web.',
      );
      _isInitialized = true;
      return;
    }

    try {
      // 1. Initialize timezone database
      tz.initializeTimeZones();
      try {
        final timezoneInfo = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
      } catch (e) {
        AppLogger.debug('NotificationService: timezone lookup fallback: $e');
      }

      // 2. Setup platform initialization settings
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const linuxSettings = LinuxInitializationSettings(
        defaultActionName: 'Open Olitun',
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
        linux: linuxSettings,
      );

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (details) {
          AppLogger.debug(
            'NotificationService: notification tapped (payload: ${details.payload})',
          );
        },
      );

      // 3. Create Android notification channel
      if (!kIsWeb && Platform.isAndroid) {
        final androidPlugin = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        if (androidPlugin != null) {
          await androidPlugin.createNotificationChannel(
            const AndroidNotificationChannel(
              reminderChannelId,
              reminderChannelName,
              description: reminderChannelDescription,
              importance: Importance.high,
            ),
          );
        }
      }

      _isInitialized = true;
      AppLogger.debug('NotificationService: initialized successfully.');
    } catch (e, stack) {
      AppLogger.debug('NotificationService: initialization error: $e\n$stack');
    }
  }

  /// Explicitly requests notification permissions from the user.
  /// Recommended to call when the user enables reminders in Settings or finishes their first lesson.
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    try {
      if (Platform.isAndroid) {
        final androidPlugin = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final granted =
            await androidPlugin?.requestNotificationsPermission() ?? false;
        return granted;
      } else if (Platform.isIOS || Platform.isMacOS) {
        final darwinPlugin = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        final granted =
            await darwinPlugin?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
        return granted;
      }
    } catch (e) {
      AppLogger.debug('NotificationService: requestPermission error: $e');
    }
    return false;
  }

  /// Calculates the next scheduled instance for [hour]:[minute].
  /// If the time has already passed today, schedules for tomorrow at the same time.
  @visibleForTesting
  tz.TZDateTime nextInstanceOfTime(int hour, int minute, [tz.TZDateTime? now]) {
    final current = now ?? tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      current.year,
      current.month,
      current.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(current)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Schedules a specific reminder slot at [hour]:[minute].
  Future<void> _scheduleSlot({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    tz.TZDateTime? startFrom,
  }) async {
    final scheduledDate = startFrom != null
        ? tz.TZDateTime(
            tz.local,
            startFrom.year,
            startFrom.month,
            startFrom.day,
            hour,
            minute,
          )
        : nextInstanceOfTime(hour, minute);

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedules an inactivity reminder after 3 days of no learning.
  Future<void> _scheduleInactivityReminder([tz.TZDateTime? from]) async {
    final baseTime = from ?? tz.TZDateTime.now(tz.local);
    final scheduledDate = baseTime.add(const Duration(days: 3));

    await _plugin.zonedSchedule(
      id: inactivityReminderNotificationId,
      title: 'We miss you in Olitun! 🪶',
      body: 'Your Santali learning journey is waiting. Jump back in today!',
      scheduledDate: scheduledDate,
      notificationDetails: _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Schedules all configured habit reminders according to [frequency].
  /// [hour] and [minute] define the main evening study reminder time.
  Future<void> scheduleAllReminders({
    NotificationFrequency frequency = NotificationFrequency.high,
    int hour = 20,
    int minute = 0,
  }) async {
    if (kIsWeb || !_isInitialized) return;

    try {
      await cancelAllReminders();

      // 1. Main Study Reminder (User-selected evening time)
      await _scheduleSlot(
        id: streakReminderNotificationId,
        hour: hour,
        minute: minute,
        title: 'Protect your streak! 🔥',
        body:
            'Take 2 minutes to practice Ol Chiki today and keep your streak alive.',
      );

      // 2. Morning Kickstart (9:00 AM) for Balanced and High frequency
      if (frequency == NotificationFrequency.balanced ||
          frequency == NotificationFrequency.high) {
        await _scheduleSlot(
          id: morningReminderNotificationId,
          hour: 9,
          minute: 0,
          title: 'Start your morning with Ol Chiki! ☀️',
          body:
              'A quick 2-minute lesson starts your day with positive momentum.',
        );
      }

      // 3. Afternoon Booster (2:30 PM) and Night Streak Saver (9:45 PM) for High frequency
      if (frequency == NotificationFrequency.high) {
        await _scheduleSlot(
          id: afternoonReminderNotificationId,
          hour: 14,
          minute: 30,
          title: 'Midday Ol Chiki boost! 🎯',
          body: 'Take a short break and master a new Santali word today.',
        );

        final nightHour = (hour >= 21 && minute >= 30) ? 22 : 21;
        final nightMinute = (nightHour == 22) ? 30 : 45;
        await _scheduleSlot(
          id: nightStreakSaverNotificationId,
          hour: nightHour,
          minute: nightMinute,
          title: 'Don\'t lose your streak! ⏳',
          body:
              'Your streak is waiting! Complete a quick lesson before midnight to save your progress.',
        );
      }

      // 4. Inactivity Re-engagement reminder (3 days from now)
      await _scheduleInactivityReminder();

      AppLogger.debug(
        'NotificationService: Scheduled ${frequency.remindersPerDay} daily reminders (frequency: ${frequency.name}, main time: $hour:${minute.toString().padLeft(2, '0')})',
      );
    } catch (e) {
      AppLogger.debug('NotificationService: scheduleAllReminders error: $e');
    }
  }

  /// Schedules a repeating daily streak reminder (backwards-compatible alias).
  Future<void> scheduleDailyStreakReminder({
    int hour = 20,
    int minute = 0,
    String? title,
    String? body,
    NotificationFrequency frequency = NotificationFrequency.high,
  }) async {
    await scheduleAllReminders(
      frequency: frequency,
      hour: hour,
      minute: minute,
    );
  }

  /// Suppresses reminders for today if the user has already practiced today.
  /// Re-arms reminders starting tomorrow according to [frequency].
  Future<void> suppressTodayReminderIfPracticed({
    int hour = 20,
    int minute = 0,
    NotificationFrequency frequency = NotificationFrequency.high,
  }) async {
    if (kIsWeb || !_isInitialized) return;

    try {
      final now = tz.TZDateTime.now(tz.local);
      final tomorrow = now.add(const Duration(days: 1));

      // Cancel all active reminder IDs for today
      for (final id in allReminderNotificationIds) {
        await _plugin.cancel(id: id);
      }

      // Re-arm Main Reminder starting tomorrow
      await _scheduleSlot(
        id: streakReminderNotificationId,
        hour: hour,
        minute: minute,
        title: 'Keep the momentum going! 🔥',
        body:
            'Ready for your daily Ol Chiki practice? Keep your streak shining.',
        startFrom: tomorrow,
      );

      // Re-arm Morning Kickstart starting tomorrow
      if (frequency == NotificationFrequency.balanced ||
          frequency == NotificationFrequency.high) {
        await _scheduleSlot(
          id: morningReminderNotificationId,
          hour: 9,
          minute: 0,
          title: 'Start your morning with Ol Chiki! ☀️',
          body:
              'A quick 2-minute lesson starts your day with positive momentum.',
          startFrom: tomorrow,
        );
      }

      // Re-arm Afternoon and Night Streak Saver starting tomorrow
      if (frequency == NotificationFrequency.high) {
        await _scheduleSlot(
          id: afternoonReminderNotificationId,
          hour: 14,
          minute: 30,
          title: 'Midday Ol Chiki boost! 🎯',
          body: 'Take a short break and master a new Santali word today.',
          startFrom: tomorrow,
        );

        final nightHour = (hour >= 21 && minute >= 30) ? 22 : 21;
        final nightMinute = (nightHour == 22) ? 30 : 45;
        await _scheduleSlot(
          id: nightStreakSaverNotificationId,
          hour: nightHour,
          minute: nightMinute,
          title: 'Don\'t lose your streak! ⏳',
          body:
              'Your streak is waiting! Complete a quick lesson before midnight to save your progress.',
          startFrom: tomorrow,
        );
      }

      // Re-arm inactivity reminder for 3 days from today
      await _scheduleInactivityReminder(now);

      AppLogger.debug(
        'NotificationService: Suppressed today\'s reminders since user practiced. Next armed starting tomorrow.',
      );
    } catch (e) {
      AppLogger.debug(
        'NotificationService: suppressTodayReminderIfPracticed error: $e',
      );
    }
  }

  /// Cancels all scheduled habit, streak, and inactivity reminders.
  Future<void> cancelAllReminders() async {
    if (kIsWeb || !_isInitialized) return;

    try {
      for (final id in allReminderNotificationIds) {
        await _plugin.cancel(id: id);
      }
      AppLogger.debug('NotificationService: all reminders canceled.');
    } catch (e) {
      AppLogger.debug('NotificationService: cancelAllReminders error: $e');
    }
  }

  /// Cancels any scheduled daily streak reminder (backwards-compatible alias).
  Future<void> cancelDailyReminder() async {
    await cancelAllReminders();
  }
}
