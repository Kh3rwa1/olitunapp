import 'package:flutter/foundation.dart';
import 'package:itun/core/logging/app_logger.dart';
import 'package:itun/core/logging/redaction_helper.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../error/failures.dart';

/// Thin wrapper around Sentry so the rest of the codebase does not depend on
/// its SDK. Telemetry is opt-in: without an explicit `SENTRY_DSN`, every
/// recording call is a no-op.
class CrashReporting {
  CrashReporting._();

  static const String _dsn = String.fromEnvironment('SENTRY_DSN');
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
      AppLogger.debug('CrashReporting: disabled.');
      return;
    }
    await SentryFlutter.init((options) {
      options.dsn = _dsn;
      options.environment = _environment;
      options.tracesSampleRate = 0.1;
      options.attachStacktrace = true;
      options.sendDefaultPii = false;
      options.beforeSend = (event, hint) async => scrubEvent(event);
    });
  }

  static void recordError(Object error, StackTrace? stack) {
    if (!isEnabled) return;
    Sentry.captureException(error, stackTrace: stack);
  }

  /// Scrubs identity, credentials, query parameters, and recursively nested
  /// breadcrumb data before an event leaves the device.
  @visibleForTesting
  static SentryEvent scrubEvent(SentryEvent event) {
    final message = event.message;
    if (message != null) {
      message.formatted = RedactionHelper.sanitize(message.formatted);
    }

    final exceptions = event.exceptions;
    if (exceptions != null) {
      for (final exception in exceptions) {
        if (exception.value != null) {
          exception.value = RedactionHelper.sanitize(exception.value!);
        }
      }
    }

    final breadcrumbs = event.breadcrumbs;
    if (breadcrumbs != null) {
      for (final breadcrumb in breadcrumbs) {
        if (breadcrumb.message != null) {
          breadcrumb.message = RedactionHelper.sanitize(breadcrumb.message!);
        }
        final data = breadcrumb.data;
        if (data != null) {
          for (final key in data.keys.toList()) {
            data[key] = _sanitizeTelemetryValue(data[key], key: key);
          }
        }
      }
    }

    final request = event.request;
    if (request != null) {
      request.headers = {};
      request.cookies = null;
      final rawUrl = request.url;
      if (rawUrl != null) {
        final uri = Uri.tryParse(rawUrl);
        if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
          final sanitizedUri = Uri(
            scheme: uri.scheme,
            host: uri.host,
            port: uri.hasPort ? uri.port : null,
            path: uri.path,
          );
          request.url = RedactionHelper.sanitize(sanitizedUri.toString());
        } else {
          request.url = RedactionHelper.sanitize(rawUrl);
        }
      }
    }

    final user = event.user;
    user?.id = null;
    user?.email = null;
    user?.username = null;
    user?.ipAddress = null;

    return event;
  }

  static Object? _sanitizeTelemetryValue(Object? value, {String? key}) {
    if (key != null && _isSensitiveTelemetryKey(key)) return '[REDACTED]';
    if (value is String) return RedactionHelper.sanitize(value);
    if (value is Map) {
      return value.map<String, Object?>((rawKey, nestedValue) {
        final nestedKey = rawKey.toString();
        return MapEntry(
          nestedKey,
          _sanitizeTelemetryValue(nestedValue, key: nestedKey),
        );
      });
    }
    if (value is Iterable) {
      return value.map(_sanitizeTelemetryValue).toList(growable: false);
    }
    return value;
  }

  static bool _isSensitiveTelemetryKey(String key) {
    final normalized = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return normalized.contains('password') ||
        normalized.contains('secret') ||
        normalized.contains('token') ||
        normalized.contains('authorization') ||
        normalized.contains('cookie') ||
        normalized.contains('email') ||
        normalized.contains('phone') ||
        normalized.contains('ipaddress') ||
        normalized == 'userid';
  }

  static void recordFlutterError(FlutterErrorDetails details) {
    if (!isEnabled) return;
    Sentry.captureException(details.exception, stackTrace: details.stack);
  }

  static void recordFailure(Failure failure, [StackTrace? stack]) {
    if (!isEnabled) return;
    if (failure is NetworkFailure || failure is ValidationFailure) return;
    final safeMessage = RedactionHelper.sanitize(failure.message);
    Sentry.captureMessage(
      '${failure.runtimeType}: $safeMessage'
      '${failure.code != null ? ' (code ${failure.code})' : ''}',
      level: SentryLevel.error,
    );
  }

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

  static void addAppwriteBreadcrumb({
    required String operation,
    required String collection,
    String? documentId,
    bool success = true,
    String? error,
    int? statusCode,
  }) {
    final safeError = error == null ? null : RedactionHelper.sanitize(error);
    if (!isEnabled) {
      AppLogger.debug(
        '[Breadcrumb] Appwrite $operation on $collection'
        '${documentId != null ? '/$documentId' : ''}'
        ' → ${success ? 'OK' : 'FAIL: $safeError'}',
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
          'error': ?safeError,
          'statusCode': ?statusCode,
        },
      ),
    );
  }

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

  static void addAdminMaintenanceBreadcrumb({
    required String action,
    bool success = true,
    String? backupFileId,
    String? error,
  }) {
    final safeError = error == null ? null : RedactionHelper.sanitize(error);
    if (!isEnabled) {
      AppLogger.debug(
        '[Breadcrumb] Admin maintenance $action'
        '${backupFileId != null ? ' backup=$backupFileId' : ''}'
        ' ${success ? 'OK' : 'FAIL: $safeError'}',
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
          'error': ?safeError,
        },
      ),
    );
  }

  static void addUploadBreadcrumb({
    required String filename,
    required String bucket,
    bool success = true,
    String? error,
    int? sizeBytes,
  }) {
    final safeFilename = RedactionHelper.sanitize(filename);
    final safeError = error == null ? null : RedactionHelper.sanitize(error);
    if (!isEnabled) {
      AppLogger.debug(
        '[Breadcrumb] Upload $safeFilename → $bucket '
        '${success ? 'OK' : 'FAIL: $safeError'}',
      );
      return;
    }
    Sentry.addBreadcrumb(
      Breadcrumb(
        type: 'http',
        category: 'upload',
        message: 'Upload $safeFilename → $bucket',
        level: success ? SentryLevel.info : SentryLevel.error,
        data: {
          'filename': safeFilename,
          'bucket': bucket,
          'success': success,
          'sizeBytes': ?sizeBytes,
          'error': ?safeError,
        },
      ),
    );
  }

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
        message: '$operation cache entry → ${hit ? 'HIT' : 'MISS'}',
        level: SentryLevel.debug,
        data: {'key': key, 'hit': hit},
      ),
    );
  }

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

  static void addAudioBreadcrumb({
    required String action,
    String? trackId,
    String? error,
  }) {
    if (!isEnabled) return;
    final safeError = error == null ? null : RedactionHelper.sanitize(error);
    Sentry.addBreadcrumb(
      Breadcrumb(
        type: 'audio',
        category: 'audio',
        message: safeError != null ? '$action: $safeError' : action,
        level: safeError != null ? SentryLevel.error : SentryLevel.info,
        data: {'action': action, 'trackId': ?trackId, 'error': ?safeError},
      ),
    );
  }
}
