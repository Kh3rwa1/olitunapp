import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:itun/core/api/appwrite_functions_service.dart';
import 'package:itun/core/auth/edge_auth.dart';
import 'package:itun/core/config/cloudflare_config.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  group('FunctionExecutionResult', () {
    test('isCompleted is true only for completed status', () {
      expect(
        const FunctionExecutionResult(
          status: 'completed',
          statusCode: 200,
          responseBody: '{}',
        ).isCompleted,
        isTrue,
      );
      expect(
        const FunctionExecutionResult(
          status: 'failed',
          statusCode: 500,
          responseBody: '{}',
        ).isCompleted,
        isFalse,
      );
      expect(
        const FunctionExecutionResult(
          status: 'timeout',
          statusCode: 0,
          responseBody: '',
        ).isCompleted,
        isFalse,
      );
    });

    test('bodyJson parses a valid JSON object', () {
      const result = FunctionExecutionResult(
        status: 'completed',
        statusCode: 200,
        responseBody: '{"ok":true,"value":42}',
      );
      final body = result.bodyJson;
      expect(body, isNotNull);
      expect(body!['ok'], isTrue);
      expect(body['value'], 42);
    });

    test('bodyJson coerces non-String-keyed maps', () {
      const result = FunctionExecutionResult(
        status: 'completed',
        statusCode: 200,
        responseBody: '{"nested":{"a":1}}',
      );
      final body = result.bodyJson;
      expect(body, isA<Map<String, dynamic>>());
      expect(body!['nested'], isA<Map<String, dynamic>>());
    });

    test('bodyJson returns null for an empty body', () {
      const result = FunctionExecutionResult(
        status: 'completed',
        statusCode: 200,
        responseBody: '',
      );
      expect(result.bodyJson, isNull);
    });

    test('bodyJson returns null for malformed JSON and does not throw', () {
      const result = FunctionExecutionResult(
        status: 'completed',
        statusCode: 200,
        responseBody: '{"ok": true,',
      );
      expect(result.bodyJson, isNull);
    });

    test('bodyJson returns null for non-object payloads', () {
      const list = FunctionExecutionResult(
        status: 'completed',
        statusCode: 200,
        responseBody: '[1,2,3]',
      );
      expect(list.bodyJson, isNull);

      const scalar = FunctionExecutionResult(
        status: 'completed',
        statusCode: 200,
        responseBody: '"just a string"',
      );
      expect(scalar.bodyJson, isNull);
    });

    test('carries the HTTP status code of the execution', () {
      final result = FunctionExecutionResult(
        status: 'completed',
        statusCode: 201,
        responseBody: jsonEncode({'created': true}),
      );
      expect(result.statusCode, 201);
      expect(result.bodyJson!['created'], isTrue);
    });
  });

  group('AppwriteFunctionsService (Worker only)', () {
    late MockHttpClient mockHttp;
    late MockAccount mockAccount;
    late AppwriteFunctionsService service;
    var jwtCount = 0;

    setUpAll(() {
      registerFallbackValue(Uri.parse('https://example.com'));
    });

    setUp(() {
      mockHttp = MockHttpClient();
      mockAccount = MockAccount();
      jwtCount = 0;
      when(
        mockAccount.createJWT,
      ).thenAnswer((_) async => models.Jwt(jwt: 'session-jwt-${++jwtCount}'));
      service = AppwriteFunctionsService(
        httpClient: mockHttp,
        edgeAuth: EdgeAuth(mockAccount),
      );
    });

    void stubPost(Future<http.Response> Function() answer) {
      when(
        () => mockHttp.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) => answer());
    }

    test('posts to the mapped Worker route with a bearer JWT', () async {
      stubPost(() async => http.Response(jsonEncode({'ok': true}), 200));

      final result = await service.execute(
        'recordMistake',
        body: {'itemId': 'a'},
      );

      expect(result.isCompleted, isTrue);
      final captured = verify(
        () => mockHttp.post(
          Uri.parse(CloudflareConfig.mistakesRecordEndpoint),
          headers: captureAny(named: 'headers'),
          body: captureAny(named: 'body'),
        ),
      ).captured;
      final headers = captured[0] as Map<String, String>;
      expect(headers['Authorization'], 'Bearer session-jwt-1');
      expect(headers.containsKey('x-appwrite-user-id'), isFalse);
      expect(jsonDecode(captured[1] as String), {'itemId': 'a'});
    });

    test('uses GET for an empty getUserMistakes call', () async {
      when(
        () => mockHttp.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('{"ok":true}', 200));

      final result = await service.execute('getUserMistakes');

      expect(result.isCompleted, isTrue);
      verify(
        () => mockHttp.get(
          Uri.parse(CloudflareConfig.mistakesEndpoint),
          headers: any(named: 'headers'),
        ),
      ).called(1);
    });

    test('retries once with a fresh JWT after a 401', () async {
      final statuses = [401, 200];
      stubPost(() async => http.Response('{}', statuses.removeAt(0)));

      final result = await service.execute('recordMistake', usePost: true);

      expect(result.statusCode, 200);
      final headers = verify(
        () => mockHttp.post(
          any(),
          headers: captureAny(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).captured.cast<Map<String, String>>();
      expect(headers.map((h) => h['Authorization']), [
        'Bearer session-jwt-1',
        'Bearer session-jwt-2',
      ]);
    });

    test('returns Worker errors as failed results', () async {
      stubPost(() async => http.Response('{"ok":false}', 503));

      final result = await service.execute('recordMistake', usePost: true);

      expect(result.isCompleted, isFalse);
      expect(result.statusCode, 503);
    });

    test('network failure is a failed result, not an exception', () async {
      stubPost(() async => throw Exception('offline'));

      final result = await service.execute('recordMistake', usePost: true);

      expect(result.isCompleted, isFalse);
      expect(result.statusCode, 0);
    });

    test('an unmapped function never leaves the device', () async {
      final result = await service.execute('customUnmappedFunction');

      expect(result.statusCode, 501);
      verifyNever(
        () => mockHttp.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      );
    });

    for (final entry in {
      'createRazorpayOrder': CloudflareConfig.paymentsOrderEndpoint,
      'verifyCoursePurchase': CloudflareConfig.paymentsVerifyEndpoint,
    }.entries) {
      test('${entry.key} runs on the Worker', () async {
        stubPost(() async => http.Response('{"ok":true}', 200));

        await service.execute(entry.key, body: {'x': 1}, usePost: true);

        verify(
          () => mockHttp.post(
            Uri.parse(entry.value),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).called(1);
      });
    }
  });
}

class MockHttpClient extends Mock implements http.Client {}

class MockAccount extends Mock implements Account {}
