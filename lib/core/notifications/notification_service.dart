import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../logging/app_logger.dart';

/// Service responsible for managing local habit and streak reminders.
/// Operates 100% offline and respects user privacy without transmitting tokens.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const int streakReminderNotificationId = 101;
  static const String reminderChannelId = 'com.olitun.app.channel.reminders';
  static const String reminderChannelName = 'Daily Study Reminders';
  static const String reminderChannelDescription =
      'Reminders to practice Ol Chiki and maintain your daily learning streak.';

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

  /// Schedules a repeating daily streak reminder at the specified [hour] and [minute] (24-hour clock).
  Future<void> scheduleDailyStreakReminder({
    int hour = 20,
    int minute = 0,
    String? title,
    String? body,
  }) async {
    if (kIsWeb || !_isInitialized) return;

    try {
      final scheduledDate = nextInstanceOfTime(hour, minute);

      const notificationDetails = NotificationDetails(
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

      await _plugin.zonedSchedule(
        id: streakReminderNotificationId,
        title: title ?? 'Protect your streak! 🔥',
        body:
            body ??
            'Take 2 minutes to practice Ol Chiki today and keep your streak alive.',
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      AppLogger.debug(
        'NotificationService: Scheduled daily streak reminder at $hour:${minute.toString().padLeft(2, '0')} (next: $scheduledDate)',
      );
    } catch (e) {
      AppLogger.debug(
        'NotificationService: scheduleDailyStreakReminder error: $e',
      );
    }
  }

  /// Suppresses reminder for today if the user has already practiced today.
  /// Re-arms the reminder starting tomorrow at the specified (or default) hour and minute.
  Future<void> suppressTodayReminderIfPracticed({
    int hour = 20,
    int minute = 0,
  }) async {
    if (kIsWeb || !_isInitialized) return;

    try {
      final now = tz.TZDateTime.now(tz.local);
      final tomorrow = now.add(const Duration(days: 1));
      final scheduledDate = tz.TZDateTime(
        tz.local,
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        hour,
        minute,
      );

      const notificationDetails = NotificationDetails(
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

      await _plugin.cancel(id: streakReminderNotificationId);
      await _plugin.zonedSchedule(
        id: streakReminderNotificationId,
        title: 'Keep the momentum going! 🔥',
        body:
            'Ready for your daily Ol Chiki practice? Keep your streak shining.',
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      AppLogger.debug(
        'NotificationService: Suppressed today reminder since user practiced. Next scheduled for: $scheduledDate',
      );
    } catch (e) {
      AppLogger.debug(
        'NotificationService: suppressTodayReminderIfPracticed error: $e',
      );
    }
  }

  /// Cancels any scheduled daily streak reminder.
  Future<void> cancelDailyReminder() async {
    if (kIsWeb || !_isInitialized) return;

    try {
      await _plugin.cancel(id: streakReminderNotificationId);
      AppLogger.debug('NotificationService: daily reminder canceled.');
    } catch (e) {
      AppLogger.debug('NotificationService: cancelDailyReminder error: $e');
    }
  }
}
