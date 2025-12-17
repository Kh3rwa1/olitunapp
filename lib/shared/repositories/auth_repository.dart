import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';

/// Repository for authentication operations
class AuthRepository {
  final FirebaseService _firebase = FirebaseService.instance;

  // Current user
  User? get currentUser => _firebase.currentUser;
  String? get currentUserId => _firebase.currentUserId;
  bool get isAuthenticated => _firebase.isAuthenticated;

  // Auth state stream
  Stream<User?> get authStateChanges => _firebase.authStateChanges;

  /// Sign in with email and password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      final credential = await _firebase.auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update last active
      if (credential.user != null) {
        await _updateLastActive(credential.user!.uid);
      }
      
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Create account with email and password
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    String level = 'beginner',
    String scriptMode = 'both',
    String themeMode = 'system',
  }) async {
    try {
      final credential = await _firebase.auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(displayName);

      // Create user document in Firestore
      if (credential.user != null) {
        await _createUserDocument(
          credential.user!,
          displayName: displayName,
          level: level,
          scriptMode: scriptMode,
          themeMode: themeMode,
        );
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Create user document in Firestore
  Future<void> _createUserDocument(
    User user, {
    required String displayName,
    required String level,
    required String scriptMode,
    required String themeMode,
  }) async {
    final userModel = UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: displayName,
      role: 'user',
      preferences: UserPreferences(
        level: level,
        scriptMode: scriptMode,
        themeMode: themeMode,
      ),
      stats: UserStats(),
      createdAt: DateTime.now(),
    );

    await _firebase.usersCollection.doc(user.uid).set(userModel.toFirestore());
  }

  /// Update last active timestamp
  Future<void> _updateLastActive(String userId) async {
    try {
      await _firebase.usersCollection.doc(userId).update({
        'lastActiveAt': DateTime.now(),
      });
    } catch (e) {
      // Ignore errors for last active update
      if (kDebugMode) {
        debugPrint('Failed to update last active: $e');
      }
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _firebase.auth.signOut();
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebase.auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Get user role from Firestore
  Future<String> getUserRole(String userId) async {
    try {
      final doc = await _firebase.usersCollection.doc(userId).get();
      if (doc.exists) {
        return doc.data()?['role'] as String? ?? 'user';
      }
      return 'user';
    } catch (e) {
      return 'user';
    }
  }

  /// Check if user is admin
  Future<bool> isUserAdmin(String? userId) async {
    if (userId == null) return false;
    final role = await getUserRole(userId);
    return role == 'admin';
  }

  /// Handle Firebase Auth errors
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled.';
      case 'weak-password':
        return 'Please use a stronger password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}
