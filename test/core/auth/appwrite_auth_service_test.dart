import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/auth/appwrite_auth_service.dart';

void main() {
  group('googleOAuthUserMessage', () {
    test('maps missing OAuth secrets to an actionable setup message', () {
      final message = googleOAuthUserMessage(
        'Invalid OAuth2 Response. Key and Secret not available.',
      );

      expect(message, contains('Google sign-in is not configured in Appwrite'));
      expect(message, contains('Client ID'));
      expect(message, contains('Client Secret'));
    });

    test('preserves unknown provider errors', () {
      expect(
        googleOAuthUserMessage('The user cancelled sign-in.'),
        'The user cancelled sign-in.',
      );
    });
  });
}
