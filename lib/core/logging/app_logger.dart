import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:itun/core/logging/redaction_helper.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Central logger.
///
/// * [debug] prints only in debug builds and never leaves the device.
/// * [warning] prints in debug builds and, when Sentry is initialized, records
///   a redacted breadcrumb so the context travels with the next crash report.
/// * [error] prints in debug builds and, when Sentry is initialized, captures
///   the exception (with its stack trace) or a redacted error-level message.
///
/// Every string that leaves the device is passed through
/// [RedactionHelper.sanitize]; `CrashReporting.scrubEvent` runs again in
/// `beforeSend` as a second line of defence.
class AppLogger {
  const AppLogger._();

  static Hub _hub = HubAdapter();

  /// Replaces the Sentry hub used for forwarding. Pass `null` to restore the
  /// global hub.
  @visibleForTesting
  static set hubForTesting(Hub? hub) => _hub = hub ?? HubAdapter();

  static void debug(
    String message, {
    String? name,
    Map<String, Object?> fields = const {},
  }) {
    if (!kDebugMode) return;
    debugPrint(_format(message, name: name, fields: fields));
  }

  static void warning(
    String message, {
    String? name,
    Map<String, Object?> fields = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      debugPrint(
        _format(
          '[WARNING] $message${error == null ? '' : ': $error'}',
          name: name,
          fields: fields,
        ),
      );
    }
    _forward(
      SentryLevel.warning,
      message,
      name: name,
      fields: fields,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void error(
    String message, {
    String? name,
    Map<String, Object?> fields = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      debugPrint(
        _format(
          '[ERROR] $message${error == null ? '' : ': $error'}',
          name: name,
          fields: fields,
        ),
      );
      if (stackTrace != null) debugPrint(stackTrace.toString());
    }
    _forward(
      SentryLevel.error,
      message,
      name: name,
      fields: fields,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void _forward(
    SentryLevel level,
    String message, {
    String? name,
    Map<String, Object?> fields = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {
    final hub = _hub;
    if (!hub.isEnabled) return;
    try {
      final safeMessage = RedactionHelper.sanitize(
        name == null ? message : '[$name] $message',
      );
      final safeFields = <String, Object?>{
        for (final entry in fields.entries)
          entry.key: _sanitizeValue(entry.value),
      };

      if (level == SentryLevel.warning) {
        hub.addBreadcrumb(
          Breadcrumb(
            type: 'log',
            category: name == null ? 'app.log' : 'app.log.$name',
            message: safeMessage,
            level: SentryLevel.warning,
            data: {
              ...safeFields,
              if (error != null) 'errorType': error.runtimeType.toString(),
              if (error != null)
                'error': RedactionHelper.sanitize(error.toString()),
            },
          ),
        );
        return;
      }

      if (error != null) {
        hub.captureException(
          error,
          stackTrace: stackTrace,
          message: SentryMessage(safeMessage),
          withScope: safeFields.isEmpty
              ? null
              : (scope) => scope.setContexts('log_fields', safeFields),
        );
      } else {
        hub.captureMessage(
          safeMessage,
          level: SentryLevel.error,
          withScope: safeFields.isEmpty
              ? null
              : (scope) => scope.setContexts('log_fields', safeFields),
        );
      }
    } catch (e) {
      // Telemetry must never break the caller; surface locally only.
      if (kDebugMode) debugPrint('AppLogger: Sentry forwarding failed: $e');
    }
  }

  static Object? _sanitizeValue(Object? value) {
    if (value is String) return RedactionHelper.sanitize(value);
    if (value == null || value is num || value is bool) return value;
    return RedactionHelper.sanitize(value.toString());
  }

  @visibleForTesting
  static String formatForTesting(
    String message, {
    String? name,
    Map<String, Object?> fields = const {},
  }) {
    return _format(message, name: name, fields: fields);
  }

  static String _format(
    String message, {
    String? name,
    Map<String, Object?> fields = const {},
  }) {
    final event = name == null ? message : '[$name] $message';
    if (fields.isEmpty) return event;

    return jsonEncode({'level': 'debug', 'message': event, 'fields': fields});
  }
}
