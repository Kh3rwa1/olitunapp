import 'package:flutter/foundation.dart';
// Conditional import for web platform window history manipulation
import 'oauth_sanitizer_stub.dart'
    if (dart.library.js_interop) 'oauth_sanitizer_web.dart'
    if (dart.library.html) 'oauth_sanitizer_legacy_web.dart';

class OAuthSanitizer {
  static void sanitizeUrlHistory() {
    if (kIsWeb) {
      sanitizeWebHistory();
    }
  }

  /// Removes a one-time OAuth `error` query parameter after it was shown.
  static void clearOAuthError() {
    if (kIsWeb) {
      clearOAuthErrorParam();
    }
  }

  static bool isAllowedRedirect(String path) {
    const allowlist = {
      '/',
      '/welcome',
      '/onboarding',
      '/categories',
      '/profile',
    };
    final cleanPath = path.split('?').first;
    return allowlist.contains(cleanPath);
  }
}
