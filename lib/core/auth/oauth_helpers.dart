import 'package:flutter/foundation.dart';
import 'package:appwrite/appwrite.dart';

@visibleForTesting
String googleOAuthUserMessage(String message) {
  final lowerMessage = message.toLowerCase();
  if (lowerMessage.contains('provider') &&
      (lowerMessage.contains('disabled') ||
          lowerMessage.contains('not enabled'))) {
    return 'Google sign-in is disabled in Appwrite. Enable the Google OAuth provider, then try again.';
  }

  return message;
}

enum WebOAuthCompletionKind { persistSession, createSession }

@visibleForTesting
class WebOAuthCompletion {
  final WebOAuthCompletionKind kind;
  final String secret;
  final String? userId;

  const WebOAuthCompletion._({
    required this.kind,
    required this.secret,
    this.userId,
  });

  const WebOAuthCompletion.persistSession(String secret)
    : this._(kind: WebOAuthCompletionKind.persistSession, secret: secret);

  const WebOAuthCompletion.createSession({
    required String userId,
    required String secret,
  }) : this._(
         kind: WebOAuthCompletionKind.createSession,
         userId: userId,
         secret: secret,
       );
}

WebOAuthCompletion parseWebOAuthCompletion(String result) {
  final uri = Uri.parse(result);
  if (uri.queryParameters.containsKey('failure')) {
    final error = uri.queryParameters['error'] ?? '';
    final message = uri.queryParameters['message'] ?? '';
    throw AppwriteException(
      'Google sign in failed${error.isNotEmpty ? ' ($error)' : ''}: ${message.isNotEmpty ? message : 'Session was cancelled or failed.'}',
    );
  }

  final key = uri.queryParameters['key'];
  final secret = uri.queryParameters['secret'];
  final userId = uri.queryParameters['userId'];

  if (secret == null || secret.isEmpty) {
    throw AppwriteException('Invalid OAuth2 response. Missing session secret.');
  }

  if (key != null && key.startsWith('a_session_')) {
    return WebOAuthCompletion.persistSession(secret);
  }

  if (userId != null && userId.isNotEmpty) {
    return WebOAuthCompletion.createSession(userId: userId, secret: secret);
  }

  throw AppwriteException('Invalid OAuth2 response. Missing session key.');
}

/// Builds the Google OAuth2 token URL for the mobile flow, mirroring the
/// Appwrite backend contract: `success`/`failure` deep links plus scopes
/// and project. Pure function so the exact URL the browser opens is
/// unit-testable.
Uri buildMobileGoogleOAuthUrl({
  required String endpoint,
  required String projectId,
}) {
  final successLink = 'appwrite-callback-$projectId://success';
  final failureLink = 'appwrite-callback-$projectId://failure';
  final query = [
    'success=${Uri.encodeComponent(successLink)}',
    'failure=${Uri.encodeComponent(failureLink)}',
    'scopes[]=${Uri.encodeComponent('email')}',
    'scopes[]=${Uri.encodeComponent('profile')}',
    'project=${Uri.encodeComponent(projectId)}',
  ].join('&');
  return Uri.parse('$endpoint/account/tokens/oauth2/google?$query');
}
