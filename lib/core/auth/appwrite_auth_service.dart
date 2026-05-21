import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:appwrite/enums.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../config/appwrite_config.dart';

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

class AppwriteAuthService {
  static const String _webSessionSecretKey = 'olitun_appwrite_session_secret';

  // Singleton pattern — one SDK Client shared across the app
  AppwriteAuthService._internal() {
    _client = Client()
        .setEndpoint(AppwriteConfig.endpoint)
        .setProject(AppwriteConfig.projectId);

    if (const bool.fromEnvironment('ALLOW_SELF_SIGNED')) {
      _client.setSelfSigned();
    }

    _account = Account(_client);
    _functions = Functions(_client);
  }

  static final AppwriteAuthService _instance = AppwriteAuthService._internal();
  factory AppwriteAuthService() => _instance;

  late final Client _client;
  late final Account _account;
  late final Functions _functions;

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
  /// On web: opens a popup, returns through /auth.html, then stores the session.
  Future<void> signInWithGoogle() async {
    debugPrint('Appwrite: Starting Google OAuth');

    try {
      if (kIsWeb) {
        final origin = Uri.base.origin;
        final result = await _account.createOAuth2Session(
          provider: OAuthProvider.google,
          success: '$origin/splash',
          failure: '$origin/welcome',
          scopes: ['email', 'profile'],
        );
        await _completeWebOAuth(result);
      } else {
        final deepLink = 'appwrite-callback-${AppwriteConfig.projectId}://';
        await _account.createOAuth2Session(
          provider: OAuthProvider.google,
          success: deepLink,
          failure: deepLink,
          scopes: ['email', 'profile'],
        );
      }
    } on AppwriteException catch (e) {
      debugPrint(
        'Appwrite OAuth RAW ERROR: message="${e.message}" code=${e.code} type="${e.type}"',
      );
      throw AppwriteException(
        googleOAuthUserMessage(e.message ?? e.toString()),
        e.code,
        e.type,
      );
    }
  }

  /// Exchange OAuth token for session (called from splash screen after redirect)
  Future<bool> exchangeOAuthToken(String userId, String secret) async {
    try {
      if (userId.startsWith('a_session_')) {
        await _persistWebSession(secret);
      } else {
        await _account.createSession(userId: userId, secret: secret);
      }
      debugPrint('Appwrite: OAuth session created ✅');
      return true;
    } catch (e) {
      debugPrint('Appwrite: Failed to create session from token: $e');
      return false;
    }
  }

  Future<void> _completeWebOAuth(Object? result) async {
    if (!kIsWeb || result is! String || result.isEmpty) return;

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
      throw AppwriteException(
        'Invalid OAuth2 response. Missing session secret.',
      );
    }

    if (key != null && key.startsWith('a_session_')) {
      await _persistWebSession(secret);
      return;
    }

    if (userId != null && userId.isNotEmpty) {
      await _account.createSession(userId: userId, secret: secret);
      return;
    }

    throw AppwriteException('Invalid OAuth2 response. Missing session key.');
  }

  Future<void> _persistWebSession(String secret) async {
    _client.setSession(secret);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_webSessionSecretKey, secret);
  }

  Future<void> _restoreWebSession() async {
    if (!kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    final secret = prefs.getString(_webSessionSecretKey);
    if (secret != null && secret.isNotEmpty) {
      _client.setSession(secret);
    }
  }

  Future<void> _clearWebSession() async {
    if (!kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_webSessionSecretKey);
  }

  Future<void> _clearLocalSessionState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasLocalSessionKey, false);
    await _clearWebSession();
  }

  static const String _hasLocalSessionKey = 'olitun_has_local_session';

  // ─── Session Management ───

  /// Check if user has an active session
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      if (connectivityResults.contains(ConnectivityResult.none)) {
        final hasLocal = prefs.getBool(_hasLocalSessionKey) ?? false;
        debugPrint(
          'Appwrite: Device is offline. Returning cached session: $hasLocal',
        );
        return hasLocal;
      }
    } catch (e) {
      debugPrint('Appwrite: Error checking connectivity: $e');
    }

    try {
      if (kIsWeb) {
        await _restoreWebSession();
      }
      final session = await _account
          .getSession(sessionId: 'current')
          .timeout(const Duration(seconds: 3));
      debugPrint('Appwrite: Session active for user ${session.userId} ✅');
      await prefs.setBool(_hasLocalSessionKey, true);
      return true;
    } catch (e) {
      debugPrint('Appwrite: isLoggedIn error: $e');

      // If it's a network error or timeout, and we know we had a session,
      // return true optimistically to avoid kicking the user to login.
      final hasLocal = prefs.getBool(_hasLocalSessionKey) ?? false;
      if (hasLocal) {
        if (e is AppwriteException) {
          // code 0 or empty type often indicates network/timeout issues in Appwrite SDK
          if (e.code == 0 || e.type == '' || e.type == 'general_unknown') {
            debugPrint(
              'Appwrite: Network error, but had local session. Returning true.',
            );
            return true;
          }
        } else if (e.toString().contains('SocketException') ||
            e.toString().contains('TimeoutException')) {
          debugPrint(
            'Appwrite: Socket/Timeout error, but had local session. Returning true.',
          );
          return true;
        }
      }

      // If it's a 401 (Unauthorized), the session is definitely gone.
      if (e is AppwriteException && e.code == 401) {
        debugPrint('Appwrite: Session expired (401). Clearing local flag.');
        await prefs.setBool(_hasLocalSessionKey, false);
      }

      return false;
    }
  }

  /// Get current user profile
  Future<models.User> getMe() async {
    final connectivityResults = await Connectivity().checkConnectivity();
    if (connectivityResults.contains(ConnectivityResult.none)) {
      throw AppwriteException('No internet connection', 0, 'network_failure');
    }
    await _restoreWebSession();
    return await _account.get().timeout(const Duration(seconds: 3));
  }

  /// Update user display name
  Future<models.User> updateName(String name) async {
    final connectivityResults = await Connectivity().checkConnectivity();
    if (connectivityResults.contains(ConnectivityResult.none)) {
      throw AppwriteException('No internet connection', 0, 'network_failure');
    }
    return await _account
        .updateName(name: name)
        .timeout(const Duration(seconds: 3));
  }

  /// Update user preferences (for progress sync)
  Future<void> updatePrefs(Map<String, dynamic> prefs) async {
    final connectivityResults = await Connectivity().checkConnectivity();
    if (connectivityResults.contains(ConnectivityResult.none)) {
      throw AppwriteException('No internet connection', 0, 'network_failure');
    }
    await _account
        .updatePrefs(prefs: prefs)
        .timeout(const Duration(seconds: 3));
  }

  /// Get user preferences
  Future<models.Preferences> getPrefs() async {
    final connectivityResults = await Connectivity().checkConnectivity();
    if (connectivityResults.contains(ConnectivityResult.none)) {
      throw AppwriteException('No internet connection', 0, 'network_failure');
    }
    return await _account.getPrefs().timeout(const Duration(seconds: 3));
  }

  /// Sign out — delete current session
  Future<void> signOut() async {
    try {
      await _restoreWebSession();
      await _account
          .deleteSession(sessionId: 'current')
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Appwrite: Sign out error: $e');
    } finally {
      await _clearLocalSessionState();
    }
  }

  /// Permanently delete the user account from Appwrite and clear all local state.
  ///
  /// Calls the 'delete-account' Cloud Function to hard-delete the user record,
  /// making it possible to sign in again with the same email or OAuth provider without
  /// hitting a "user already exists" / session conflict.
  Future<void> deleteAccount() async {
    try {
      await _restoreWebSession();
      // Hard-delete the account using our Cloud Function so OAuth (Google)
      // can create a fresh user record on the next sign-in without conflict.
      await _functions.createExecution(functionId: 'delete-account');
    } on AppwriteException catch (e) {
      debugPrint('Appwrite: deleteAccount error: $e');
      // If delete fails, still try to clean up session
      try {
        await _account.deleteSession(sessionId: 'current');
      } catch (_) {}
    } finally {
      await _clearLocalSessionState();
    }
  }
}

final appwriteAuthServiceProvider = Provider<AppwriteAuthService>((ref) {
  return AppwriteAuthService();
});
