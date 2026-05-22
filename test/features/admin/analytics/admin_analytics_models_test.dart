import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/presentation/analytics/admin_analytics_models.dart';

void main() {
  group('AdminAnalyticsSnapshot', () {
    test('builds DAU WAU MAU and rollup charts from rows', () {
      final snapshot = AdminAnalyticsSnapshot.fromRows(
        now: DateTime.utc(2026, 5, 22),
        rollups: [
          {
            'dateKey': '2026-05-22',
            'eventName': 'lesson_completed',
            'totalEvents': 5,
            'uniqueUsers': 2,
            'platformBreakdown': '{"android":3,"web":2}',
            'sourceBreakdown': '{"lesson_detail":5}',
          },
          {
            'dateKey': '2026-05-22',
            'eventName': 'quiz_completed',
            'totalEvents': 2,
            'uniqueUsers': 1,
            'platformBreakdown': '{"android":2}',
            'sourceBreakdown': '{"quiz_screen":2}',
          },
        ],
        events: [
          {
            'dateKey': '2026-05-22',
            'eventName': 'lesson_completed',
            'userId': 'u1',
            'sessionId': 's1',
          },
          {
            'dateKey': '2026-05-20',
            'eventName': 'quiz_completed',
            'userId': 'u2',
            'sessionId': 's2',
          },
          {
            'dateKey': '2026-04-29',
            'eventName': 'lesson_started',
            'sessionId': 'guest',
          },
        ],
      );

      expect(snapshot.dau, 1);
      expect(snapshot.wau, 2);
      expect(snapshot.mau, 3);
      expect(snapshot.eventTotals['lesson_completed'], 5);
      expect(snapshot.platformTotals['android'], 5);
      expect(snapshot.eventSourceTotals['quiz_completed / quiz_screen'], 2);
    });

    test('falls back to raw events when rollups are not available yet', () {
      final snapshot = AdminAnalyticsSnapshot.fromRows(
        now: DateTime.utc(2026, 5, 22),
        rollups: const [],
        events: const [
          {
            'dateKey': '2026-05-22',
            'eventName': 'streak_milestone',
            'source': 'profile',
            'platform': 'android',
            'userId': 'u1',
          },
        ],
      );

      expect(snapshot.dau, 1);
      expect(snapshot.eventTotals, {'streak_milestone': 1});
      expect(snapshot.sourceTotals, {'profile': 1});
      expect(snapshot.platformTotals, {'android': 1});
    });

    test('uses rollup unique users when raw event reads are restricted', () {
      final snapshot = AdminAnalyticsSnapshot.fromRows(
        now: DateTime.utc(2026, 5, 22),
        rollups: const [
          {
            'dateKey': '2026-05-21',
            'eventName': 'lesson_completed',
            'totalEvents': 9,
            'uniqueUsers': 4,
          },
          {
            'dateKey': '2026-05-21',
            'eventName': 'quiz_completed',
            'totalEvents': 5,
            'uniqueUsers': 2,
          },
          {
            'dateKey': '2026-05-18',
            'eventName': 'lesson_started',
            'totalEvents': 3,
            'uniqueUsers': 3,
          },
        ],
        events: const [],
      );

      expect(snapshot.dau, 4);
      expect(snapshot.wau, 7);
      expect(snapshot.mau, 7);
      expect(snapshot.dailyActiveUsers[DateTime.utc(2026, 5, 21)], 4);
    });
  });

  group('retention cohorts', () {
    test('calculates weekly cohort retention from raw events', () {
      final cohorts = buildRetentionCohorts(const [
        {'dateKey': '2026-05-04', 'userId': 'u1'},
        {'dateKey': '2026-05-05', 'userId': 'u2'},
        {'dateKey': '2026-05-11', 'userId': 'u1'},
        {'dateKey': '2026-05-18', 'userId': 'u1'},
        {'dateKey': '2026-05-18', 'userId': 'u2'},
      ], now: DateTime.utc(2026, 5, 22));

      final first = cohorts.last;
      expect(formatDateKey(first.weekStart), '2026-05-04');
      expect(first.size, 2);
      expect(first.weekRetention.take(3).toList(), [1, 0.5, 1]);
    });
  });

  group('parseBreakdown', () {
    test('ignores malformed JSON and empty keys', () {
      expect(parseBreakdown('{bad json'), isEmpty);
      expect(parseBreakdown({'android': 2, '': 4, 'web': '3'}), {
        'web': 3,
        'android': 2,
      });
    });
  });
}
