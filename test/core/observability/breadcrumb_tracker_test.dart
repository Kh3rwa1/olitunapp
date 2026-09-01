import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/observability/breadcrumb_tracker.dart';

void main() {
  group('BreadcrumbTracker Ring Buffer & Data Scrubbing Tests', () {
    late BreadcrumbTracker tracker;

    setUp(() {
      tracker = BreadcrumbTracker(maxCapacity: 5);
    });

    test('adds breadcrumbs and respects ring buffer max capacity limit', () {
      for (var i = 1; i <= 7; i++) {
        tracker.add(category: 'test', message: 'Step $i');
      }

      expect(tracker.count, equals(5));
      final recent = tracker.getRecent();
      expect(recent.first.message, equals('Step 3'));
      expect(recent.last.message, equals('Step 7'));
    });

    test('scrubs sensitive tokens, passwords, and secrets from metadata', () {
      final rawData = <String, dynamic>{
        'user_id': 'user_123',
        'auth_token': 'secret_jwt_token_here',
        'password': 'mypassword123',
        'nested': {'api_key': 'appwrite_secret_key', 'public_info': 'hello'},
      };

      final sanitized = BreadcrumbTracker.sanitizeData(rawData);

      expect(sanitized['user_id'], equals('user_123'));
      expect(sanitized['auth_token'], equals('[REDACTED]'));
      expect(sanitized['password'], equals('[REDACTED]'));
      expect(sanitized['nested']['api_key'], equals('[REDACTED]'));
      expect(sanitized['nested']['public_info'], equals('hello'));
    });

    test('clears all recorded breadcrumbs cleanly', () {
      tracker.add(category: 'ui', message: 'button tap');
      expect(tracker.count, equals(1));

      tracker.clear();
      expect(tracker.count, equals(0));
    });
  });
}
