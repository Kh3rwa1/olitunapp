import 'package:itun/core/logging/app_logger.dart';
import 'package:itun/core/logging/redaction_helper.dart';
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

  static const String _defaultDsn =
      'https://84bebaf2d902ae3f5326d29727aa6635@o4510882921709568.ingest.us.sentry.io/4512026738229248';

  static const String _dsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: _defaultDsn,
  );
  static const String _environment = String.fromEnvironment(
    'SENTRY_ENV',
    defaultValue: 'development',
  );
  static const bool _enableInDebug = bool.fromEnvironment(
    'SENTRY_ENABLE_IN_DEBUG',
  );

  static bool get isEnabled =>
      _dsn.isNotEmpty && (!kDebugMode || _enableInDebug);

  static Future<void> init() async {
    if (!isEnabled) {
      AppLogger.debug('CrashReporting: disabled (no DSN or running in debug).');
      return;
    }
    await SentryFlutter.init((options) {
      options.dsn = _dsn;
      options.environment = _environment;
      options.tracesSampleRate = 0.1;
      options.attachStacktrace = true;
      // PII gate: filenames, document IDs and error strings can carry
      // emails, tokens or user content. Scrub everything before upload —
      // this keeps the Play Data Safety story honest for a learning app.
      options.beforeSend = (event, hint) async => scrubEvent(event);
    });
  }

  static void recordError(Object error, StackTrace? stack) {
    if (!isEnabled) return;
    Sentry.captureException(error, stackTrace: stack);
  }

  /// PII scrubber applied to every event before upload (see `beforeSend`
  /// wiring in [init]). Pure function so it stays unit-testable without
  /// initializing the SDK: messages, exception values and breadcrumb
  /// payloads go through [RedactionHelper.sanitize], request headers and
  /// cookies are dropped outright, and any user-identity fields are
  /// stripped (the app never sets Sentry user identity).
  @visibleForTesting
  static SentryEvent scrubEvent(SentryEvent event) {
    final message = event.message;
    if (message != null) {
      message.formatted = RedactionHelper.sanitize(message.formatted);
    }

    final exceptions = event.exceptions;
    if (exceptions != null) {
      for (final e in exceptions) {
        if (e.value != null) {
          e.value = RedactionHelper.sanitize(e.value!);
        }
      }
    }

    final breadcrumbs = event.breadcrumbs;
    if (breadcrumbs != null) {
      for (final b in breadcrumbs) {
        if (b.message != null) {
          b.message = RedactionHelper.sanitize(b.message!);
        }
        final data = b.data;
        if (data != null) {
          for (final key in data.keys.toList()) {
            final value = data[key];
            if (value is String) data[key] = RedactionHelper.sanitize(value);
          }
        }
      }
    }

    final request = event.request;
    if (request != null) {
      request.headers = {};
      request.cookies = null;
    }

    final user = event.user;
    user?.id = null;
    user?.email = null;
    user?.username = null;
    user?.ipAddress = null;

    return event;
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
      AppLogger.debug(
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
          'documentId': ?documentId,
          'success': success,
          'error': ?error,
          'statusCode': ?statusCode,
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
      AppLogger.debug(
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
        data: {'entity': entity, 'entityId': ?entityId, ...?metadata},
      ),
    );
  }

  /// Record privileged maintenance requests such as content backup and reset.
  static void addAdminMaintenanceBreadcrumb({
    required String action,
    bool success = true,
    String? backupFileId,
    String? error,
  }) {
    if (!isEnabled) {
      AppLogger.debug(
        '[Breadcrumb] Admin maintenance $action'
        '${backupFileId != null ? ' backup=$backupFileId' : ''}'
        ' ${success ? 'OK' : 'FAIL: $error'}',
      );
      return;
    }
    Sentry.addBreadcrumb(
      Breadcrumb(
        type: 'user',
        category: 'admin.maintenance',
        message: 'maintenance $action',
        level: success ? SentryLevel.info : SentryLevel.error,
        data: {
          'action': action,
          'success': success,
          'backupFileId': ?backupFileId,
          'error': ?error,
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
      AppLogger.debug(
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

  /// Record a UI user interaction breadcrumb.
  static void addUIBreadcrumb({
    required String element,
    required String action,
  }) {
    if (!isEnabled) return;
    Sentry.addBreadcrumb(
      Breadcrumb(
        type: 'user',
        category: 'ui',
        message: '$action on $element',
        level: SentryLevel.info,
        data: {'element': element, 'action': action},
      ),
    );
  }

  /// Record an audio event breadcrumb.
  static void addAudioBreadcrumb({
    required String action,
    String? trackId,
    String? error,
  }) {
    if (!isEnabled) return;
    Sentry.addBreadcrumb(
      Breadcrumb(
        type: 'audio',
        category: 'audio',
        message: error != null ? '$action: $error' : action,
        level: error != null ? SentryLevel.error : SentryLevel.info,
        data: {'action': action, 'trackId': ?trackId, 'error': ?error},
      ),
    );
  }
}
