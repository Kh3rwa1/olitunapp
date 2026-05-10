import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/observability/crash_reporting.dart';
import 'package:itun/core/error/failures.dart';

void main() {
  group('CrashReporting', () {
    test('isEnabled is false in test environment', () {
      expect(CrashReporting.isEnabled, isFalse);
    });

    test('addAppwriteBreadcrumb does not throw when disabled', () {
      expect(
        () => CrashReporting.addAppwriteBreadcrumb(
          operation: 'list',
          collection: 'categories',
        ),
        returnsNormally,
      );
    });

    test('addAppwriteBreadcrumb with failure does not throw', () {
      expect(
        () => CrashReporting.addAppwriteBreadcrumb(
          operation: 'create',
          collection: 'lessons',
          documentId: 'abc123',
          success: false,
          error: 'Timeout',
          statusCode: 408,
        ),
        returnsNormally,
      );
    });

    test('addAdminWriteBreadcrumb does not throw when disabled', () {
      expect(
        () => CrashReporting.addAdminWriteBreadcrumb(
          action: 'create',
          entity: 'lesson',
          entityId: 'lesson-1',
          metadata: {'title': 'Alphabet Intro'},
        ),
        returnsNormally,
      );
    });

    test('addUploadBreadcrumb does not throw when disabled', () {
      expect(
        () => CrashReporting.addUploadBreadcrumb(
          filename: 'letter_a.mp3',
          bucket: 'audio',
          sizeBytes: 1024000,
        ),
        returnsNormally,
      );
    });

    test('addUploadBreadcrumb with failure does not throw', () {
      expect(
        () => CrashReporting.addUploadBreadcrumb(
          filename: 'huge.mp4',
          bucket: 'videos',
          success: false,
          error: 'File too large',
        ),
        returnsNormally,
      );
    });

    test('addNavigationBreadcrumb does not throw when disabled', () {
      expect(
        () => CrashReporting.addNavigationBreadcrumb('/home', '/admin'),
        returnsNormally,
      );
    });

    test('addCacheBreadcrumb does not throw when disabled', () {
      expect(
        () => CrashReporting.addCacheBreadcrumb(
          operation: 'get',
          key: 'categories',
        ),
        returnsNormally,
      );
    });

    test('recordError does not throw when disabled', () {
      expect(
        () => CrashReporting.recordError(Exception('test'), StackTrace.current),
        returnsNormally,
      );
    });

    test('recordFailure does not throw when disabled', () {
      expect(
        () => CrashReporting.recordFailure(
          const ServerFailure(message: 'test', code: 500),
        ),
        returnsNormally,
      );
    });
  });
}
