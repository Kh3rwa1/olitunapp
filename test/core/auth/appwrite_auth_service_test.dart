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
