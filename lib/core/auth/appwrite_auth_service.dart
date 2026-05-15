import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:appwrite/enums.dart';
import 'package:flutter/foundation.dart';
import '../config/appwrite_config.dart';

class AppwriteAuthService {
  // Singleton pattern — one SDK Client shared across the app
  AppwriteAuthService._internal() {
    _client = Client()
        .setEndpoint(AppwriteConfig.endpoint)
        .setProject(AppwriteConfig.projectId);

    if (const bool.fromEnvironment('ALLOW_SELF_SIGNED')) {
      _client.setSelfSigned();
    }

    _account = Account(_client);
  }

  static final AppwriteAuthService _instance = AppwriteAuthService._internal();
  factory AppwriteAuthService() => _instance;

  late final Client _client;
  late final Account _account;

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
    return await _account.createSession(userId: userId, secret: secret);
  }

  // ─── Google OAuth ───

  /// Sign in with Google OAuth2
  /// Uses the Appwrite SDK's built-in OAuth2 session flow on all platforms.
  /// On mobile: opens a browser, then deep-links back via appwrite-callback-{projectId}.
  /// On web: redirects the page, then returns with session cookie.
  Future<void> signInWithGoogle() async {
    debugPrint('Appwrite: Starting Google OAuth');

    if (kIsWeb) {
      final origin = Uri.base.origin;
      await _account.createOAuth2Session(
        provider: OAuthProvider.google,
        success: origin,
        failure: '$origin/#/welcome',
        scopes: ['email', 'profile'],
      );
    } else {
      await _account.createOAuth2Session(provider: OAuthProvider.google);
    }
  }

  /// Exchange OAuth token for session (called from splash screen after redirect)
  Future<bool> exchangeOAuthToken(String userId, String secret) async {
    try {
      await _account.createSession(userId: userId, secret: secret);
      debugPrint('Appwrite: OAuth session created ✅');
      return true;
    } catch (e) {
      debugPrint('Appwrite: Failed to create session from token: $e');
      return false;
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

final appwriteAuthServiceProvider = Provider<AppwriteAuthService>((ref) {
  return AppwriteAuthService();
});
