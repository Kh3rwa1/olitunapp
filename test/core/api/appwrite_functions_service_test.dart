import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/api/appwrite_functions_service.dart';

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
}
