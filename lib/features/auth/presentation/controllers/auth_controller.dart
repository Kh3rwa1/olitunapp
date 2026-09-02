import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:itun/core/logging/app_logger.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../providers/auth_providers.dart';

/// Presentation-facing facade over [AuthRepository].
///
/// Screens depend on this controller instead of the repository directly,
/// keeping UI code free of data-layer references and giving business
/// classification rules (e.g. which auth failures deserve a user-visible
/// message) a single, testable home.
class AuthController {
  AuthController(this._ref);

  final Ref _ref;

  Future<Either<Failure, String>> sendOtp(String email) =>
      _ref.read(authRepositoryProvider).sendOtp(email);

  Future<Either<Failure, UserEntity>> verifyOtp({
    required String userId,
    required String secret,
  }) => _ref
      .read(authRepositoryProvider)
      .verifyOtp(userId: userId, secret: secret);

  Future<Either<Failure, UserEntity>> signInAnonymously() =>
      _ref.read(authRepositoryProvider).signInAnonymously();

  Future<Either<Failure, void>> signInWithGoogle() =>
      _ref.read(authRepositoryProvider).signInWithGoogle();

  Future<Either<Failure, bool>> isLoggedIn() =>
      _ref.read(authRepositoryProvider).isLoggedIn();

  /// Persists onboarding learning goals into user prefs when signed in.
  ///
  /// Silently tolerates guests and offline states — local settings already
  /// captured the goals.
  Future<void> syncLearningGoals(List<String> goals) async {
    try {
      final repo = _ref.read(authRepositoryProvider);
      final loggedIn = await repo.isLoggedIn();
      if (!loggedIn.getOrElse((_) => false)) return;

      final prefsResult = await repo.getUserPrefs();
      final newPrefs = Map<String, dynamic>.from(
        prefsResult.getOrElse((_) => <String, dynamic>{}),
      )..['learning_goals'] = goals;
      await repo.updateUserPrefs(newPrefs);
    } catch (e) {
      // Guest mode or network unavailable — goals stay in local settings,
      // but a failed authed prefs sync should be visible in logs.
      AppLogger.warning(
        'AuthController: learning goals sync failed: $e',
        name: 'AuthController',
      );
    }
  }

  /// Maps an OAuth sign-in failure to a user-facing snackbar message.
  ///
  /// Returns `null` when the failure should be swallowed silently (genuine
  /// user dismissal of the OAuth sheet).
  String? googleSignInUserMessage(Failure failure) {
    final msg = failure.message.toLowerCase();

    // Genuine user dismissal — silently ignore.
    if (msg.contains('canceled') && !msg.contains('appwrite')) return null;

    if (failure.message.contains('user_already_exists') ||
        (failure.code != null && failure.code == 409)) {
      return 'An account with this email already exists. '
          'Please sign in with Email instead.';
    }
    if (msg.contains('canceled') || msg.contains('cancelled')) {
      // OAuth sheet closed by the system (e.g. back-navigation) — no noise.
      return null;
    }
    return 'Google sign-in failed: ${failure.message}';
  }

  /// Maps a thrown exception from the OAuth flow to a user-facing message,
  /// or `null` when it should be swallowed silently.
  String? googleSignInExceptionMessage(Object error) {
    final errStr = error.toString().toLowerCase();
    if (errStr.contains('canceled') || errStr.contains('cancelled')) {
      return null;
    }
    return 'Google sign-in failed: '
        '${error.toString().replaceAll('Exception: ', '')}';
  }
}

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref);
});
