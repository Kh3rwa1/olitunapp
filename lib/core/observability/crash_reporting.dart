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

  // ─── Breadcrumbs ────────────────────────────────────────

  /// Add a navigation breadcrumb (e.g. screen transitions).
  static void addNavigationBreadcrumb(String from, String to) {
    if (!isEnabled) return;
    Sentry.addBreadcrumb(
      Breadcrumb(
        type: 'navigation',
        category: 'navigation',
        data: {'from': from, 'to': to},
      ),
    );
  }

  /// Record an Appwrite API call result as a breadcrumb.
  ///
  /// On success, records collection/operation for tracing context.
  /// On failure, adds the error message for faster root-cause analysis.
  static void addAppwriteBreadcrumb({
    required String operation,
    required String collection,
    String? documentId,
    bool success = true,
    String? error,
    int? statusCode,
  }) {
    if (!isEnabled) {
      debugPrint(
        '[Breadcrumb] Appwrite $operation on $collection'
        '${documentId != null ? '/$documentId' : ''}'
        ' → ${success ? 'OK' : 'FAIL: $error'}',
      );
      return;
    }
    Sentry.addBreadcrumb(
      Breadcrumb(
        type: 'http',
        category: 'appwrite.$operation',
        message:
            '$operation $collection${documentId != null ? '/$documentId' : ''}',
        level: success ? SentryLevel.info : SentryLevel.error,
        data: {
          'collection': collection,
          if (documentId != null) 'documentId': documentId,
          'success': success,
          if (error != null) 'error': error,
          if (statusCode != null) 'statusCode': statusCode,
        },
      ),
    );
  }

  /// Record an admin write action (create/update/delete) as a breadcrumb
  /// for auditing and debugging admin mutations.
  static void addAdminWriteBreadcrumb({
    required String action,
    required String entity,
    String? entityId,
    Map<String, dynamic>? metadata,
  }) {
    if (!isEnabled) {
      debugPrint(
        '[Breadcrumb] Admin $action $entity'
        '${entityId != null ? ' ($entityId)' : ''}',
      );
      return;
    }
    Sentry.addBreadcrumb(
      Breadcrumb(
        type: 'user',
        category: 'admin.$action',
        message: '$action $entity${entityId != null ? ' ($entityId)' : ''}',
        level: SentryLevel.info,
        data: {
          'entity': entity,
          'entityId': ?entityId,
          if (metadata != null) ...metadata,
        },
      ),
    );
  }

  /// Record an upload attempt breadcrumb.
  static void addUploadBreadcrumb({
    required String filename,
    required String bucket,
    bool success = true,
    String? error,
    int? sizeBytes,
  }) {
    if (!isEnabled) {
      debugPrint(
        '[Breadcrumb] Upload $filename → $bucket ${success ? 'OK' : 'FAIL: $error'}',
      );
      return;
    }
    Sentry.addBreadcrumb(
      Breadcrumb(
        type: 'http',
        category: 'upload',
        message: 'Upload $filename → $bucket',
        level: success ? SentryLevel.info : SentryLevel.error,
        data: {
          'filename': filename,
          'bucket': bucket,
          'success': success,
          'sizeBytes': ?sizeBytes,
          'error': ?error,
        },
      ),
    );
  }

  /// Record a cache operation breadcrumb.
  static void addCacheBreadcrumb({
    required String operation,
    required String key,
    bool hit = true,
  }) {
    if (!isEnabled) return;
    Sentry.addBreadcrumb(
      Breadcrumb(
        type: 'query',
        category: 'cache.$operation',
        message: '$operation $key → ${hit ? 'HIT' : 'MISS'}',
        level: SentryLevel.debug,
        data: {'key': key, 'hit': hit},
      ),
    );
  }
}
