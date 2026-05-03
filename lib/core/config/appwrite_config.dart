/// Centralized Appwrite configuration.
///
/// Required build flags — the app will throw a StateError on startup if
/// either of these is missing. There are no hardcoded fallbacks.
///
///   --dart-define=APPWRITE_ENDPOINT=https://sgp.cloud.appwrite.io/v1
///   --dart-define=APPWRITE_PROJECT_ID=<your-project-id>
///
/// Optional:
///   --dart-define=ADMIN_TEAM_ID=admins         (default: "admins")
///   --dart-define=TRANSLATE_URL=<appwrite-fn-url>
///   --dart-define=API_BASE_URL=<your-api-base>
///   --dart-define=SENTRY_DSN=<sentry-dsn>
class AppwriteConfig {
  AppwriteConfig._();

  static const String _envEndpoint = String.fromEnvironment('APPWRITE_ENDPOINT');
  static const String _envProjectId = String.fromEnvironment('APPWRITE_PROJECT_ID');

  /// Resolved endpoint — never empty after [validate].
  static String get endpoint => _envEndpoint;

  /// Resolved project ID — never empty after [validate].
  static String get projectId => _envProjectId;

  static const String databaseId = 'olitun_db';

  /// ID (or name) of the Appwrite Team that grants admin access.
  /// Membership in this team is the single source of truth for admin rights.
  static const String adminTeamId = String.fromEnvironment(
    'ADMIN_TEAM_ID',
    defaultValue: 'admins',
  );

  /// Validates required config. Call once at app startup, before any
  /// Appwrite client is constructed. Throws [StateError] with an actionable
  /// message if anything required is missing.
  static void validate() {
    if (_envEndpoint.isEmpty) {
      throw StateError(
        '\n\nAPPWRITE_ENDPOINT is not set.\n'
        'Build with: --dart-define=APPWRITE_ENDPOINT=https://<region>.cloud.appwrite.io/v1\n',
      );
    }
    if (_envProjectId.isEmpty) {
      throw StateError(
        '\n\nAPPWRITE_PROJECT_ID is not set.\n'
        'Build with: --dart-define=APPWRITE_PROJECT_ID=<your-project-id>\n',
      );
    }
  }
}
