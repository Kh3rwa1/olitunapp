import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../error/failures.dart';

/// Thin wrapper around Sentry so the rest of the codebase doesn't depend on
/// the SDK directly. If `SENTRY_DSN` is not provided at build time, the
/// init/recording calls become no-ops (still safe to call).
///
/// Configure via:
///   --dart-define=SENTRY_DSN=[your-dsn]
///   --dart-define=SENTRY_ENV=production|staging|development
class CrashReporting {
  CrashReporting._();

  static const String _dsn = String.fromEnvironment('SENTRY_DSN');
  static const String _environment = String.fromEnvironment(
    'SENTRY_ENV',
    defaultValue: 'development',
  );

  static bool get isEnabled => _dsn.isNotEmpty && !kDebugMode;

  static Future<void> init() async {
    if (!isEnabled) {
      debugPrint('CrashReporting: disabled (no DSN or running in debug).');
      return;
    }
    await SentryFlutter.init((options) {
      options.dsn = _dsn;
      options.environment = _environment;
      options.tracesSampleRate = 0.1;
      options.attachStacktrace = true;
    });
  }

  static void recordError(Object error, StackTrace? stack) {
    if (!isEnabled) return;
    Sentry.captureException(error, stackTrace: stack);
  }

  static void recordFlutterError(FlutterErrorDetails details) {
    if (!isEnabled) return;
    Sentry.captureException(details.exception, stackTrace: details.stack);
  }

  /// Record a domain-layer [Failure] returned from a repository. Network and
  /// validation failures are intentionally skipped — they are user-facing
  /// expected outcomes, not bugs. Server/auth/cache failures are reported.
  static void recordFailure(Failure failure, [StackTrace? stack]) {
    if (!isEnabled) return;
    if (failure is NetworkFailure || failure is ValidationFailure) return;
    Sentry.captureMessage(
      '${failure.runtimeType}: ${failure.message}'
      '${failure.code != null ? ' (code ${failure.code})' : ''}',
      level: SentryLevel.error,
    );
  }
}
