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

  /// Daily slots are armed as dated one-shots, one per day for the next
  /// [dailyHorizonDays] days: `slotId * 10 + dayOffset`. The plugin's
  /// time-matching repeat always fires at the next matching time of day, so
  /// "start tomorrow" (after today's practice) was impossible with it.
  static const int dailyHorizonDays = 7;

  static const List<int> dailySlots = [evening, morning, afternoon, night];

  static List<int> dailyIds(int slotId) =>
      List.generate(dailyHorizonDays, (d) => slotId * 10 + d);

  /// Every id this app may have scheduled, including the legacy repeating
  /// ids 101-104 so an upgrade cancels an old install's alarms.
  static final List<int> all = [
    evening,
    morning,
    afternoon,
    night,
    lapseDay3,
    lapseDay7,
    lapseDay14,
    for (final id in dailySlots) ...dailyIds(id),
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

  /// Cancels everything, then arms [slots] (dated daily one-shots, from today
  /// or from [startFrom]) plus the lapse series counted from [now].
  Future<void> arm({
    required List<ReminderSlot> slots,
    required tz.TZDateTime now,
    tz.TZDateTime? startFrom,
    DateTime? lastPracticeAt,
  }) async {
    await cancelAll();
    for (final slot in slots) {
      await scheduleSlot(slot, startFrom: startFrom, now: now);
    }
    await scheduleLapseSeries(now, lastPracticeAt: lastPracticeAt);
  }

  /// Fire times for the lapse series: 3, 7 and 14 days after the last
  /// practice (or after [now] for a learner who never practised), keeping
  /// only the ones still ahead. Re-arming on launch therefore never moves
  /// them; only a new practice does.
  static Map<int, tz.TZDateTime> lapseFireTimes(
    tz.TZDateTime now, {
    DateTime? lastPracticeAt,
  }) {
    final anchor = lastPracticeAt == null
        ? now
        : tz.TZDateTime(
            tz.local,
            lastPracticeAt.year,
            lastPracticeAt.month,
            lastPracticeAt.day,
            now.hour,
            now.minute,
          );
    final result = <int, tz.TZDateTime>{};
    for (final entry in ReminderIds.lapseDays.entries) {
      final when = anchor.add(Duration(days: entry.value));
      if (when.isAfter(now)) result[entry.key] = when;
    }
    return result;
  }

  /// The dated fire times for [slot]: one per day for the next
  /// [ReminderIds.dailyHorizonDays] days, starting today if the time is
  /// still ahead, or from [startFrom] (tomorrow after today's practice).
  static List<tz.TZDateTime> dailyFireTimes(
    ReminderSlot slot,
    tz.TZDateTime now, {
    tz.TZDateTime? startFrom,
  }) {
    final first = startFrom != null
        ? tz.TZDateTime(
            tz.local,
            startFrom.year,
            startFrom.month,
            startFrom.day,
            slot.hour,
            slot.minute,
          )
        : nextInstanceOfTime(slot.hour, slot.minute, now);
    return List.generate(
      ReminderIds.dailyHorizonDays,
      (d) => first.add(Duration(days: d)),
    );
  }

  /// Arms one daily slot as dated one-shots (see [ReminderIds.dailyIds]).
  /// Re-armed on every launch and every practice, so the horizon is only a
  /// safety net for a learner who stops opening the app.
  Future<void> scheduleSlot(
    ReminderSlot slot, {
    tz.TZDateTime? startFrom,
    tz.TZDateTime? now,
  }) async {
    final times = dailyFireTimes(
      slot,
      now ?? tz.TZDateTime.now(tz.local),
      startFrom: startFrom,
    );
    final ids = ReminderIds.dailyIds(slot.id);
    for (var i = 0; i < times.length; i++) {
      await _plugin.zonedSchedule(
        id: ids[i],
        title: slot.title,
        body: slot.body,
        payload: slot.payload,
        scheduledDate: times[i],
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  /// One-shots at 3, 7 and 14 days after [from]. Re-armed on every
  /// practice, so they only ever fire for a learner who really lapsed.
  Future<void> scheduleLapseSeries(
    tz.TZDateTime now, {
    DateTime? lastPracticeAt,
  }) async {
    final times = lapseFireTimes(now, lastPracticeAt: lastPracticeAt);
    for (final entry in times.entries) {
      final copy = ReminderCopy.lapse(ReminderIds.lapseDays[entry.key]!);
      await _plugin.zonedSchedule(
        id: entry.key,
        title: copy.title,
        body: copy.body,
        payload: 'daily',
        scheduledDate: entry.value,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}
