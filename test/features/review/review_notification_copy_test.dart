// Learner-state notification copy: real numbers, honest time cost,
// no guilt, no fake urgency.

import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/notifications/notification_service.dart';
import 'package:itun/features/review/domain/memory_scheduler.dart';

void main() {
  group('NotificationCopy', () {
    test('reviewDue states count and time cost', () {
      final copy = NotificationCopy.reviewDue(dueCount: 5, minutes: 4);
      expect(copy.title, contains('5'));
      expect(copy.body, contains('5'));
      expect(copy.body, contains('4 min'));
    });

    test('reviewDue singular reads naturally', () {
      final copy = NotificationCopy.reviewDue(dueCount: 1, minutes: 1);
      expect(copy.title, '1 review ready');
      expect(copy.body, contains('1 item is'));
    });

    test('reviewStruggle names the struggle without shaming', () {
      final copy = NotificationCopy.reviewStruggle(struggleCount: 2);
      expect(copy.body, contains('2 words you found tricky'));
      expect(copy.body.toLowerCase(), isNot(contains('haven\'t')));
      expect(copy.body, isNot(contains('😢')));
    });

    test('gentleReturn never guilts', () {
      expect(
        NotificationCopy.gentleReturn.body.toLowerCase(),
        isNot(contains('haven\'t')),
      );
      expect(NotificationCopy.gentleReturn.body, contains('No rush'));
    });
  });

  group('review -> notification wiring', () {
    test('estimateMinutes feeds honest time cost for 8 due items', () {
      expect(MemoryScheduler.estimateMinutes(8), 6);
      final copy = NotificationCopy.reviewDue(
        dueCount: 8,
        minutes: MemoryScheduler.estimateMinutes(8),
      );
      expect(copy.body, contains('~6 min'));
    });
  });
}
