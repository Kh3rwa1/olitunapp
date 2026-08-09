import 'package:appwrite/appwrite.dart';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/auth/appwrite_auth_service.dart';

void main() {
  group('googleOAuthUserMessage', () {
    test('passes through raw OAuth errors for diagnosis', () {
      final message = googleOAuthUserMessage(
        'Invalid OAuth2 Response. Key and Secret not available.',
      );

      // Raw error is now surfaced directly instead of being remapped
      expect(message, contains('Key and Secret'));
    });

    test('preserves unknown provider errors', () {
      expect(
        googleOAuthUserMessage('The user cancelled sign-in.'),
        'The user cancelled sign-in.',
      );
    });
  });

  group('parseWebOAuthCompletion', () {
    test('parses Appwrite web session key redirects', () {
      final completion = parseWebOAuthCompletion(
        'https://olitun.app/splash?key=a_session_123&secret=session-secret',
      );

      expect(completion.kind, WebOAuthCompletionKind.persistSession);
      expect(completion.secret, 'session-secret');
      expect(completion.userId, isNull);
    });

    test('parses userId and secret redirects', () {
      final completion = parseWebOAuthCompletion(
        'https://olitun.app/splash?userId=user_1&secret=session-secret',
      );

      expect(completion.kind, WebOAuthCompletionKind.createSession);
      expect(completion.userId, 'user_1');
      expect(completion.secret, 'session-secret');
    });

    test('throws readable failure query messages', () {
      expect(
        () => parseWebOAuthCompletion(
          'https://olitun.app/welcome?failure=true&error=access_denied&message=Cancelled',
        ),
        throwsA(
          isA<AppwriteException>().having(
            (error) => error.message,
            'message',
            contains('access_denied'),
          ),
        ),
      );
    });

    test('rejects redirects without a secret', () {
      expect(
        () =>
            parseWebOAuthCompletion('https://olitun.app/splash?userId=user_1'),
        throwsA(
          isA<AppwriteException>().having(
            (error) => error.message,
            'message',
            contains('Missing session secret'),
          ),
        ),
      );
    });

    test('rejects redirects without a usable session key or userId', () {
      expect(
        () => parseWebOAuthCompletion(
          'https://olitun.app/splash?key=unexpected&secret=session-secret',
        ),
        throwsA(
          isA<AppwriteException>().having(
            (error) => error.message,
            'message',
            contains('Missing session key'),
          ),
        ),
      );
    });
  });

  group('parseAdminMaintenanceResponse', () {
    test('returns decoded success payload', () {
      final response = parseAdminMaintenanceResponse(
        statusCode: 200,
        body: '{"success":true,"deleted":{"lessons":3}}',
      );

      expect(response['success'], isTrue);
      expect(response['deleted'], {'lessons': 3});
    });

    test('throws function message on failed response', () {
      expect(
        () => parseAdminMaintenanceResponse(
          statusCode: 403,
          body: '{"success":false,"message":"Admin team required."}',
        ),
        throwsA(
          isA<AppwriteException>().having(
            (error) => error.message,
            'message',
            'Admin team required.',
          ),
        ),
      );
    });

    test('extracts backup file id when present', () {
      expect(
        adminMaintenanceBackupFileId({
          'success': true,
          'backup': {'fileId': 'backup-1'},
        }),
        'backup-1',
      );
    });
  });

  group('parseAccountDeletionExecution', () {
    test(
      'parses HTTP 500 with authDeleted: true as pending cleanup reconciliation',
      () {
        final res = parseAccountDeletionExecution(
          status: 'completed',
          statusCode: 500,
          responseBody:
              '{"ok":false,"code":"state_update_failed","authDeleted":true,"message":"Account deleted; final cleanup reconciliation is pending."}',
        );

        expect(res.isAuthDeleted, isTrue);
        expect(res.isFullSuccess, isFalse);
        expect(res.statusCode, 500);
        expect(
          res.errorMessage,
          contains('final cleanup reconciliation is pending'),
        );
      },
    );

    test('parses HTTP 500 without authDeleted as server deletion failure', () {
      final res = parseAccountDeletionExecution(
        status: 'completed',
        statusCode: 500,
        responseBody:
            '{"ok":false,"code":"db_error","message":"Database failure before Auth deletion."}',
      );

      expect(res.isAuthDeleted, isFalse);
      expect(res.isFullSuccess, isFalse);
      expect(res.statusCode, 500);
      expect(res.errorMessage, 'db_error');
    });

    test('parses HTTP 200 with ok: true as full deletion success', () {
      final res = parseAccountDeletionExecution(
        status: 'completed',
        statusCode: 200,
        responseBody: '{"ok":true,"code":"account_deleted"}',
      );

      expect(res.isAuthDeleted, isTrue);
      expect(res.isFullSuccess, isTrue);
      expect(res.statusCode, 200);
    });

    test('fails closed on empty response body', () {
      final res = parseAccountDeletionExecution(
        status: 'completed',
        statusCode: 500,
        responseBody: '',
      );

      expect(res.isAuthDeleted, isFalse);
      expect(res.isFullSuccess, isFalse);
      expect(res.errorMessage, 'Account deletion failed on server');
    });

    test('fails closed on malformed non-JSON response body', () {
      final res = parseAccountDeletionExecution(
        status: 'completed',
        statusCode: 200,
        responseBody: '<html>Internal Server Error</html>',
      );

      expect(res.isAuthDeleted, isFalse);
      expect(res.isFullSuccess, isFalse);
      expect(res.errorMessage, 'Account deletion failed on server');
    });

    test('fails closed on non-map JSON payload', () {
      final res = parseAccountDeletionExecution(
        status: 'completed',
        statusCode: 200,
        responseBody: '["ok", true]',
      );

      expect(res.isAuthDeleted, isFalse);
      expect(res.isFullSuccess, isFalse);
      expect(res.errorMessage, 'Account deletion failed on server');
    });
  });

  group('isWebSessionValidTimestamp', () {
    final now = DateTime(2026, 8, 9, 12, 0, 0);

    test('rejects null, zero, and negative timestamps', () {
      expect(isWebSessionValidTimestamp(null, nowOverride: now), isFalse);
      expect(isWebSessionValidTimestamp(0, nowOverride: now), isFalse);
      expect(isWebSessionValidTimestamp(-100, nowOverride: now), isFalse);
    });

    test('rejects timestamps older than 24 hours', () {
      final oldTs = now
          .subtract(const Duration(hours: 25))
          .millisecondsSinceEpoch;
      expect(isWebSessionValidTimestamp(oldTs, nowOverride: now), isFalse);
    });

    test(
      'rejects timestamps implausibly in the future (>1 min clock skew)',
      () {
        final futureTs = now
            .add(const Duration(minutes: 5))
            .millisecondsSinceEpoch;
        expect(isWebSessionValidTimestamp(futureTs, nowOverride: now), isFalse);
      },
    );

    test('allows timestamps within 1 min future clock skew allowance', () {
      final nearFutureTs = now
          .add(const Duration(seconds: 30))
          .millisecondsSinceEpoch;
      expect(
        isWebSessionValidTimestamp(nearFutureTs, nowOverride: now),
        isTrue,
      );
    });

    test('accepts valid timestamps within the 24-hour window', () {
      final validTs = now
          .subtract(const Duration(hours: 2))
          .millisecondsSinceEpoch;
      expect(isWebSessionValidTimestamp(validTs, nowOverride: now), isTrue);
    });
  });

  group('isTransientSessionValidationFailure', () {
    test('allows cached session only for network and timeout failures', () {
      expect(
        isTransientSessionValidationFailure(
          AppwriteException('offline', 0, 'network_failure'),
        ),
        isTrue,
      );
      expect(
        isTransientSessionValidationFailure(TimeoutException('slow')),
        isTrue,
      );
    });

    test('fails closed for non-auth Appwrite errors', () {
      expect(
        isTransientSessionValidationFailure(
          AppwriteException('bad request', 400, 'general_argument_invalid'),
        ),
        isFalse,
      );
      expect(
        isTransientSessionValidationFailure(
          AppwriteException('forbidden', 403, 'user_unauthorized'),
        ),
        isFalse,
      );
    });
  });
}
