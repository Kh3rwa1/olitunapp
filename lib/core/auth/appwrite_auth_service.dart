import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:appwrite/enums.dart';
import 'package:flutter/foundation.dart';

class AppwriteAuthService {
  static const String _endpoint = String.fromEnvironment(
    'APPWRITE_ENDPOINT',
    defaultValue: 'https://sgp.cloud.appwrite.io/v1',
  );
  static const String _projectId = String.fromEnvironment(
    'APPWRITE_PROJECT_ID',
    defaultValue: '699495910038e39622c5',
  );

  late final Client _client;
  late final Account _account;

  AppwriteAuthService() {
    _client = Client()
      .setEndpoint(_endpoint)
      .setProject(_projectId)
      .setSelfSigned(status: kDebugMode);

    _account = Account(_client);
  }

  Account get account => _account;
  Client get client => _client;

  /// Ping Appwrite backend to verify setup
  Future<void> ping() async {
    try {
      await _client.ping();
      debugPrint('Appwrite: Ping successful ✅');
    } catch (e) {
      debugPrint('Appwrite: Ping failed ❌ $e');
    }
  }

  // ─── Email OTP ───

  /// Send OTP code to email. Returns userId needed for session creation.
  Future<models.Token> sendOtpCode(String email) async {
    final trimmedEmail = email.trim().toLowerCase();
    debugPrint('Appwrite: Sending OTP to $trimmedEmail');
    return await _account.createEmailToken(
      userId: ID.unique(),
      email: trimmedEmail,
    );
  }

  /// Verify OTP and create session
  Future<models.Session> verifyOtp({
    required String userId,
    required String secret,
  }) async {
    debugPrint('Appwrite: Verifying OTP for user $userId');
    return await _account.createSession(
      userId: userId,
      secret: secret,
    );
  }

  // ─── Google OAuth ───

  /// Sign in with Google OAuth2
  Future<void> signInWithGoogle() async {
    debugPrint('Appwrite: Starting Google OAuth');

    if (kIsWeb) {
      // Web: need explicit redirect URLs
      final origin = Uri.base.origin; // e.g. https://olitun.in
      await _account.createOAuth2Session(
        provider: OAuthProvider.google,
        success: '$origin/home',
        failure: '$origin/welcome',
      );
    } else {
      // Mobile: uses deep link callback automatically
      await _account.createOAuth2Session(
        provider: OAuthProvider.google,
      );
    }
  }

  // ─── Session Management ───

  /// Check if user has an active session
  Future<bool> isLoggedIn() async {
    try {
      await _account.getSession(sessionId: 'current');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Get current user profile
  Future<models.User> getMe() async {
    return await _account.get();
  }

  /// Update user display name
  Future<models.User> updateName(String name) async {
    return await _account.updateName(name: name);
  }

  /// Update user preferences (for progress sync)
  Future<void> updatePrefs(Map<String, dynamic> prefs) async {
    await _account.updatePrefs(prefs: prefs);
  }

  /// Get user preferences
  Future<models.Preferences> getPrefs() async {
    return await _account.getPrefs();
  }

  /// Sign out — delete current session
  Future<void> signOut() async {
    try {
      await _account.deleteSession(sessionId: 'current');
    } catch (e) {
      debugPrint('Appwrite: Sign out error: $e');
    }
  }

  /// Delete user account permanently
  Future<void> deleteAccount() async {
    await _account.updateStatus();
    await signOut();
  }
}
