import 'package:appwrite/models.dart' as models;
import '../../core/auth/appwrite_auth_service.dart';

class AuthRepository {
  final AppwriteAuthService _appwrite;

  AuthRepository(this._appwrite);

  /// Send OTP code to user's email. Returns token with userId.
  Future<models.Token> sendOtp(String email) async {
    return await _appwrite.sendOtpCode(email);
  }

  /// Verify OTP code and create session
  Future<models.Session> verifyOtp({
    required String userId,
    required String secret,
  }) async {
    return await _appwrite.verifyOtp(userId: userId, secret: secret);
  }

  /// Sign in with Google OAuth2
  Future<void> signInWithGoogle() async {
    await _appwrite.signInWithGoogle();
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await _appwrite.isLoggedIn();
  }

  /// Get current user profile
  Future<models.User> getMe() async {
    return await _appwrite.getMe();
  }

  /// Update user display name
  Future<void> updateDisplayName(String name) async {
    await _appwrite.updateName(name);
  }

  /// Update user preferences (for progress sync)
  Future<void> updatePrefs(Map<String, dynamic> prefs) async {
    await _appwrite.updatePrefs(prefs);
  }

  /// Get user preferences
  Future<models.Preferences> getPrefs() async {
    return await _appwrite.getPrefs();
  }

  /// Sign out and clear session
  Future<void> signOut() async {
    await _appwrite.signOut();
  }

  /// Delete current user account permanently
  Future<void> deleteAccount() async {
    await _appwrite.deleteAccount();
  }
}
