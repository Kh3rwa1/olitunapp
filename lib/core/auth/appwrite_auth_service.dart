import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:appwrite/enums.dart';
import 'package:flutter/foundation.dart';
import '../config/appwrite_config.dart';
import 'web_redirect.dart' as web_redirect;

class AppwriteAuthService {
  // Singleton pattern — one SDK Client shared across the app
  AppwriteAuthService._internal() {
    _client = Client()
      .setEndpoint(AppwriteConfig.endpoint)
      .setProject(AppwriteConfig.projectId)
      .setSelfSigned();

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
    return await _account.createSession(
      userId: userId,
      secret: secret,
    );
  }

  // ─── Google OAuth ───

  /// Sign in with Google OAuth2
  /// On web: redirects the entire page to Appwrite OAuth endpoint.
  /// On mobile: uses SDK popup/deep link.
  Future<void> signInWithGoogle() async {
    debugPrint('Appwrite: Starting Google OAuth');

    if (kIsWeb) {
      // Web: full-page redirect to Appwrite OAuth2 token endpoint.
      // After Google auth, Appwrite redirects back with ?userId=...&secret=...
      final origin = Uri.base.origin;
      final oauthUrl = '${AppwriteConfig.endpoint}/account/tokens/oauth2/google'
          '?project=${AppwriteConfig.projectId}'
          '&success=${Uri.encodeComponent(origin)}'
          '&failure=${Uri.encodeComponent('$origin/#/welcome')}'
          '&scopes[]=email&scopes[]=profile';
      
      // Navigate the entire page (not popup)
      _redirectToUrl(oauthUrl);
    } else {
      await _account.createOAuth2Session(
        provider: OAuthProvider.google,
      );
    }
  }

  /// Redirect the page (web only)
  void _redirectToUrl(String url) {
    web_redirect.redirectToUrl(url);
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
