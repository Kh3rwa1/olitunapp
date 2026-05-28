import 'dart:convert';

import 'package:flutter/foundation.dart';

class AppLogger {
  const AppLogger._();

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
  }) {
    if (!kDebugMode) return;
    debugPrint(_format('[WARNING] $message', name: name, fields: fields));
  }

  static void error(
    String message, {
    String? name,
    Map<String, Object?> fields = const {},
  }) {
    if (!kDebugMode) return;
    debugPrint(_format('[ERROR] $message', name: name, fields: fields));
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
