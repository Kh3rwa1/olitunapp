import 'package:itun/core/auth/appwrite_auth_service.dart';
import 'package:itun/core/config/appwrite_config.dart';
import 'package:itun/core/logging/app_logger.dart';

/// Server-side admin authorization.
///
/// Admin rights are decided by the Cloudflare Worker (`/api/v1/auth/me`
/// `isAdmin`): members of the Appwrite team [AppwriteConfig.adminTeamId]
/// keep the role when their session moves to Worker sign-in, and
/// ADMIN_EMAILS can grant it. There is NO client-side secret.
///
/// The previous client-side admin-secret model has been removed —
/// it provided no real security because the secret was bundled into the
/// compiled JS/APK and could be extracted by anyone.
/// Minimal seam over `Teams(client).list()` so unit tests can inject a fake
/// without depending on a real Appwrite client.
typedef TeamsListFetcher = Future<List<String>> Function();

class AdminAuthService {
  AdminAuthService(this._auth, {TeamsListFetcher? teamsListFetcher})
    : _teamsListFetcher = teamsListFetcher;

  final AppwriteAuthService _auth;
  final TeamsListFetcher? _teamsListFetcher;

  Future<List<String>> _listTeamIds() async => _teamsListFetcher!();

  /// Returns true if the currently logged-in user is a member of the admin
  /// team. Returns false if there is no session, or membership lookup fails.
  ///
  /// Membership is matched against the team's **immutable ID** only.
  /// Matching by team name would let any user with team-create permission
  /// escalate to admin by creating a team called `admins`, so name matching
  /// is intentionally not supported.
  Future<bool> isCurrentUserAdmin() async {
    try {
      if (_teamsListFetcher == null) return await _auth.isCurrentUserAdmin();
      final teamIds = await _listTeamIds();
      const adminId = AppwriteConfig.adminTeamId;
      return teamIds.any((id) => id == adminId);
    } catch (e, stack) {
      AppLogger.warning(
        'AdminAuth: membership lookup failed',
        name: 'AdminAuthService',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }

  /// Signs an admin in and verifies the role. Appwrite password sessions
  /// no longer exist, so this reuses the current session when it is already
  /// an admin, and otherwise signs in with Google ([email] and [password]
  /// are ignored). On the web the Google redirect leaves the page; the admin
  /// opens /admin again afterwards. A non-admin session created here is
  /// signed out again.
  Future<bool> signInAsAdmin({
    required String email,
    required String password,
  }) async {
    try {
      if (await isCurrentUserAdmin()) return true;

      await _auth.signInWithGoogle();

      final isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) {
        // Clean up — non-admin should not be left with a session created here.
        await _auth.signOut();
      }
      return isAdmin;
    } catch (e, stack) {
      AppLogger.warning(
        'AdminAuth: sign-in failed',
        name: 'AdminAuthService',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }

  Future<void> signOut() => _auth.signOut();
}
