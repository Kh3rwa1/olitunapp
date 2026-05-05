import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/auth/appwrite_auth_service.dart';
import '../../../core/config/appwrite_config.dart';

/// Server-side admin authorization.
///
/// Admin rights are granted by membership in the Appwrite Team configured
/// via [AppwriteConfig.adminTeamId]. There is NO client-side secret. A user
/// must (a) have a valid Appwrite session and (b) be a member of the admin
/// team, both of which are verified server-side by Appwrite.
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

  Future<List<String>> _listTeamIds() async {
    if (_teamsListFetcher != null) return _teamsListFetcher();
    final teams = Teams(_auth.client);
    final result = await teams.list();
    return result.teams.map((t) => t.$id).toList();
  }

  /// Returns true if the currently logged-in user is a member of the admin
  /// team. Returns false if there is no session, or membership lookup fails.
  ///
  /// Membership is matched against the team's **immutable ID** only.
  /// Matching by team name would let any user with team-create permission
  /// escalate to admin by creating a team called `admins`, so name matching
  /// is intentionally not supported.
  Future<bool> isCurrentUserAdmin() async {
    try {
      final teamIds = await _listTeamIds();
      const adminId = AppwriteConfig.adminTeamId;
      return teamIds.any((id) => id == adminId);
    } catch (e) {
      debugPrint('AdminAuth: membership lookup failed: $e');
      return false;
    }
  }

  /// Sign the user in via email + password and verify admin team membership.
  /// Returns true only if the session is created AND the account belongs to
  /// the admin team. On failure, any partial session is cleaned up.
  Future<bool> signInAsAdmin({
    required String email,
    required String password,
  }) async {
    try {
      // Make sure no stale session is in the way
      try {
        await _auth.account.deleteSession(sessionId: 'current');
      } catch (_) {}

      await _auth.account.createEmailPasswordSession(
        email: email.trim(),
        password: password,
      );

      final isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) {
        // Clean up — non-admin should not be left with a session created here.
        await _auth.signOut();
      }
      return isAdmin;
    } catch (e) {
      debugPrint('AdminAuth: sign-in failed: $e');
      return false;
    }
  }

  Future<void> signOut() => _auth.signOut();
}

final adminAuthServiceProvider = Provider<AdminAuthService>((ref) {
  return AdminAuthService(ref.watch(appwriteAuthServiceProvider));
});

/// Async source of truth for whether the current user is an admin.
/// Watch this in router guards and admin screens.
final adminAuthProvider = FutureProvider<bool>((ref) async {
  final svc = ref.watch(adminAuthServiceProvider);
  return svc.isCurrentUserAdmin();
});

/// Kept for legacy `sharedPreferencesProvider` consumers — DO NOT use this
/// for admin auth decisions. The override is set in main.dart.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});
