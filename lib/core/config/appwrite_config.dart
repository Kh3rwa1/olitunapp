import 'package:flutter/foundation.dart';

/// Centralized Appwrite configuration.
///
/// Development and test builds default to a non-routable endpoint so a local
/// run can never contact production by accident. Release builds must identify
/// their environment explicitly and provide real backend values.
class AppwriteConfig {
  AppwriteConfig._();

  static const String environmentName = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static const String _envEndpoint = String.fromEnvironment(
    'APPWRITE_ENDPOINT',
    defaultValue: 'https://example.invalid/v1',
  );
  static const String _envProjectId = String.fromEnvironment(
    'APPWRITE_PROJECT_ID',
    defaultValue: 'local-development',
  );

  static String get endpoint => _envEndpoint;
  static String get projectId => _envProjectId;

  static const String databaseId = 'olitun_db';

  /// ID of the Appwrite Team that grants admin access.
  static const String adminTeamId = String.fromEnvironment(
    'ADMIN_TEAM_ID',
    defaultValue: 'admins',
  );

  /// Razorpay public key ID used for checkout.
  static const String razorpayKeyId = String.fromEnvironment('RAZORPAY_KEY_ID');

  /// Translate Appwrite Function URL. The function itself remains separately
  /// deployed and versioned; this value only selects its environment endpoint.
  static const String translateUrl = String.fromEnvironment('TRANSLATE_URL');

  static const Set<String> _knownEnvironments = {
    'development',
    'test',
    'ci',
    'staging',
    'production',
  };

  /// Validates build-time configuration before any SDK client is constructed.
  static void validate() {
    validateValues(
      environment: environmentName,
      endpoint: endpoint,
      projectId: projectId,
      translateUrl: translateUrl,
      isReleaseMode: kReleaseMode,
      requireTranslateUrl: const bool.fromEnvironment('REQUIRE_TRANSLATE_URL'),
    );
  }

  /// Pure validation entry point used by tests and release tooling.
  @visibleForTesting
  static void validateValues({
    required String environment,
    required String endpoint,
    required String projectId,
    required String translateUrl,
    required bool isReleaseMode,
    required bool requireTranslateUrl,
  }) {
    final normalizedEnvironment = environment.trim().toLowerCase();
    if (!_knownEnvironments.contains(normalizedEnvironment)) {
      throw StateError(
        'APP_ENV must be one of: ${_knownEnvironments.join(', ')}.',
      );
    }

    if (isReleaseMode &&
        normalizedEnvironment != 'production' &&
        normalizedEnvironment != 'staging' &&
        normalizedEnvironment != 'ci') {
      throw StateError(
        'Release builds require APP_ENV=production, staging, or ci.',
      );
    }

    final productionLike =
        normalizedEnvironment == 'production' ||
        normalizedEnvironment == 'staging';

    _validateHttpUrl(
      name: 'APPWRITE_ENDPOINT',
      value: endpoint,
      requireHttps: productionLike,
    );

    final normalizedProjectId = projectId.trim();
    if (normalizedProjectId.isEmpty) {
      throw StateError('APPWRITE_PROJECT_ID must not be empty.');
    }
    if (productionLike &&
        const {
          'local-development',
          'ci-project',
          'placeholder',
        }.contains(normalizedProjectId)) {
      throw StateError(
        'APPWRITE_PROJECT_ID must identify a real $normalizedEnvironment project.',
      );
    }

    final needsTranslateUrl = productionLike || requireTranslateUrl;
    if (needsTranslateUrl && translateUrl.trim().isEmpty) {
      throw StateError(
        'TRANSLATE_URL is required for $normalizedEnvironment builds.',
      );
    }
    if (translateUrl.trim().isNotEmpty) {
      _validateHttpUrl(
        name: 'TRANSLATE_URL',
        value: translateUrl,
        requireHttps: productionLike,
      );
    }

    if (productionLike) {
      final endpointHost = Uri.parse(endpoint).host.toLowerCase();
      final translateHost = Uri.parse(translateUrl).host.toLowerCase();
      if (endpointHost.endsWith('.invalid') ||
          translateHost.endsWith('.invalid')) {
        throw StateError(
          'Non-routable placeholder URLs cannot be used in $normalizedEnvironment.',
        );
      }
    }
  }

  static void _validateHttpUrl({
    required String name,
    required String value,
    required bool requireHttps,
  }) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !uri.hasScheme ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw StateError('$name must be a valid HTTP(S) URL.');
    }
    if (requireHttps && uri.scheme != 'https') {
      throw StateError('$name must use HTTPS outside local or CI builds.');
    }
  }
}
