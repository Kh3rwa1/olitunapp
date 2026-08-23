import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/features/auth/domain/repositories/auth_repository.dart';
import 'package:itun/features/auth/presentation/controllers/auth_controller.dart';
import 'package:itun/features/auth/presentation/providers/auth_providers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = MockAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  AuthController controller() => container.read(authControllerProvider);

  group('googleSignInUserMessage', () {
    test('returns null for genuine user dismissal', () {
      final msg = controller().googleSignInUserMessage(
        const AuthFailure(message: 'User canceled the flow'),
      );
      expect(msg, isNull);
    });

    test('returns null for system-closed OAuth sheet variants', () {
      final msg = controller().googleSignInUserMessage(
        const AuthFailure(message: 'Request cancelled'),
      );
      expect(msg, isNull);
    });

    test('does not swallow Appwrite-reported cancellations', () {
      final msg = controller().googleSignInUserMessage(
        const AuthFailure(
          message: 'Appwrite canceled session: user_already_exists',
        ),
      );
      expect(msg, isNotNull);
    });

    test('maps duplicate account to email sign-in guidance', () {
      final msg = controller().googleSignInUserMessage(
        const ServerFailure(message: 'user_already_exists', code: 409),
      );
      expect(msg, contains('already exists'));
      expect(msg, contains('Email'));
    });

    test('maps code-only 409 to duplicate-account guidance', () {
      final msg = controller().googleSignInUserMessage(
        const ServerFailure(message: 'conflict', code: 409),
      );
      expect(msg, contains('already exists'));
    });

    test('wraps unknown failures with context', () {
      final msg = controller().googleSignInUserMessage(const NetworkFailure());
      expect(msg, startsWith('Google sign-in failed:'));
    });
  });

  group('googleSignInExceptionMessage', () {
    test('swallows cancellations', () {
      expect(
        controller().googleSignInExceptionMessage(Exception('cancelled')),
        isNull,
      );
    });

    test('strips Exception prefix from real errors', () {
      final msg = controller().googleSignInExceptionMessage(
        Exception('network unreachable'),
      );
      expect(msg, 'Google sign-in failed: network unreachable');
    });
  });

  group('syncLearningGoals', () {
    setUp(() {
      registerFallbackValue(<String, dynamic>{});
    });

    test('no-ops for guests without touching prefs', () async {
      when(() => repo.isLoggedIn()).thenAnswer((_) async => const Right(false));

      await controller().syncLearningGoals(['vocab']);

      verifyNever(() => repo.getUserPrefs());
      verifyNever(() => repo.updateUserPrefs(any()));
    });

    test('merges goals into existing prefs when signed in', () async {
      when(() => repo.isLoggedIn()).thenAnswer((_) async => const Right(true));
      when(() => repo.getUserPrefs()).thenAnswer(
        (_) async => const Right(<String, dynamic>{'script_mode': 'ol_chiki'}),
      );
      when(
        () => repo.updateUserPrefs(any()),
      ).thenAnswer((_) async => const Right(null));

      await controller().syncLearningGoals(['alphabet', 'numbers']);

      final captured =
          verify(() => repo.updateUserPrefs(captureAny())).captured.single
              as Map<String, dynamic>;
      expect(captured['script_mode'], 'ol_chiki');
      expect(captured['learning_goals'], ['alphabet', 'numbers']);
    });

    test('tolerates repository errors so onboarding can complete', () async {
      when(
        () => repo.isLoggedIn(),
      ).thenAnswer((_) async => const Left(ServerFailure(message: 'down')));

      await controller().syncLearningGoals(['reading']);

      verifyNever(() => repo.updateUserPrefs(any()));
    });
  });
}
