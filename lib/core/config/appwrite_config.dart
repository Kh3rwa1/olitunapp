/// Centralized Appwrite configuration.
///
/// Configured with production defaults so release builds and testing environments
/// are wired up out-of-the-box. Can be overridden via --dart-define flags:
///
///   --dart-define=APPWRITE_ENDPOINT=https://sgp.cloud.appwrite.io/v1
///   --dart-define=APPWRITE_PROJECT_ID=[your-project-id]
///   --dart-define=ADMIN_TEAM_ID=admins
///   --dart-define=TRANSLATE_URL=[appwrite-fn-url]
class AppwriteConfig {
  AppwriteConfig._();

  static const String _defaultEndpoint = 'https://sgp.cloud.appwrite.io/v1';
  static const String _defaultProjectId = '699495910038e39622c5';
  static const String _defaultTranslateUrl =
      'https://sgp.cloud.appwrite.io/v1/functions/6a007db60024418c0997/executions';

  static const String _envEndpoint = String.fromEnvironment(
    'APPWRITE_ENDPOINT',
    defaultValue: _defaultEndpoint,
  );
  static const String _envProjectId = String.fromEnvironment(
    'APPWRITE_PROJECT_ID',
    defaultValue: _defaultProjectId,
  );

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

  /// Razorpay public key ID used for checkout.
  static const String razorpayKeyId = String.fromEnvironment('RAZORPAY_KEY_ID');

  /// Translate Appwrite Function URL.
  static const String translateUrl = String.fromEnvironment(
    'TRANSLATE_URL',
    defaultValue: _defaultTranslateUrl,
  );

  /// Validates required config. Call once at app startup, before any
  /// Appwrite client is constructed. Throws [StateError] with an actionable
  /// message if anything required is missing.
  static void validate() {
    if (_envEndpoint.isEmpty) {
      throw StateError(
        '\n\nAPPWRITE_ENDPOINT is not set.\n'
        'Build with: --dart-define=APPWRITE_ENDPOINT=https://[region].cloud.appwrite.io/v1\n',
      );
    }
    if (_envProjectId.isEmpty) {
      throw StateError(
        '\n\nAPPWRITE_PROJECT_ID is not set.\n'
        'Build with: --dart-define=APPWRITE_PROJECT_ID=[your-project-id]\n',
      );
    }
    if (const bool.fromEnvironment('REQUIRE_TRANSLATE_URL') &&
        translateUrl.isEmpty) {
      throw StateError(
        '\n\nTRANSLATE_URL is required.\n'
        'Build with: --dart-define=TRANSLATE_URL=[your-appwrite-function-url]\n',
      );
    }
  }
}
