import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/core/analytics/analytics_service.dart';
import 'package:itun/core/auth/edge_auth.dart';
import 'package:itun/core/config/cloudflare_config.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Account extends Mock implements Account {}

class _Jwt extends Mock implements models.Jwt {}

EdgeAuth _edgeAuth({String? jwt}) {
  final account = _Account();
  if (jwt == null) {
    when(account.createJWT).thenThrow(AppwriteException('guest'));
  } else {
    final token = _Jwt();
    when(() => token.jwt).thenReturn(jwt);
    when(account.createJWT).thenAnswer((_) async => token);
  }
  return EdgeAuth(account);
}

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

  group('LearningAnalyticsService.edge', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('posts a batch to the Worker with the session JWT', () async {
      final sent = <http.Request>[];
      final service = LearningAnalyticsService.edge(
        prefs: prefs,
        edgeAuth: _edgeAuth(jwt: 'jwt-1'),
        httpClient: MockClient((req) async {
          sent.add(req);
          return http.Response('{"ok":true,"accepted":1}', 200);
        }),
      );

      await service.track(LearningAnalyticsEvents.lessonStarted);

      expect(sent, hasLength(1));
      expect(
        sent.single.url.toString(),
        CloudflareConfig.analyticsEventsEndpoint,
      );
      expect(sent.single.headers['Authorization'], 'Bearer jwt-1');
      final body = jsonDecode(sent.single.body) as Map<String, dynamic>;
      final events = body['events'] as List;
      expect(events, hasLength(1));
      expect(events.single['eventName'], LearningAnalyticsEvents.lessonStarted);
      // Identity comes from the JWT on the server, never the payload.
      expect(events.single, isNot(contains('userId')));
    });

    test('guests post without Authorization', () async {
      http.Request? sent;
      final service = LearningAnalyticsService.edge(
        prefs: prefs,
        edgeAuth: _edgeAuth(),
        httpClient: MockClient((req) async {
          sent = req;
          return http.Response('{"ok":true,"accepted":1}', 200);
        }),
      );
      await service.track(LearningAnalyticsEvents.lessonStarted);
      expect(sent, isNotNull);
      expect(sent!.headers.containsKey('Authorization'), isFalse);
    });

    test(
      'server errors queue the event; rejected events are dropped',
      () async {
        var status = 503;
        var calls = 0;
        final service = LearningAnalyticsService.edge(
          prefs: prefs,
          edgeAuth: _edgeAuth(),
          httpClient: MockClient((_) async {
            calls++;
            return http.Response('{"ok":false}', status);
          }),
        );

        await service.track(LearningAnalyticsEvents.quizAttempted);
        expect(
          prefs.getString('pending_learning_analytics_events_v1'),
          isNotNull,
        );

        status = 400;
        await service.flushPending();
        expect(prefs.getString('pending_learning_analytics_events_v1'), isNull);
        expect(calls, 2);
      },
    );
  });
}
