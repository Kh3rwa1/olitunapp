import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/config/appwrite_config.dart';

void main() {
  group('AppwriteConfig', () {
    test('development defaults are non-routable and safe', () {
      expect(Uri.parse(AppwriteConfig.endpoint).host, 'example.invalid');
      expect(AppwriteConfig.projectId, 'local-development');
      expect(AppwriteConfig.isBackendConfigured, isFalse);
      expect(AppwriteConfig.validate, returnsNormally);
    });

    test('recognizes only real backend targets as configured', () {
      expect(
        AppwriteConfig.isBackendConfiguredValues(
          endpoint: 'https://example.invalid/v1',
          projectId: 'production-project',
        ),
        isFalse,
      );
      expect(
        AppwriteConfig.isBackendConfiguredValues(
          endpoint: 'https://backend.example.com/v1',
          projectId: 'local-development',
        ),
        isFalse,
      );
      expect(
        AppwriteConfig.isBackendConfiguredValues(
          endpoint: 'https://backend.example.com/v1',
          projectId: 'production-project',
        ),
        isTrue,
      );
    });

    test('rejects a development environment for release artifacts', () {
      expect(
        () => AppwriteConfig.validateValues(
          environment: 'development',
          endpoint: 'https://example.invalid/v1',
          projectId: 'local-development',
          translateUrl: '',
          isReleaseMode: true,
          requireTranslateUrl: false,
        ),
        throwsStateError,
      );
    });

    test('rejects placeholder production configuration', () {
      expect(
        () => AppwriteConfig.validateValues(
          environment: 'production',
          endpoint: 'https://example.invalid/v1',
          projectId: 'local-development',
          translateUrl: 'https://example.invalid/functions/translator',
          isReleaseMode: true,
          requireTranslateUrl: false,
        ),
        throwsStateError,
      );
    });

    test('accepts explicit HTTPS production configuration', () {
      expect(
        () => AppwriteConfig.validateValues(
          environment: 'production',
          endpoint: 'https://backend.example.com/v1',
          projectId: 'production-project',
          translateUrl: 'https://backend.example.com/functions/translator',
          isReleaseMode: true,
          requireTranslateUrl: false,
        ),
        returnsNormally,
      );
    });

    test('rejects insecure production endpoints', () {
      expect(
        () => AppwriteConfig.validateValues(
          environment: 'production',
          endpoint: 'http://backend.example.com/v1',
          projectId: 'production-project',
          translateUrl: 'https://backend.example.com/functions/translator',
          isReleaseMode: true,
          requireTranslateUrl: false,
        ),
        throwsStateError,
      );
    });

    test('adminTeamId defaults to admins', () {
      expect(AppwriteConfig.adminTeamId, 'admins');
    });
  });
}
