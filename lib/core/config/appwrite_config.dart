/// Centralized Appwrite configuration.
///
/// All values MUST be injected at build time via --dart-define flags.
/// The app will throw an assertion error at startup if any value is missing.
///
/// Required build flags:
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

  static const String endpoint = String.fromEnvironment('APPWRITE_ENDPOINT');
  static const String projectId = String.fromEnvironment('APPWRITE_PROJECT_ID');
  static const String databaseId = 'olitun_db';

  /// Validates all required config values are present.
  /// Call once at app startup in main().
  static void validate() {
    assert(
      endpoint.isNotEmpty,
      '\n\n🔴 APPWRITE_ENDPOINT is not set!\n'
      'Build with: --dart-define=APPWRITE_ENDPOINT=https://sgp.cloud.appwrite.io/v1\n',
    );
    assert(
      projectId.isNotEmpty,
      '\n\n🔴 APPWRITE_PROJECT_ID is not set!\n'
      'Build with: --dart-define=APPWRITE_PROJECT_ID=<your-project-id>\n',
    );
  }
}
