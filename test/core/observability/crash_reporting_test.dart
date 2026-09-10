import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/core/observability/crash_reporting.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  group('CrashReporting', () {
    test('telemetry is opt-in in the test environment', () {
      expect(CrashReporting.isEnabled, isFalse);
    });

    test('recording APIs remain safe when disabled', () {
      expect(
        () => CrashReporting.addAppwriteBreadcrumb(
          operation: 'create',
          collection: 'lessons',
          documentId: 'abc123',
          success: false,
          error: 'Timeout for kid@example.com',
          statusCode: 408,
        ),
        returnsNormally,
      );
      expect(
        () => CrashReporting.addAdminWriteBreadcrumb(
          action: 'create',
          entity: 'lesson',
          entityId: 'lesson-1',
          metadata: {'title': 'Alphabet Intro'},
        ),
        returnsNormally,
      );
      expect(
        () => CrashReporting.addAdminMaintenanceBreadcrumb(
          action: 'wipe_content',
          backupFileId: 'backup-1',
        ),
        returnsNormally,
      );
      expect(
        () => CrashReporting.addUploadBreadcrumb(
          filename: 'letter_a.mp3',
          bucket: 'audio',
          sizeBytes: 1024000,
        ),
        returnsNormally,
      );
      expect(
        () => CrashReporting.addNavigationBreadcrumb('/home', '/admin'),
        returnsNormally,
      );
      expect(
        () => CrashReporting.addCacheBreadcrumb(
          operation: 'get',
          key: 'categories',
        ),
        returnsNormally,
      );
      expect(
        () => CrashReporting.recordError(Exception('test'), StackTrace.current),
        returnsNormally,
      );
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

      test('recursively sanitizes breadcrumb payloads', () {
        final event = SentryEvent(
          breadcrumbs: [
            Breadcrumb(
              message: 'Upload failed for kid@mail.com',
              data: {
                'filename': 'photo.jpg',
                'userId': 'user-1',
                'nested': {
                  'authorization': 'Bearer nested-secret',
                  'note': 'contact parent@mail.com',
                },
              },
            ),
          ],
        );

        final scrubbed = CrashReporting.scrubEvent(event);
        final crumb = scrubbed.breadcrumbs!.first;
        final nested = crumb.data!['nested'] as Map<String, Object?>;

        expect(crumb.message, contains('k***@mail.com'));
        expect(crumb.data!['filename'], 'photo.jpg');
        expect(crumb.data!['userId'], '[REDACTED]');
        expect(nested['authorization'], '[REDACTED]');
        expect(nested['note'], contains('p***@mail.com'));
      });

      test('drops request credentials, query data, and user identity', () {
        final event = SentryEvent(
          request: SentryRequest(
            url:
                'https://sgp.cloud.appwrite.io/v1/databases/x?secret=abc#token',
            method: 'GET',
            headers: {'Authorization': 'Bearer secret'},
            cookies: 'a_session=abc',
          ),
          user: SentryUser(id: 'u1', email: 'a@b.com', ipAddress: '1.2.3.4'),
        );

        final scrubbed = CrashReporting.scrubEvent(event);

        expect(scrubbed.request!.headers, isEmpty);
        expect(scrubbed.request!.cookies, isNull);
        expect(scrubbed.request!.url, endsWith('/v1/databases/x'));
        expect(scrubbed.request!.url, isNot(contains('secret')));
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
