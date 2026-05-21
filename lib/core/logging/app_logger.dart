import 'package:flutter/foundation.dart';

class AppLogger {
  const AppLogger._();

  static void debug(String message, {String? name}) {
    if (!kDebugMode) return;
    debugPrint(name == null ? message : '[$name] $message');
  }
}
