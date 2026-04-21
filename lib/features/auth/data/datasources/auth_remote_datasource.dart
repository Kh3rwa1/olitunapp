import 'package:appwrite/enums.dart';
import 'package:appwrite/appwrite.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signUpWithEmail({required String email, required String password, String? name});
  Future<UserModel> signInWithEmail({required String email, required String password});
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
  Future<bool> isLoggedIn();
  Future<void> sendVerificationEmail();
  Future<void> deleteAccount();
  Future<void> updateDisplayName(String name);
  Future<String> sendOtp(String email);
  Future<UserModel> verifyOtp({required String userId, required String secret});
  Future<void> signInWithGoogle();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Account account;

  AuthRemoteDataSourceImpl(this.account);

  @override
  Future<UserModel> signUpWithEmail({required String email, required String password, String? name}) async {
    try {
      await account.create(userId: ID.unique(), email: email, password: password, name: name);
      return await signInWithEmail(email: email, password: password);
    } on AppwriteException catch (e) {
      throw ServerException(message: e.message ?? 'Sign up failed', code: e.code);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<UserModel> signInWithEmail({required String email, required String password}) async {
    try {
      await account.createEmailPasswordSession(email: email, password: password);
      final user = await account.get();
      return UserModel.fromJson(user.toMap());
    } on AppwriteException catch (e) {
      throw ServerException(message: e.message ?? 'Sign in failed', code: e.code);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await account.deleteSession(sessionId: 'current');
    } on AppwriteException catch (e) {
      throw ServerException(message: e.message ?? 'Sign out failed', code: e.code);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = await account.get();
      return UserModel.fromJson(user.toMap());
    } on AppwriteException catch (e) {
      if (e.code == 401) return null;
      throw ServerException(message: e.message ?? 'Failed to get user', code: e.code);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    try {
      await account.getSession(sessionId: 'current');
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> sendVerificationEmail() async {
    try {
      await account.createEmailVerification(url: 'https://olitun.app/verify');
    } on AppwriteException catch (e) {
      throw ServerException(message: e.message ?? 'Verification failed', code: e.code);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await account.updateStatus();
    } on AppwriteException catch (e) {
      throw ServerException(message: e.message ?? 'Delete account failed', code: e.code);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> updateDisplayName(String name) async {
    try {
      await account.updateName(name: name);
    } on AppwriteException catch (e) {
      throw ServerException(message: e.message ?? 'Update name failed', code: e.code);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<String> sendOtp(String email) async {
    try {
      final token = await account.createEmailToken(userId: ID.unique(), email: email.trim().toLowerCase());
      return token.userId;
    } on AppwriteException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to send OTP', code: e.code);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<UserModel> verifyOtp({required String userId, required String secret}) async {
    try {
      await account.createSession(userId: userId, secret: secret);
      final user = await account.get();
      return UserModel.fromJson(user.toMap());
    } on AppwriteException catch (e) {
      throw ServerException(message: e.message ?? 'OTP verification failed', code: e.code);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      await account.createOAuth2Session(provider: OAuthProvider.google);
    } on AppwriteException catch (e) {
      throw ServerException(message: e.message ?? 'Google sign in failed', code: e.code);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
