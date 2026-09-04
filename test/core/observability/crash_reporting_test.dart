import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/observability/crash_reporting.dart';
import 'package:itun/core/error/failures.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

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

    test('addAdminMaintenanceBreadcrumb does not throw when disabled', () {
      expect(
        () => CrashReporting.addAdminMaintenanceBreadcrumb(
          action: 'wipe_content',
          backupFileId: 'backup-1',
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

    group('scrubEvent', () {
      test('redacts email and tokens from messages and exceptions', () {
        final event = SentryEvent(
          message: SentryMessage('failed for user@example.com'),
          exceptions: [
            SentryException(
              type: 'StateError',
              value: 'Bearer abc123.def456 state',
            ),
          ],
        );

        final scrubbed = CrashReporting.scrubEvent(event);

        expect(scrubbed.message!.formatted, contains('u***@example.com'));
        expect(
          scrubbed.message!.formatted,
          isNot(contains('user@example.com')),
        );
        expect(
          scrubbed.exceptions!.first.value,
          contains('Bearer [REDACTED_TOKEN]'),
        );
      });

      test('sanitizes breadcrumb payloads but keeps structure', () {
        final event = SentryEvent(
          breadcrumbs: [
            Breadcrumb(
              message: 'Upload failed for kid@mail.com',
              data: {'filename': 'photo.jpg', 'userId': 'user-1'},
            ),
          ],
        );

        final scrubbed = CrashReporting.scrubEvent(event);
        final crumb = scrubbed.breadcrumbs!.first;

        expect(crumb.message, contains('k***@mail.com'));
        expect(crumb.data!['filename'], 'photo.jpg');
        expect(crumb.message, isNot(contains('kid@mail.com')));
      });

      test('drops request headers/cookies and user identity fields', () {
        final event = SentryEvent(
          request: SentryRequest(
            url: 'https://sgp.cloud.appwrite.io/v1/databases/x',
            method: 'GET',
            headers: {'Authorization': 'Bearer secret'},
            cookies: 'a_session=abc',
          ),
          user: SentryUser(id: 'u1', email: 'a@b.com', ipAddress: '1.2.3.4'),
        );

        final scrubbed = CrashReporting.scrubEvent(event);

        expect(scrubbed.request!.headers, isEmpty);
        expect(scrubbed.request!.cookies, isNull);
        expect(scrubbed.request!.url, contains('appwrite.io'));
        expect(scrubbed.user!.id, isNull);
        expect(scrubbed.user!.email, isNull);
        expect(scrubbed.user!.ipAddress, isNull);
      });

      test('passes through events with no sensitive content unchanged', () {
        final event = SentryEvent(message: SentryMessage('plain failure'));

        final scrubbed = CrashReporting.scrubEvent(event);

        expect(scrubbed.message!.formatted, 'plain failure');
      });
    });
  });
}
