import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import '../logging/app_logger.dart';
import 'notification_types.dart';
import 'reminder_context.dart';
import 'reminder_scheduler.dart';
export 'notification_types.dart';
export 'reminder_context.dart';
export 'reminder_copy.dart';
export 'reminder_scheduler.dart'
    show ReminderIds, ReminderSlot, buildDailySlots;

/// Service responsible for managing local habit and streak reminders.
/// Operates 100% offline and respects user privacy without transmitting tokens.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  /// Payload that deep-links to Today's Review ('/review').
  static const String reviewNotificationPayload = 'review';

  /// Payload that opens Home (daily habit reminders and the lapse series).
  static const String dailyNotificationPayload = 'daily';

  /// Payload that opens Daily Practice ('/practice/daily').
  static const String practiceNotificationPayload = 'practice';

  /// Prefs flag: the one-time permission prompt has been shown.
  static const String permissionPromptedPrefKey =
      'notification_permission_prompted_v1';

  /// Tap handler installed by the app root (deep link to Today's Review).
  /// Null in tests / when the router isn't mounted.
  // ignore: avoid_setters_without_getters
  static void Function(String? payload)? onNotificationTap;

  static const int streakReminderNotificationId = ReminderIds.evening;
  static const int morningReminderNotificationId = ReminderIds.morning;
  static const int afternoonReminderNotificationId = ReminderIds.afternoon;
  static const int nightStreakSaverNotificationId = ReminderIds.night;
  static const int inactivityReminderNotificationId = ReminderIds.lapseDay3;
  static const int lapseDay7NotificationId = ReminderIds.lapseDay7;
  static const int lapseDay14NotificationId = ReminderIds.lapseDay14;

  static final List<int> allReminderNotificationIds = ReminderIds.all;

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
  late final ReminderScheduler _scheduler = ReminderScheduler(
    _plugin,
    _notificationDetails,
  );
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
      // 1. Initialize timezone database and guarantee UTC baseline
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.UTC);
      } catch (e) {
        AppLogger.debug(
          'Setting the UTC timezone baseline failed: $e',
          name: 'NotificationService',
        );
      }
      try {
        final timezoneInfo = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
      } catch (e) {
        AppLogger.debug(
          'NotificationService: timezone lookup fallback to UTC: $e',
        );
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
          try {
            onNotificationTap?.call(details.payload);
          } catch (e) {
            AppLogger.debug('NotificationService: tap handler error: $e');
          }
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
  /// Recommended to call on startup or when the user enables reminders in Settings.
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    try {
      if (!_isInitialized) {
        await initialize();
      }
      if (Platform.isAndroid) {
        final androidPlugin = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final granted =
            await androidPlugin?.requestNotificationsPermission() ?? false;
        return granted;
      } else if (Platform.isIOS) {
        final iosPlugin = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        final granted =
            await iosPlugin?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
        return granted;
      } else if (Platform.isMacOS) {
        final macosPlugin = _plugin
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >();
        final granted =
            await macosPlugin?.requestPermissions(
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

  /// Checks whether notifications are currently allowed on the device.
  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return false;

    try {
      if (!_isInitialized) {
        await initialize();
      }
      if (Platform.isAndroid) {
        final androidPlugin = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        return await androidPlugin?.areNotificationsEnabled() ?? false;
      } else if (Platform.isIOS) {
        final iosPlugin = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        final permissions = await iosPlugin?.checkPermissions();
        return permissions?.isEnabled ?? false;
      } else if (Platform.isMacOS) {
        final macosPlugin = _plugin
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >();
        final permissions = await macosPlugin?.checkPermissions();
        return permissions?.isEnabled ?? false;
      }
    } catch (e) {
      AppLogger.debug('NotificationService: areNotificationsEnabled error: $e');
    }
    return false;
  }

  /// Displays an immediate test notification to verify that notification channels
  /// and permissions are fully operational on this device.
  Future<bool> showInstantTestNotification({
    String title = 'Olitun Reminder Test 🔥',
    String body =
        'Notifications are working perfectly! Keep up your Ol Chiki practice.',
  }) async {
    if (kIsWeb) return false;

    try {
      if (!_isInitialized) {
        await initialize();
      }
      final granted = await requestPermission();
      if (!granted) {
        final isEnabled = await areNotificationsEnabled();
        if (!isEnabled) return false;
      }

      await _plugin.show(
        id: 999,
        title: title,
        body: body,
        notificationDetails: _notificationDetails,
      );
      AppLogger.debug('NotificationService: instant test notification shown.');
      return true;
    } catch (e) {
      AppLogger.debug(
        'NotificationService: showInstantTestNotification error: $e',
      );
      return false;
    }
  }

  /// Calculates the next scheduled instance for [hour]:[minute].
  /// If the time has already passed today, schedules for tomorrow at the same time.
  @visibleForTesting
  tz.TZDateTime nextInstanceOfTime(
    int hour,
    int minute, [
    tz.TZDateTime? now,
  ]) => ReminderScheduler.nextInstanceOfTime(hour, minute, now);

  /// Prompts for notification permission at a moment of success: only once
  /// (prefs flag [permissionPromptedPrefKey]) and only after the learner has
  /// actually practiced, so the system dialog never greets a newcomer.
  /// Returns whether permission is granted. Settings keeps using
  /// [requestPermission] directly.
  Future<bool> requestPermissionIfEligible({
    required bool hasPracticed,
    required SharedPreferences prefs,
  }) async {
    if (kIsWeb || !hasPracticed) return false;
    if (prefs.getBool(permissionPromptedPrefKey) ?? false) return false;
    await prefs.setBool(permissionPromptedPrefKey, true);
    final granted = await requestPermission();
    await prefs.setBool('notification_permission_granted', granted);
    AppLogger.debug(
      'NotificationService: permission prompt after practice → $granted',
    );
    return granted;
  }

  /// Schedules every habit reminder for [frequency] with copy built from
  /// [context]. When the learner already practiced today the slots start
  /// tomorrow, so a reopen never re-arms a reminder practice just earned.
  Future<void> scheduleAllReminders({
    NotificationFrequency frequency = ReminderPolicy.defaultFrequency,
    int hour = 20,
    int minute = 0,
    ReminderContext context = ReminderContext.empty,
  }) => _arm(
    frequency: frequency,
    hour: hour,
    minute: minute,
    context: context,
    fromTomorrow: context.practicedToday,
    reason: 'schedule',
  );

  /// Suppresses today's reminders after real practice and re-arms them from
  /// tomorrow (same slots, honest copy, lapse series counted from now).
  Future<void> suppressTodayReminderIfPracticed({
    int hour = 20,
    int minute = 0,
    NotificationFrequency frequency = ReminderPolicy.defaultFrequency,
    ReminderContext context = ReminderContext.empty,
  }) => _arm(
    frequency: frequency,
    hour: hour,
    minute: minute,
    context: context.copyWith(practicedToday: true),
    fromTomorrow: true,
    reason: 'suppress-today',
  );

  Future<void> _arm({
    required NotificationFrequency frequency,
    required int hour,
    required int minute,
    required ReminderContext context,
    required bool fromTomorrow,
    required String reason,
  }) async {
    if (kIsWeb) return;
    if (!_isInitialized) {
      await initialize();
    }
    try {
      final now = tz.TZDateTime.now(tz.local);
      final slots = buildDailySlots(
        frequency: frequency,
        hour: hour,
        minute: minute,
        context: context,
      );
      await _scheduler.arm(
        slots: slots,
        now: now,
        startFrom: fromTomorrow ? now.add(const Duration(days: 1)) : null,
      );
      AppLogger.debug(
        'NotificationService: $reason armed ${slots.length} daily slot(s) '
        '(${frequency.name}, main $hour:${minute.toString().padLeft(2, '0')}, '
        'from ${fromTomorrow ? 'tomorrow' : 'today'}, $context)',
      );
    } catch (e) {
      AppLogger.debug('NotificationService: $reason error: $e');
    }
  }

  /// Schedules a repeating daily streak reminder (backwards-compatible alias).
  Future<void> scheduleDailyStreakReminder({
    int hour = 20,
    int minute = 0,
    String? title,
    String? body,
    NotificationFrequency frequency = ReminderPolicy.defaultFrequency,
  }) async {
    await scheduleAllReminders(
      frequency: frequency,
      hour: hour,
      minute: minute,
    );
  }

  /// Replaces ONLY the evening slot with learner-state copy ("N reviews
  /// ready · ~M min"). Same volume — no extra notifications, no spam.
  /// [title]/[body] override the English fallback with already-localized
  /// copy (resolved by the caller with the active locale). Tapping the
  /// notification deep-links to Today's Review via [reviewNotificationPayload].
  /// Call at most once/day (caller guards with a date-keyed pref) and only
  /// when [dueCount] > 0 and reminders are enabled.
  Future<void> syncEveningReminderWithReview({
    required int dueCount,
    required int minutes,
    int struggleCount = 0,
    int hour = 20,
    int minute = 0,
    String? title,
    String? body,
  }) async {
    if (kIsWeb || dueCount <= 0) return;
    if (!_isInitialized) {
      await initialize();
    }
    try {
      final copy = struggleCount > 0 && struggleCount >= dueCount ~/ 2
          ? NotificationCopy.reviewStruggle(struggleCount: struggleCount)
          : NotificationCopy.reviewDue(dueCount: dueCount, minutes: minutes);
      await _plugin.cancel(id: streakReminderNotificationId);
      await _scheduler.scheduleSlot(
        ReminderSlot(
          id: streakReminderNotificationId,
          hour: hour,
          minute: minute,
          title: title ?? copy.title,
          body: body ?? copy.body,
          payload: reviewNotificationPayload,
        ),
      );
      AppLogger.debug(
        'NotificationService: evening reminder synced with review ($dueCount due).',
      );
    } catch (e) {
      AppLogger.debug(
        'NotificationService: syncEveningReminderWithReview error: $e',
      );
    }
  }

  /// Cancels all scheduled habit, streak, and lapse reminders.
  Future<void> cancelAllReminders() async {
    if (kIsWeb) return;
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _scheduler.cancelAll();
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
