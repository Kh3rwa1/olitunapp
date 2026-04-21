/// Centralized Appwrite configuration.
///
/// Values are injected at build time via --dart-define flags.
/// If not provided, hardcoded production defaults are used.
///
/// Optional build flags (override defaults):
///   --dart-define=APPWRITE_ENDPOINT=https://sgp.cloud.appwrite.io/v1
///   --dart-define=APPWRITE_PROJECT_ID=<your-project-id>
///   --dart-define=ADMIN_SECRET_KEY=<your-admin-secret>
///
/// Example build command:
///   flutter build apk \
///     --dart-define=APPWRITE_ENDPOINT=https://sgp.cloud.appwrite.io/v1 \
///     --dart-define=APPWRITE_PROJECT_ID=699495910038e39622c5 \
///     --dart-define=ADMIN_SECRET_KEY=<new-secure-key>
class AppwriteConfig {
  AppwriteConfig._();

  // --dart-define overrides (empty string if not provided)
  static const String _envEndpoint = String.fromEnvironment('APPWRITE_ENDPOINT');
  static const String _envProjectId = String.fromEnvironment('APPWRITE_PROJECT_ID');

  // Production defaults — used when --dart-define values are not provided
  static const String _defaultEndpoint = 'https://sgp.cloud.appwrite.io/v1';
  static const String _defaultProjectId = '699495910038e39622c5';

  /// Resolved endpoint: --dart-define value if set, otherwise production default
  static String get endpoint =>
      _envEndpoint.isNotEmpty ? _envEndpoint : _defaultEndpoint;

  /// Resolved project ID: --dart-define value if set, otherwise production default
  static String get projectId =>
      _envProjectId.isNotEmpty ? _envProjectId : _defaultProjectId;

  static const String databaseId = 'olitun_db';

  /// Validates all required config values are present.
  /// Uses runtime check (not assert) so it works in release builds too.
  static void validate() {
    if (endpoint.isEmpty) {
      throw StateError(
        '\n\n🔴 APPWRITE_ENDPOINT is not set!\n'
        'Build with: --dart-define=APPWRITE_ENDPOINT=https://sgp.cloud.appwrite.io/v1\n',
      );
    }
    if (projectId.isEmpty) {
      throw StateError(
        '\n\n🔴 APPWRITE_PROJECT_ID is not set!\n'
        'Build with: --dart-define=APPWRITE_PROJECT_ID=<your-project-id>\n',
      );
    }
  }
}

