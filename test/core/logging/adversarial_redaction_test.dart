import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/logging/redaction_helper.dart';

void main() {
  group('Adversarial Log Redaction Suite', () {
    test('Mixed case and complex email patterns are masked cleanly', () {
      const input =
          'Contact USER.ADMIN+SECURE@DEPT.ENTERPRISE.CO.UK for details';
      final result = RedactionHelper.sanitize(input);
      expect(
        result,
        isNot(contains('USER.ADMIN+SECURE@DEPT.ENTERPRISE.CO.UK')),
      );
      expect(result, contains('U***@DEPT.ENTERPRISE.CO.UK'));
    });

    test('JWT tokens and bearer strings are redacted', () {
      const jwt =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiJ1c3JfMTIzIn0.abcdef1234567890';
      const input = 'Auth header: Bearer $jwt with token';
      final result = RedactionHelper.sanitize(input);
      expect(result, isNot(contains(jwt)));
      expect(result, contains('[REDACTED_JWT]'));
    });

    test('Plaintext passwords and API keys are redacted', () {
      const logText =
          'user: alex, password=superSecretPassword123!, apiKey=xyz987654321';
      final result = RedactionHelper.sanitize(logText);
      expect(result, isNot(contains('superSecretPassword123!')));
      expect(result, isNot(contains('xyz987654321')));
      expect(result, contains('password=[REDACTED]'));
      expect(result, contains('apiKey=[REDACTED]'));
    });

    test('Razorpay payment credentials are masked', () {
      const input =
          'Payment order rzp_live_99887766554433 created with secret key_secret=abcdef12345';
      final result = RedactionHelper.sanitize(input);
      expect(result, isNot(contains('rzp_live_99887766554433')));
      expect(result, contains('[REDACTED_PAYMENT_KEY]'));
    });

    test('IP addresses in error messages are masked', () {
      const input =
          'Connection refused from client 192.168.1.150:443 to upstream 10.0.0.1';
      final result = RedactionHelper.sanitize(input);
      expect(result, isNot(contains('192.168.1.150')));
      expect(result, isNot(contains('10.0.0.1')));
      expect(result, contains('[REDACTED_IP]'));
    });
  });
}
