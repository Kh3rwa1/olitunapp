import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'notification_types.dart';
import 'reminder_context.dart';
import 'reminder_copy.dart';

/// Notification ids for every reminder slot.
class ReminderIds {
  const ReminderIds._();

  static const int evening = 101;
  static const int morning = 102;
  static const int afternoon = 103;
  static const int night = 104;
  static const int lapseDay3 = 105;
  static const int lapseDay7 = 106;
  static const int lapseDay14 = 107;

  static const List<int> all = [
    evening,
    morning,
    afternoon,
    night,
    lapseDay3,
    lapseDay7,
    lapseDay14,
  ];

  /// Days-without-practice for each lapse one-shot.
  static const Map<int, int> lapseDays = {
    lapseDay3: 3,
    lapseDay7: 7,
    lapseDay14: 14,
  };
}

/// One scheduled reminder, as a pure value (testable without a plugin).
class ReminderSlot {
  const ReminderSlot({
    required this.id,
    required this.hour,
    required this.minute,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final int hour;
  final int minute;
  final String title;
  final String body;
  final String payload;
}

/// Builds the repeating daily slots for [frequency] from honest state.
/// The night "streak saver" exists only when there is a streak to save.
List<ReminderSlot> buildDailySlots({
  required NotificationFrequency frequency,
  required int hour,
  required int minute,
  required ReminderContext context,
}) {
  final payload = ReminderCopy.payloadFor(context);
  final evening = ReminderCopy.evening(context);
  final slots = <ReminderSlot>[
    ReminderSlot(
      id: ReminderIds.evening,
      hour: hour,
      minute: minute,
      title: evening.title,
      body: evening.body,
      payload: payload,
    ),
  ];
  if (frequency == NotificationFrequency.balanced ||
      frequency == NotificationFrequency.high) {
    final morning = ReminderCopy.morning(context);
    slots.add(
      ReminderSlot(
        id: ReminderIds.morning,
        hour: 9,
        minute: 0,
        title: morning.title,
        body: morning.body,
        payload: payload,
      ),
    );
  }
  if (frequency == NotificationFrequency.high) {
    final afternoon = ReminderCopy.afternoon(context);
    slots.add(
      ReminderSlot(
        id: ReminderIds.afternoon,
        hour: 14,
        minute: 30,
        title: afternoon.title,
        body: afternoon.body,
        payload: 'daily',
      ),
    );
    if (context.streak > 0) {
      final nightHour = (hour >= 21 && minute >= 30) ? 22 : 21;
      final nightMinute = (nightHour == 22) ? 30 : 45;
      final night = ReminderCopy.night(context);
      slots.add(
        ReminderSlot(
          id: ReminderIds.night,
          hour: nightHour,
          minute: nightMinute,
          title: night.title,
          body: night.body,
          payload: 'daily',
        ),
      );
    }
  }
  return slots;
}

/// Talks to the platform plugin. Everything decided above is pure.
class ReminderScheduler {
  ReminderScheduler(this._plugin, this._details);

  final FlutterLocalNotificationsPlugin _plugin;
  final NotificationDetails _details;

  /// Next occurrence of [hour]:[minute]; tomorrow if already past today.
  static tz.TZDateTime nextInstanceOfTime(
    int hour,
    int minute, [
    tz.TZDateTime? now,
  ]) {
    final current = now ?? tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      current.year,
      current.month,
      current.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(current)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> cancelAll() async {
    for (final id in ReminderIds.all) {
      await _plugin.cancel(id: id);
    }
  }

  /// Cancels everything, then arms [slots] (repeating daily, from today or
  /// from [startFrom]) plus the lapse series counted from [now].
  Future<void> arm({
    required List<ReminderSlot> slots,
    required tz.TZDateTime now,
    tz.TZDateTime? startFrom,
  }) async {
    await cancelAll();
    for (final slot in slots) {
      await scheduleSlot(slot, startFrom: startFrom);
    }
    await scheduleLapseSeries(now);
  }

  /// Arms one repeating slot.
  Future<void> scheduleSlot(ReminderSlot slot, {tz.TZDateTime? startFrom}) {
    final when = startFrom != null
        ? tz.TZDateTime(
            tz.local,
            startFrom.year,
            startFrom.month,
            startFrom.day,
            slot.hour,
            slot.minute,
          )
        : nextInstanceOfTime(slot.hour, slot.minute);
    return _plugin.zonedSchedule(
      id: slot.id,
      title: slot.title,
      body: slot.body,
      payload: slot.payload,
      scheduledDate: when,
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// One-shots at 3, 7 and 14 days after [from]. Re-armed on every
  /// practice, so they only ever fire for a learner who really lapsed.
  Future<void> scheduleLapseSeries(tz.TZDateTime from) async {
    for (final entry in ReminderIds.lapseDays.entries) {
      final copy = ReminderCopy.lapse(entry.value);
      await _plugin.zonedSchedule(
        id: entry.key,
        title: copy.title,
        body: copy.body,
        payload: 'daily',
        scheduledDate: from.add(Duration(days: entry.value)),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}
