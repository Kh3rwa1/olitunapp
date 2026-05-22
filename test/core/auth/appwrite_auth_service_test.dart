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
