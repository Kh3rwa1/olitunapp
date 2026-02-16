import '../../../core/auth/stack_auth_service.dart';

class AuthRepository {
  final StackAuthService _stackAuth;

  AuthRepository(this._stackAuth);

  /// Send OTP code to user's email
  Future<void> sendOtp(String email) async {
    await _stackAuth.sendOtpCode(email);
  }

  /// Verify OTP code and authenticate user
  Future<Map<String, dynamic>> verifyOtp(String code) async {
    return await _stackAuth.verifyOtp(code);
  }

  /// Sign out and clear tokens
  Future<void> signOut() async {
    await _stackAuth.signOut();
  }

  /// Get current user profile
  Future<Map<String, dynamic>> getMe() async {
    return await _stackAuth.getMe();
  }

  /// Update user metadata (for progress sync)
  Future<void> updateMetadata(Map<String, dynamic> metadata) async {
    await _stackAuth.updateMetadata(metadata);
  }

  /// Update user profile name
  Future<void> updateDisplayName(String name) async {
    await _stackAuth.updateProfile({'display_name': name});
  }

  /// Get stored auth token
  Future<String?> getToken() async => await _stackAuth.token;
}
