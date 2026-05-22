import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/analytics/analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LearningAnalyticsService', () {
    late SharedPreferences prefs;
    var idCounter = 0;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      idCounter = 0;
    });

    String nextId() => 'event_${++idCounter}';

    test('writes sanitized learning event payloads', () async {
      final writes = <Map<String, dynamic>>[];
      final service = LearningAnalyticsService(
        prefs: prefs,
        idFactory: nextId,
        now: () => DateTime.utc(2026, 5, 22, 10, 30),
        userIdProvider: () async => 'user_123',
        remoteWriter: (_, payload) async => writes.add(payload),
      );

      await service.track(
        LearningAnalyticsEvents.lessonCompleted,
        source: 'lesson_detail',
        sourceId: 'lesson_1',
        learnerLevel: 'Beginner',
        metadata: {
          'categoryId': 'letters',
          'email': 'learner@example.com',
          'password': 'do-not-store',
          'stars': 25,
        },
      );

      expect(writes, hasLength(1));
      final payload = writes.single;
      expect(payload['eventName'], LearningAnalyticsEvents.lessonCompleted);
      expect(payload['eventId'], 'event_1');
      expect(payload['sessionId'], 'event_2');
      expect(payload['userId'], 'user_123');
      expect(payload['dateKey'], '2026-05-22');

      final metadata = jsonDecode(payload['metadata'] as String);
      expect(metadata['categoryId'], 'letters');
      expect(metadata['stars'], 25);
      expect(metadata, isNot(contains('email')));
      expect(metadata, isNot(contains('password')));
    });

    test('queues failed writes and flushes them later', () async {
      var shouldFail = true;
      final writes = <String>[];
      final service = LearningAnalyticsService(
        prefs: prefs,
        idFactory: nextId,
        now: () => DateTime.utc(2026, 5, 22),
        remoteWriter: (eventId, _) async {
          if (shouldFail) throw Exception('offline');
          writes.add(eventId);
        },
      );

      await service.track(LearningAnalyticsEvents.quizAttempted);
      expect(writes, isEmpty);

      shouldFail = false;
      await service.flushPending();
      expect(writes, ['event_1']);

      writes.clear();
      await service.flushPending();
      expect(writes, isEmpty);
    });
  });
}
