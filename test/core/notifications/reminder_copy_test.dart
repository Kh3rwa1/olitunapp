import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/notifications/notification_service.dart';
import 'package:itun/core/notifications/reminder_scheduler.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
  });
  _schedulerHorizonTests();
  _lapseAnchorTests();
  group('ReminderCopy', () {
    test('evening copy never mentions a streak when there is none', () {
      final copy = ReminderCopy.evening(ReminderContext.empty);
      expect(copy.title.toLowerCase(), isNot(contains('streak')));
      expect(copy.body.toLowerCase(), isNot(contains('streak')));
      expect(copy.title, contains('word'));
    });

    test('evening copy states the real streak', () {
      final copy = ReminderCopy.evening(const ReminderContext(streak: 6));
      expect(copy.title, contains('6-day streak'));
    });

    test('evening copy counts due reviews with correct plural', () {
      expect(
        ReminderCopy.evening(const ReminderContext(dueReviews: 1)).title,
        '1 review ready',
      );
      expect(
        ReminderCopy.evening(const ReminderContext(dueReviews: 4)).title,
        '4 reviews ready',
      );
      expect(
        ReminderCopy.evening(
          const ReminderContext(streak: 2, dueReviews: 4),
        ).body,
        contains('4 reviews'),
      );
    });

    test('morning copy mentions reviews only when due', () {
      expect(
        ReminderCopy.morning(ReminderContext.empty).title,
        isNot(contains('review')),
      );
      expect(
        ReminderCopy.morning(const ReminderContext(dueReviews: 3)).title,
        contains('3 reviews'),
      );
    });

    test('afternoon copy frames the next streak day when a streak exists', () {
      expect(
        ReminderCopy.afternoon(const ReminderContext(streak: 4)).body,
        contains('day 5'),
      );
      expect(
        ReminderCopy.afternoon(ReminderContext.empty).body,
        isNot(contains('day ')),
      );
    });

    test('night copy uses singular and plural days', () {
      expect(
        ReminderCopy.night(const ReminderContext(streak: 1)).title,
        contains('1 day streak'),
      );
      expect(
        ReminderCopy.night(const ReminderContext(streak: 12)).title,
        contains('12 days streak'),
      );
    });

    test('lapse copy is distinct for day 3, 7 and 14', () {
      final titles = {3, 7, 14}.map((d) => ReminderCopy.lapse(d).title);
      expect(titles.toSet().length, 3);
      for (final d in [3, 7, 14]) {
        final copy = ReminderCopy.lapse(d);
        expect(copy.title, isNotEmpty);
        expect(copy.body, isNotEmpty);
        expect(copy.body.toLowerCase(), isNot(contains('miss you')));
      }
    });

    test('payload is review when reviews are due, otherwise daily', () {
      expect(ReminderCopy.payloadFor(ReminderContext.empty), 'daily');
      expect(
        ReminderCopy.payloadFor(const ReminderContext(dueReviews: 2)),
        'review',
      );
    });
  });

  group('buildDailySlots', () {
    List<ReminderSlot> slots(
      NotificationFrequency f, {
      ReminderContext ctx = ReminderContext.empty,
      int hour = 20,
      int minute = 0,
    }) =>
        buildDailySlots(frequency: f, hour: hour, minute: minute, context: ctx);

    test('once → one slot at the chosen time', () {
      final s = slots(NotificationFrequency.once, hour: 19, minute: 30);
      expect(s.map((e) => e.id), [ReminderIds.evening]);
      expect(s.single.hour, 19);
      expect(s.single.minute, 30);
    });

    test('balanced → evening + 09:00 morning', () {
      final s = slots(NotificationFrequency.balanced);
      expect(s.map((e) => e.id), [ReminderIds.evening, ReminderIds.morning]);
      expect(s[1].hour, 9);
    });

    test('high without a streak has no night streak saver', () {
      final s = slots(NotificationFrequency.high);
      expect(s.map((e) => e.id), [
        ReminderIds.evening,
        ReminderIds.morning,
        ReminderIds.afternoon,
      ]);
    });

    test('high with a streak adds the night saver at 21:45', () {
      final s = slots(
        NotificationFrequency.high,
        ctx: const ReminderContext(streak: 3),
      );
      final night = s.singleWhere((e) => e.id == ReminderIds.night);
      expect((night.hour, night.minute), (21, 45));
      expect(night.title, contains('3 days streak'));
    });

    test('night saver moves to 22:30 when the main slot is after 21:30', () {
      final s = slots(
        NotificationFrequency.high,
        ctx: const ReminderContext(streak: 3),
        hour: 21,
        minute: 45,
      );
      final night = s.singleWhere((e) => e.id == ReminderIds.night);
      expect((night.hour, night.minute), (22, 30));
    });

    test(
      'evening and morning carry the review payload when reviews are due',
      () {
        final s = slots(
          NotificationFrequency.balanced,
          ctx: const ReminderContext(dueReviews: 2),
        );
        expect(s.every((e) => e.payload == 'review'), isTrue);
      },
    );
  });

  group('ReminderPolicy', () {
    test('parseFrequency defaults to once for missing or unknown names', () {
      expect(ReminderPolicy.parseFrequency(null), NotificationFrequency.once);
      expect(ReminderPolicy.parseFrequency(''), NotificationFrequency.once);
      expect(
        ReminderPolicy.parseFrequency('weekly'),
        NotificationFrequency.once,
      );
      expect(ReminderPolicy.parseFrequency('high'), NotificationFrequency.high);
      expect(
        ReminderPolicy.parseFrequency('balanced'),
        NotificationFrequency.balanced,
      );
    });

    test(
      'practicedTodayFromPrefs reads any mission flag for today (UTC)',
      () async {
        final now = DateTime.utc(2026, 11, 10, 15);
        SharedPreferences.setMockInitialValues({
          'mission_quiz_taken_date': '2026-11-10',
        });
        var prefs = await SharedPreferences.getInstance();
        expect(ReminderPolicy.practicedTodayFromPrefs(prefs, now: now), isTrue);

        SharedPreferences.setMockInitialValues({
          'mission_lesson_completed_date': '2026-11-09',
        });
        prefs = await SharedPreferences.getInstance();
        expect(
          ReminderPolicy.practicedTodayFromPrefs(prefs, now: now),
          isFalse,
        );

        SharedPreferences.setMockInitialValues({});
        prefs = await SharedPreferences.getInstance();
        expect(
          ReminderPolicy.practicedTodayFromPrefs(prefs, now: now),
          isFalse,
        );
      },
    );

    test('ReminderContext equality and copyWith', () {
      const a = ReminderContext(streak: 2, dueReviews: 1);
      expect(a, const ReminderContext(streak: 2, dueReviews: 1));
      expect(
        a.hashCode,
        const ReminderContext(streak: 2, dueReviews: 1).hashCode,
      );
      expect(a.copyWith(practicedToday: true).practicedToday, isTrue);
      expect(a.copyWith(streak: 5).streak, 5);
      expect(a.toString(), contains('streak: 2'));
    });
  });
}

void _schedulerHorizonTests() {
  group('ReminderScheduler.dailyFireTimes', () {
    const slot = ReminderSlot(
      id: ReminderIds.evening,
      hour: 20,
      minute: 0,
      title: 't',
      body: 'b',
      payload: 'daily',
    );

    test('starts today when the time is still ahead', () {
      final now = tz.TZDateTime(tz.local, 2026, 11, 10, 7, 49);
      final times = ReminderScheduler.dailyFireTimes(slot, now);
      expect(times.length, ReminderIds.dailyHorizonDays);
      expect(times.first, tz.TZDateTime(tz.local, 2026, 11, 10, 20));
      expect(times[1], tz.TZDateTime(tz.local, 2026, 11, 11, 20));
    });

    test('skips today after practice (startFrom tomorrow)', () {
      final now = tz.TZDateTime(tz.local, 2026, 11, 10, 7, 49);
      final times = ReminderScheduler.dailyFireTimes(
        slot,
        now,
        startFrom: now.add(const Duration(days: 1)),
      );
      expect(times.first, tz.TZDateTime(tz.local, 2026, 11, 11, 20));
      expect(times.every((t) => t.day != 10 || t.month != 11), isTrue);
    });

    test('ids are unique per slot and day and all are cancellable', () {
      final ids = ReminderIds.dailyIds(ReminderIds.evening);
      expect(ids, [1010, 1011, 1012, 1013, 1014, 1015, 1016]);
      expect(ReminderIds.all.toSet().length, ReminderIds.all.length);
      expect(ReminderIds.all, containsAll(ids));
      expect(ReminderIds.all, containsAll([101, 105, 106, 107]));
    });
  });
}

void _lapseAnchorTests() {
  group('ReminderScheduler.lapseFireTimes', () {
    tz.TZDateTime now() => tz.TZDateTime(tz.local, 2026, 11, 10, 9);

    test('never practised: counts from now', () {
      final t = ReminderScheduler.lapseFireTimes(now());
      expect(t.keys, containsAll([105, 106, 107]));
      expect(t[105], tz.TZDateTime(tz.local, 2026, 11, 13, 9));
    });

    test('anchored to the last practice, past dates dropped', () {
      final t = ReminderScheduler.lapseFireTimes(
        now(),
        lastPracticeAt: DateTime(2026, 11, 5),
      );
      // Day 3 (Nov 8) is already past; day 7 (Nov 12) and 14 (Nov 19) remain.
      expect(t.containsKey(105), isFalse);
      expect(t[106], tz.TZDateTime(tz.local, 2026, 11, 12, 9));
      expect(t[107], tz.TZDateTime(tz.local, 2026, 11, 19, 9));
    });

    test('relaunching without practice does not move the series', () {
      final a = ReminderScheduler.lapseFireTimes(
        now(),
        lastPracticeAt: DateTime(2026, 11, 9),
      );
      final b = ReminderScheduler.lapseFireTimes(
        now().add(const Duration(hours: 6)),
        lastPracticeAt: DateTime(2026, 11, 9),
      );
      expect(a[105]!.day, b[105]!.day);
    });
  });

  test('lastPracticeFromPrefs picks the latest practice flag', () async {
    SharedPreferences.setMockInitialValues({
      'mission_lesson_completed_date': '2026-11-03',
      'mission_quiz_taken_date': '2026-11-08',
    });
    final prefs = await SharedPreferences.getInstance();
    expect(ReminderPolicy.lastPracticeFromPrefs(prefs), DateTime(2026, 11, 8));
    SharedPreferences.setMockInitialValues({});
    final empty = await SharedPreferences.getInstance();
    expect(ReminderPolicy.lastPracticeFromPrefs(empty), isNull);
  });
}
