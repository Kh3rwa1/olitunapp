import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/api/ai_service.dart';

void main() {
  group('AiConfig', () {
    test('reverseTranslateUrl defaults to translateUrl', () {
      expect(AiConfig.reverseTranslateUrl, AiConfig.translateUrl);
    });

    test('maxTranslationChars is reasonable', () {
      expect(AiConfig.maxTranslationChars, greaterThan(0));
      expect(AiConfig.maxTranslationChars, lessThanOrEqualTo(10000));
    });
  });

  group('TranslateResult', () {
    test('creates a non-error result', () {
      final result = TranslateResult(
        translation: 'hello',
        detectedLanguage: 'en',
        cached: true,
      );
      expect(result.translation, 'hello');
      expect(result.detectedLanguage, 'en');
      expect(result.cached, isTrue);
      expect(result.isError, isFalse);
    });

    test('creates an error result', () {
      final result = TranslateResult(
        translation: 'rate limited',
        isError: true,
      );
      expect(result.isError, isTrue);
      expect(result.cached, isFalse);
    });
  });

  group('unwrapAppwriteExecution', () {
    test('parses direct JSON body', () {
      const body = '{"success":true,"data":{"translation":"hello"}}';
      final parsed = AiService.unwrapAppwriteExecution(body);
      expect(parsed, isNotNull);
      expect(parsed!['success'], isTrue);
      expect((parsed['data'] as Map)['translation'], 'hello');
    });

    test('unwraps Appwrite Execution responseBody', () {
      const body =
          '{"status":"completed","responseBody":"{\\"success\\":true,\\"data\\":{\\"translation\\":\\"hi\\"}}","\$id":"exec1"}';
      final parsed = AiService.unwrapAppwriteExecution(body);
      expect(parsed, isNotNull);
      expect(parsed!['success'], isTrue);
    });

    test('returns null for non-map JSON', () {
      final parsed = AiService.unwrapAppwriteExecution('[1,2,3]');
      expect(parsed, isNull);
    });

    test('returns null for invalid JSON', () {
      final parsed = AiService.unwrapAppwriteExecution('not json');
      expect(parsed, isNull);
    });

    test('returns null for Execution with empty responseBody', () {
      const body = '{"status":"completed","responseBody":"","\$id":"exec1"}';
      final parsed = AiService.unwrapAppwriteExecution(body);
      expect(parsed, isNull);
    });
  });

  group('AiService.translate', () {
    test('rejects text exceeding maxTranslationChars', () async {
      final service = AiService();
      final longText = 'a' * (AiConfig.maxTranslationChars + 1);
      final result = await service.translate(longText);
      expect(result, isNotNull);
      expect(result!.isError, isTrue);
      expect(result.translation, contains('too long'));
    });

    test('throws StateError when URL is not configured', () async {
      final service = AiService();
      expect(
        () => service.translate('hello'),
        throwsA(isA<StateError>()),
      );
    });
  });
}
