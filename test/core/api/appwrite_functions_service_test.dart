import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:itun/core/api/appwrite_functions_service.dart';
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

  group('AppwriteFunctionsService.execute', () {
    late MockClient mockClient;
    late MockFunctions mockFunctions;
    late MockHttpClient mockHttp;
    late AppwriteFunctionsService service;

    setUpAll(() {
      registerFallbackValue(ExecutionMethod.gET);
      registerFallbackValue(Uri.parse('https://example.com'));
    });

    setUp(() {
      mockClient = MockClient();
      mockFunctions = MockFunctions();
      mockHttp = MockHttpClient();
      service = AppwriteFunctionsService(
        mockClient,
        httpClient: mockHttp,
        functions: mockFunctions,
      );
    });

    test(
      'dispatches to Cloudflare Worker edge API when endpoint exists',
      () async {
        when(
          () => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async =>
              http.Response(jsonEncode({'ok': true, 'streak': 5}), 200),
        );

        final result = await service.execute(
          'getUserGamificationSummary',
          body: {'userId': 'user_123'},
        );

        expect(result.isCompleted, isTrue);
        expect(result.statusCode, 200);
        expect(result.bodyJson!['ok'], isTrue);
        expect(result.bodyJson!['streak'], 5);

        verify(
          () => mockHttp.post(
            Uri.parse(CloudflareConfig.gamificationSummaryEndpoint),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).called(1);
        verifyNever(
          () => mockFunctions.createExecution(
            functionId: any(named: 'functionId'),
            body: any(named: 'body'),
            xasync: any(named: 'xasync'),
            method: any(named: 'method'),
          ),
        );
      },
    );

    test(
      'falls back to Appwrite Functions if Cloudflare Worker fails with network exception',
      () async {
        when(
          () => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenThrow(Exception('Edge connection timed out'));

        final mockExecution = MockExecution();
        when(() => mockExecution.status).thenReturn(ExecutionStatus.completed);
        when(() => mockExecution.responseStatusCode).thenReturn(200);
        when(
          () => mockExecution.responseBody,
        ).thenReturn('{"fromAppwrite":true}');

        when(
          () => mockFunctions.createExecution(
            functionId: any(named: 'functionId'),
            body: any(named: 'body'),
            xasync: any(named: 'xasync'),
            method: any(named: 'method'),
          ),
        ).thenAnswer((_) async => mockExecution);

        final result = await service.execute(
          'getUserGamificationSummary',
          body: {'userId': 'user_123'},
        );

        expect(result.isCompleted, isTrue);
        expect(result.statusCode, 200);
        expect(result.bodyJson!['fromAppwrite'], isTrue);

        verify(
          () => mockFunctions.createExecution(
            functionId: 'getUserGamificationSummary',
            body: any(named: 'body'),
            xasync: false,
            method: any(named: 'method'),
          ),
        ).called(1);
      },
    );

    test(
      'falls back to Appwrite Functions if Cloudflare Worker returns 500 error',
      () async {
        when(
          () => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => http.Response('Server Error', 500));

        final mockExecution = MockExecution();
        when(() => mockExecution.status).thenReturn(ExecutionStatus.completed);
        when(() => mockExecution.responseStatusCode).thenReturn(200);
        when(() => mockExecution.responseBody).thenReturn('{"fallback":true}');

        when(
          () => mockFunctions.createExecution(
            functionId: any(named: 'functionId'),
            body: any(named: 'body'),
            xasync: any(named: 'xasync'),
            method: any(named: 'method'),
          ),
        ).thenAnswer((_) async => mockExecution);

        final result = await service.execute(
          'recordMistake',
          body: {'userId': 'user_123'},
        );

        expect(result.isCompleted, isTrue);
        expect(result.bodyJson!['fallback'], isTrue);
        verify(
          () => mockFunctions.createExecution(
            functionId: 'recordMistake',
            body: any(named: 'body'),
            xasync: false,
            method: any(named: 'method'),
          ),
        ).called(1);
      },
    );

    test(
      'calls Appwrite Functions directly if functionId has no Cloudflare mapping',
      () async {
        final mockExecution = MockExecution();
        when(() => mockExecution.status).thenReturn(ExecutionStatus.completed);
        when(() => mockExecution.responseStatusCode).thenReturn(200);
        when(() => mockExecution.responseBody).thenReturn('{"unmapped":true}');

        when(
          () => mockFunctions.createExecution(
            functionId: any(named: 'functionId'),
            body: any(named: 'body'),
            xasync: any(named: 'xasync'),
            method: any(named: 'method'),
          ),
        ).thenAnswer((_) async => mockExecution);

        final result = await service.execute(
          'customUnmappedFunction',
          body: {},
        );

        expect(result.isCompleted, isTrue);
        expect(result.bodyJson!['unmapped'], isTrue);
        verifyNever(
          () => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        );
        verify(
          () => mockFunctions.createExecution(
            functionId: 'customUnmappedFunction',
            body: '{}',
            xasync: false,
            method: ExecutionMethod.gET,
          ),
        ).called(1);
      },
    );
  });
}

class MockClient extends Mock implements Client {}

class MockFunctions extends Mock implements Functions {}

class MockExecution extends Mock implements models.Execution {}

class MockHttpClient extends Mock implements http.Client {}
