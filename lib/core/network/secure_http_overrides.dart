import 'package:itun/core/logging/app_logger.dart';
import 'dart:io';

/// Keeps production HTTP clients on the platform's normal certificate
/// validation path.
///
/// `ALLOW_SELF_SIGNED=true` is reserved for local/self-hosted development.
/// Production builds should leave it unset so invalid, expired, or
/// self-signed certificates are rejected by the platform trust store.
class SecureHttpOverrides extends HttpOverrides {
  SecureHttpOverrides._();

  static void initialize() {
    if (const bool.fromEnvironment('ALLOW_SELF_SIGNED')) {
      AppLogger.debug(
        '[TLS Security] Self-signed certificates allowed for this build.',
      );
      return;
    }

    HttpOverrides.global = SecureHttpOverrides._();
    AppLogger.debug(
      '[TLS Security] Strict platform certificate validation active.',
    );
  }

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (cert, host, port) {
      AppLogger.debug(
        '[TLS Security] Rejected invalid certificate for $host:$port.',
      );
      return false;
    };
    return client;
  }
}
