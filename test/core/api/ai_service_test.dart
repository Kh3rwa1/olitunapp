import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/api/ai_service.dart';

void main() {
  group('AiService config', () {
    test('throws StateError when TRANSLATE_URL is not configured', () async {
      // The dart-define is empty in the test environment, so calling
      // translate must surface the misconfiguration loudly rather than
      // silently falling back to a hardcoded host.
      final svc = AiService();
      expect(() => svc.translate('hello'), throwsA(isA<StateError>()));
    });

    test(
      'rejects oversized requests before network configuration is used',
      () async {
        final svc = AiService();
        final result = await svc.translate(
          'x' * (AiConfig.maxTranslationChars + 1),
        );

        expect(result, isNotNull);
        expect(result!.isError, isTrue);
        expect(result.translation, contains('${AiConfig.maxTranslationChars}'));
      },
    );
  });

  group('AiService Appwrite Execution unwrap', () {
    test('returns the body as-is when it is already a function response', () {
      final body = jsonEncode({
        'success': true,
        'data': {'translation': 'hi'},
      });
      final out = AiService.unwrapAppwriteExecution(body);
      expect(out!['success'], isTrue);
      expect((out['data'] as Map)['translation'], 'hi');
    });

    test('unwraps an Appwrite Execution object to its inner responseBody', () {
      final inner = jsonEncode({
        'success': true,
        'data': {'translation': 'ᱚᱞ', 'cached': false},
      });
      final execution = jsonEncode({
        '\$id': 'exec_1',
        'status': 'completed',
        'responseStatusCode': 200,
        'responseBody': inner,
      });
      final out = AiService.unwrapAppwriteExecution(execution);
      expect(out!['success'], isTrue);
      expect((out['data'] as Map)['translation'], 'ᱚᱞ');
    });

    test('returns null on malformed JSON', () {
      expect(AiService.unwrapAppwriteExecution('not json'), isNull);
    });

    test('returns null when execution wrapper has empty responseBody', () {
      final execution = jsonEncode({
        '\$id': 'exec_2',
        'status': 'completed',
        'responseBody': '',
      });
      expect(AiService.unwrapAppwriteExecution(execution), isNull);
    });
  });
}
