import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// True when running under `flutter test` (used to skip infinite/looping
/// animations that would never settle in widget tests).
bool get isFlutterTestEnvironment {
  if (kIsWeb) return false;
  try {
    return Platform.environment.containsKey('FLUTTER_TEST');
  } catch (_) {
    // Platform.environment is unavailable in some sandboxed runtimes;
    // defaulting to non-test is the safe fallback.
    return false;
  }
}
