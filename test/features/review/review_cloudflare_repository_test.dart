import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/core/auth/edge_auth.dart';
import 'package:itun/features/review/data/review_cloudflare_repository.dart';
import 'package:itun/features/review/data/review_store.dart';
import 'package:itun/features/review/domain/review_item.dart';
import 'package:itun/features/review/domain/review_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockAccount extends Mock implements Account {}

const _states = 'https://edge.test/api/v1/review/states';
const _mutate = 'https://edge.test/api/v1/review/mutate';

void main() {
  late _MockAccount account;
  late List<http.Request> requests;
  late http.Response Function(http.Request) respond;
  late ReviewCloudflareRepository repo;
  var issued = 0;

  setUp(() {
    account = _MockAccount();
    issued = 0;
    when(
      () => account.createJWT(),
    ).thenAnswer((_) async => models.Jwt(jwt: 'jwt-${++issued}'));
    requests = [];
    respond = (_) => http.Response('{"ok":true}', 200);
    repo = ReviewCloudflareRepository(
      edgeAuth: EdgeAuth(account),
      httpClient: MockClient((req) async {
        requests.add(req);
        return respond(req);
      }),
      statesEndpoint: _states,
      mutateEndpoint: _mutate,
    );
  });

  Map<String, dynamic> bodyOf(http.Request req) =>
      jsonDecode(req.body) as Map<String, dynamic>;

  final item = MemoryItemState(
    itemId: 'word_1',
    itemType: ReviewItemType.word,
    introducedAt: DateTime.utc(2026),
    nextReviewAt: DateTime.utc(2026, 1, 4),
    lastPresentedAt: DateTime.utc(2026),
    lastReviewedAt: DateTime.utc(2026),
    successfulRecalls: 1,
    intervalDays: 3.0,
  );

  final op = ReviewRecallOperationPayload(
    operationId: 'op-1',
    userId: 'alice',
    itemId: 'word_1',
    itemType: ReviewItemType.word,
    exerciseType: ReviewExerciseType.typing,
    correct: true,
    responseTimeMs: 900,
    occurredAt: DateTime.utc(2026, 1, 3, 10),
    deviceId: 'device-a',
    localSequence: 4,
    schemaVersion: ReviewStore.schemaVersion,
  );

  group('row identity', () {
    test('matches the Worker and former Appwrite row id format', () {
      final id = ReviewCloudflareRepository.rowIdFor('user-123', 'word_456');
      expect(id, hasLength(33));
      expect(id, startsWith('r_'));
      expect(RegExp(r'^r_[0-9a-f]{31}$').hasMatch(id), isTrue);
    });

    test('distinct user/item boundaries never collide', () {
      final ids = {
        ReviewCloudflareRepository.rowIdFor('user_1', 'item_2'),
        ReviewCloudflareRepository.rowIdFor('user', '1__item_2'),
        ReviewCloudflareRepository.rowIdFor('user_1_item', '2'),
        ReviewCloudflareRepository.rowIdFor('u/1', 'item_2'),
      };
      expect(ids, hasLength(4));
    });
  });

  group('pushState', () {
    test('POSTs an upsert to the Worker with the JWT and no userId', () async {
      await repo.pushState('alice', item);

      expect(requests, hasLength(1));
      final req = requests.single;
      expect(req.method, 'POST');
      expect(req.url.toString(), _mutate);
      expect(req.headers['Authorization'], 'Bearer jwt-1');
      expect(req.headers['Content-Type'], startsWith('application/json'));
      final body = bodyOf(req);
      expect(body['action'], 'upsert');
      expect(body['itemId'], 'word_1');
      expect(body['itemType'], 'word');
      expect(body['schemaVersion'], ReviewStore.schemaVersion);
      expect(body['nextReviewAt'], item.nextReviewAt.toIso8601String());
      expect(body['lastReviewedAt'], item.lastReviewedAt!.toIso8601String());
      expect(jsonDecode(body['stateJson'] as String)['itemId'], 'word_1');
      expect(body.containsKey('userId'), isFalse);
    });

    test('throws ReviewSyncException on server failure', () async {
      respond = (_) => http.Response(
        '{"ok":false,"error":"SERVER_ERROR","message":"boom"}',
        500,
      );
      await expectLater(
        repo.pushState('alice', item),
        throwsA(
          isA<ReviewSyncException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.code, 'code', 'SERVER_ERROR'),
        ),
      );
    });

    test(
      'a 401 drops the cached JWT so the next call mints a new one',
      () async {
        respond = (_) =>
            http.Response('{"ok":false,"error":"UNAUTHENTICATED"}', 401);
        await expectLater(
          repo.pushState('alice', item),
          throwsA(isA<ReviewSyncException>()),
        );
        respond = (_) => http.Response('{"ok":true}', 200);
        await repo.pushState('alice', item);
        expect(requests.last.headers['Authorization'], 'Bearer jwt-2');
      },
    );
  });

  group('applyRecallOperation', () {
    test('POSTs applyRecall with the full operation payload', () async {
      respond = (_) => http.Response('{"ok":true,"duplicate":false}', 200);
      final applied = await repo.applyRecallOperation('alice', op);

      expect(applied, isTrue);
      final req = requests.single;
      expect(req.url.toString(), _mutate);
      expect(req.headers['Authorization'], 'Bearer jwt-1');
      final body = bodyOf(req);
      expect(body['action'], 'applyRecall');
      expect(body['operationId'], 'op-1');
      expect(body['itemId'], 'word_1');
      expect(body['itemType'], 'word');
      expect(body['exerciseType'], 'typing');
      expect(body['correct'], isTrue);
      expect(body['responseTimeMs'], 900);
      expect(body['occurredAt'], op.occurredAt.toIso8601String());
      expect(body['deviceId'], 'device-a');
      expect(body['localSequence'], 4);
      expect(body['userId'], 'alice');
    });

    test('returns false when the server reports a duplicate', () async {
      respond = (_) => http.Response('{"ok":true,"duplicate":true}', 200);
      expect(await repo.applyRecallOperation('alice', op), isFalse);
    });

    test('throws on rejection so the outbox retries', () async {
      respond = (_) =>
          http.Response('{"ok":false,"error":"FORBIDDEN","message":"no"}', 403);
      await expectLater(
        repo.applyRecallOperation('alice', op),
        throwsA(
          isA<ReviewSyncException>().having((e) => e.code, 'code', 'FORBIDDEN'),
        ),
      );
    });
  });

  group('deleteState', () {
    test('POSTs a delete for the item', () async {
      await repo.deleteState('alice', 'word_1');
      final body = bodyOf(requests.single);
      expect(body, {'action': 'delete', 'itemId': 'word_1'});
      expect(requests.single.headers['Authorization'], 'Bearer jwt-1');
    });

    test('tolerates 404', () async {
      respond = (_) => http.Response('{"ok":false}', 404);
      await repo.deleteState('alice', 'word_1');
    });

    test('throws on other failures', () async {
      respond = (_) => http.Response('{"ok":false}', 500);
      await expectLater(
        repo.deleteState('alice', 'word_1'),
        throwsA(isA<ReviewSyncException>()),
      );
    });
  });

  group('loadRemoteStates', () {
    String row(Object? stateJson) => jsonEncode({'stateJson': stateJson});

    test('GETs states with the JWT and skips malformed rows', () async {
      respond = (_) => http.Response(
        '{"ok":true,"hasMore":false,"nextCursor":null,"rows":['
        '${row(jsonEncode(item.toMap()))},'
        '${row('not json')},'
        '${row(jsonEncode([1, 2]))},'
        '${row('')},'
        '${row(42)},'
        '"not a row"'
        ']}',
        200,
      );
      final states = await repo.loadRemoteStates('alice');

      expect(states.map((s) => s.itemId), ['word_1']);
      final req = requests.single;
      expect(req.method, 'GET');
      expect(req.url.path, '/api/v1/review/states');
      expect(req.url.queryParameters['limit'], '500');
      expect(req.url.queryParameters.containsKey('userId'), isFalse);
      expect(req.headers['Authorization'], 'Bearer jwt-1');
    });

    test('follows nextCursor across pages', () async {
      final second = MemoryItemState(
        itemId: 'sentence_1',
        itemType: ReviewItemType.sentence,
        introducedAt: DateTime.utc(2026),
        nextReviewAt: DateTime.utc(2026, 1, 2),
      );
      respond = (req) {
        final cursor = req.url.queryParameters['cursor'];
        if (cursor == null) {
          return http.Response(
            '{"ok":true,"hasMore":true,"nextCursor":"r_abc",'
            '"rows":[${row(jsonEncode(item.toMap()))}]}',
            200,
          );
        }
        expect(cursor, 'r_abc');
        return http.Response(
          '{"ok":true,"hasMore":false,"nextCursor":null,'
          '"rows":[${row(jsonEncode(second.toMap()))}]}',
          200,
        );
      };
      final states = await repo.loadRemoteStates('alice');
      expect(states.map((s) => s.itemId), ['word_1', 'sentence_1']);
      expect(requests, hasLength(2));
    });

    test('throws when the Worker fails', () async {
      respond = (_) => http.Response('upstream error', 502);
      await expectLater(
        repo.loadRemoteStates('alice'),
        throwsA(
          isA<ReviewSyncException>().having((e) => e.statusCode, 'status', 502),
        ),
      );
    });
  });
}
