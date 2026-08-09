import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/logging/redaction_helper.dart';

void main() {
  group('RedactionHelper Tests', () {
    test('redactEmail masks username portion', () {
      expect(RedactionHelper.redactEmail('testuser@domain.com'), 't***@domain.com');
      expect(RedactionHelper.redactEmail('a@b.com'), '***@b.com');
      expect(RedactionHelper.redactEmail(''), '');
      expect(RedactionHelper.redactEmail('invalidemail'), '[REDACTED_EMAIL]');
    });

    test('redactSecret masks middle portion', () {
      expect(RedactionHelper.redactSecret('secret12345'), 'se***45');
      expect(RedactionHelper.redactSecret('abc'), '***');
      expect(RedactionHelper.redactSecret(''), '');
    });

    test('sanitize redacts embedded emails, bearer tokens, and session secrets', () {
      const logMsg = 'User john.doe@example.com logged in with secret=a_session_998877 and Bearer token12345';
      final sanitized = RedactionHelper.sanitize(logMsg);

      expect(sanitized, isNot(contains('john.doe@example.com')));
      expect(sanitized, contains('j***@example.com'));
      expect(sanitized, isNot(contains('a_session_998877')));
      expect(sanitized, contains('Bearer [REDACTED_TOKEN]'));
    });
  });
}
