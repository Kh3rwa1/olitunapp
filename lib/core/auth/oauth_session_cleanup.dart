import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;

import '../logging/app_logger.dart';

/// Ends whatever Appwrite session this browser or device still holds before
/// an OAuth redirect.
///
/// Appwrite links a Google login to an existing account with the same email
/// only when nobody is signed in. If a session is still active (typically a
/// leftover guest session), Appwrite tries to attach the Google identity to
/// that user instead and fails with `409 user_already_exists`.
///
/// Returns true when the browser is confirmed signed out (or nobody was
/// signed in), false when a session could not be removed.
Future<bool> clearSessionsBeforeOAuth(
  Account account, {
  Future<void> Function()? restoreWebSession,
}) async {
  // Restoring and deleting are separate steps: a failed restore must never
  // skip the deletion.
  if (restoreWebSession != null) {
    try {
      await restoreWebSession();
    } catch (e) {
      AppLogger.debug('OAuth cleanup: session restore failed: $e', name: _tag);
    }
  }

  final current = await _currentUser(account);
  if (current == null) return true;

  // A guest's sessions belong to nobody else, so remove all of them. For a
  // real account only end this device's session, never other devices'.
  final isGuest = current.email.trim().isEmpty;
  try {
    if (isGuest) {
      await account.deleteSessions();
    } else {
      await account.deleteSession(sessionId: 'current');
    }
  } catch (e) {
    AppLogger.debug('OAuth cleanup: session delete failed: $e', name: _tag);
  }

  final remaining = await _currentUser(account);
  if (remaining == null) return true;
  if (remaining.email.trim().isEmpty) {
    try {
      await account.deleteSessions();
    } catch (e) {
      AppLogger.debug('OAuth cleanup: retry delete failed: $e', name: _tag);
    }
    return await _currentUser(account) == null;
  }
  return false;
}

const _tag = 'OAuthSessionCleanup';

Future<models.User?> _currentUser(Account account) async {
  try {
    return await account.get();
  } on AppwriteException catch (e) {
    // 401 means nobody is signed in, which is what we want.
    if (e.code != 401) {
      AppLogger.debug('OAuth cleanup: account check failed: $e', name: _tag);
    }
    return null;
  } catch (e) {
    AppLogger.debug('OAuth cleanup: account check failed: $e', name: _tag);
    return null;
  }
}
