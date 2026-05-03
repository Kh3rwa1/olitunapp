import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/core/observability/crash_reporting.dart';

void main() {
  group('CrashReporting', () {
    test('is disabled in debug / when DSN is empty', () {
      // Tests run with kDebugMode == true and no SENTRY_DSN dart-define,
      // so isEnabled must be false and no recording call may throw.
      expect(CrashReporting.isEnabled, isFalse);
      expect(
        () => CrashReporting.recordError(Exception('x'), StackTrace.current),
        returnsNormally,
      );
      expect(
        () => CrashReporting.recordFailure(
          const ServerFailure(message: 'boom', code: 500),
        ),
        returnsNormally,
      );
    });

    test('recordFailure tolerates NetworkFailure and ValidationFailure', () {
      // These failure types are user-facing expected outcomes, never sent.
      expect(
        () => CrashReporting.recordFailure(const NetworkFailure()),
        returnsNormally,
      );
      expect(
        () => CrashReporting.recordFailure(
          const ValidationFailure(message: 'bad'),
        ),
        returnsNormally,
      );
    });
  });
}
