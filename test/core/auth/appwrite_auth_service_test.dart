import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:appwrite/enums.dart' as enums;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/core/auth/appwrite_auth_service.dart';

class MockClient extends Mock implements Client {}

class MockAccount extends Mock implements Account {}

class MockFunctions extends Mock implements Functions {}

class MockExecution extends Mock implements models.Execution {}

class MockSession extends Mock implements models.Session {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockClient mockClient;
  late MockAccount mockAccount;
  late MockFunctions mockFunctions;
  late MockExecution mockExecution;

  setUp(() {
    mockClient = MockClient();
    mockAccount = MockAccount();
    mockFunctions = MockFunctions();
    mockExecution = MockExecution();

    SharedPreferences.setMockInitialValues({});
  });

  group('parseAccountDeletionExecution', () {
    test(
      '1. HTTP 500 with authDeleted: true returns authDeletedReconciliationPending',
      () {
        final result = parseAccountDeletionExecution(
          status: 'completed',
          statusCode: 500,
          responseBody:
              '{"ok": false, "authDeleted": true, "code": "cleanup_partial_failure"}',
        );

        expect(
          result.kind,
          AccountDeletionOutcomeKind.authDeletedReconciliationPending,
        );
        expect(result.isAuthDeleted, isTrue);
        expect(result.isFullSuccess, isFalse);
        expect(result.statusCode, 500);
        expect(result.errorMessage, contains('reconciliation is pending'));
      },
    );

    test('2. HTTP 500 without authDeleted: true returns failed', () {
      final result = parseAccountDeletionExecution(
        status: 'failed',
        statusCode: 500,
        responseBody:
            '{"ok": false, "authDeleted": false, "code": "database_error"}',
      );

      expect(result.kind, AccountDeletionOutcomeKind.failed);
      expect(result.isAuthDeleted, isFalse);
      expect(result.isFullSuccess, isFalse);
      expect(result.statusCode, 500);
      expect(result.errorMessage, 'database_error');
    });

    test('3. HTTP 2xx with ok: true returns completed outcome', () {
      final result = parseAccountDeletionExecution(
        status: 'completed',
        statusCode: 200,
        responseBody: '{"ok": true, "authDeleted": true}',
      );

      expect(result.kind, AccountDeletionOutcomeKind.completed);
      expect(result.isAuthDeleted, isTrue);
      expect(result.isFullSuccess, isTrue);
      expect(result.statusCode, 200);
    });

    test('4. Empty response fails closed as malformed', () {
      final result = parseAccountDeletionExecution(
        status: 'completed',
        statusCode: 200,
        responseBody: '',
      );

      expect(result.kind, AccountDeletionOutcomeKind.malformed);
      expect(result.isAuthDeleted, isFalse);
      expect(result.isFullSuccess, isFalse);
    });

    test(
      '5. Malformed JSON fails closed as malformed without leaking raw body',
      () {
        final result = parseAccountDeletionExecution(
          status: 'completed',
          statusCode: 200,
          responseBody: '{invalid json body}',
        );

        expect(result.kind, AccountDeletionOutcomeKind.malformed);
        expect(result.isAuthDeleted, isFalse);
        expect(result.isFullSuccess, isFalse);
        expect(result.errorMessage, isNot(contains('{invalid json body}')));
      },
    );

    test('6. Non-object JSON fails closed as malformed', () {
      final result = parseAccountDeletionExecution(
        status: 'completed',
        statusCode: 200,
        responseBody: '["item1", "item2"]',
      );

      expect(result.kind, AccountDeletionOutcomeKind.malformed);
      expect(result.isAuthDeleted, isFalse);
      expect(result.isFullSuccess, isFalse);
    });
  });

  group('AppwriteAuthService Session & Deletion Invariants', () {
    test(
      '7. Missing secret with stale in-memory session clears session on isLoggedIn',
      () async {
        SharedPreferences.setMockInitialValues({
          'olitun_has_local_session': true,
        });
        final prefs = await SharedPreferences.getInstance();

        when(() => mockClient.setSession(any())).thenReturn(mockClient);
        when(
          () => mockAccount.getSession(sessionId: 'current'),
        ).thenThrow(AppwriteException('Unauthorized', 401));

        final service = AppwriteAuthService.forTesting(
          client: mockClient,
          account: mockAccount,
          functions: mockFunctions,
          prefs: prefs,
          isWebOverride: true,
        );

        final loggedIn = await service.isLoggedIn();
        expect(loggedIn, isFalse);
        expect(prefs.getBool('olitun_has_local_session'), isFalse);
        verifyNever(() => mockClient.setSession(''));
      },
    );

    test(
      '8. Secret with missing timestamp clears persisted keys and SDK session',
      () async {
        SharedPreferences.setMockInitialValues({
          'olitun_has_local_session': true,
          'olitun_appwrite_session_secret': 'secret-123',
        });
        final prefs = await SharedPreferences.getInstance();

        when(() => mockClient.setSession(any())).thenReturn(mockClient);
        when(
          () => mockAccount.getSession(sessionId: 'current'),
        ).thenThrow(AppwriteException('Unauthorized', 401));

        final service = AppwriteAuthService.forTesting(
          client: mockClient,
          account: mockAccount,
          functions: mockFunctions,
          prefs: prefs,
          isWebOverride: true,
        );

        final loggedIn = await service.isLoggedIn();

        expect(loggedIn, isFalse);
        expect(prefs.getString('olitun_appwrite_session_secret'), isNull);
        expect(prefs.getInt('olitun_web_session_ts'), isNull);
        verify(() => mockClient.setSession('')).called(greaterThanOrEqualTo(1));
      },
    );

    test(
      '9. Expired, negative, zero, and future timestamps clear session state',
      () async {
        final now = DateTime(2026, 8, 9, 12, 0);

        // Expired (> 24 hours ago)
        expect(
          isWebSessionValidTimestamp(
            now.subtract(const Duration(hours: 25)).millisecondsSinceEpoch,
            nowOverride: now,
          ),
          isFalse,
        );

        // Negative & Zero
        expect(isWebSessionValidTimestamp(-100, nowOverride: now), isFalse);
        expect(isWebSessionValidTimestamp(0, nowOverride: now), isFalse);

        // Future beyond 1 min skew (> +60s)
        expect(
          isWebSessionValidTimestamp(
            now.add(const Duration(seconds: 70)).millisecondsSinceEpoch,
            nowOverride: now,
          ),
          isFalse,
        );

        // Within 1 min future skew is allowed
        expect(
          isWebSessionValidTimestamp(
            now.add(const Duration(seconds: 30)).millisecondsSinceEpoch,
            nowOverride: now,
          ),
          isTrue,
        );
      },
    );

    test(
      '10. Valid timestamp within 24 hours restores session normally',
      () async {
        final now = DateTime(2026, 8, 9, 12, 0);
        final validTs = now
            .subtract(const Duration(hours: 2))
            .millisecondsSinceEpoch;

        SharedPreferences.setMockInitialValues({
          'olitun_has_local_session': true,
          'olitun_appwrite_session_secret': 'valid-secret',
          'olitun_web_session_ts': validTs,
        });
        final prefs = await SharedPreferences.getInstance();

        when(
          () => mockClient.setSession('valid-secret'),
        ).thenReturn(mockClient);
        final mockSession = MockSession();
        when(() => mockSession.userId).thenReturn('user-123');

        when(
          () => mockAccount.getSession(sessionId: 'current'),
        ).thenAnswer((_) async => mockSession);

        final service = AppwriteAuthService.forTesting(
          client: mockClient,
          account: mockAccount,
          functions: mockFunctions,
          prefs: prefs,
          nowProvider: () => now,
          isWebOverride: true,
        );

        final loggedIn = await service.isLoggedIn();
        expect(loggedIn, isTrue);
        verify(
          () => mockClient.setSession('valid-secret'),
        ).called(greaterThanOrEqualTo(1));
      },
    );

    test(
      '11. deleteAccount HTTP 500 with authDeleted: true clears local session state',
      () async {
        SharedPreferences.setMockInitialValues({
          'olitun_has_local_session': true,
          'olitun_appwrite_session_secret': 'secret',
          'olitun_web_session_ts': DateTime.now().millisecondsSinceEpoch,
        });
        final prefs = await SharedPreferences.getInstance();

        when(() => mockClient.setSession(any())).thenReturn(mockClient);
        when(
          () => mockExecution.status,
        ).thenReturn(enums.ExecutionStatus.completed);
        when(() => mockExecution.responseStatusCode).thenReturn(500);
        when(
          () => mockExecution.responseBody,
        ).thenReturn('{"ok": false, "authDeleted": true}');

        when(
          () => mockFunctions.createExecution(functionId: 'delete-account'),
        ).thenAnswer((_) async => mockExecution);

        final service = AppwriteAuthService.forTesting(
          client: mockClient,
          account: mockAccount,
          functions: mockFunctions,
          prefs: prefs,
          isWebOverride: true,
        );

        expect(
          () => service.deleteAccount(),
          throwsA(
            isA<AppwriteException>().having(
              (e) => e.message,
              'message',
              contains('reconciliation is pending'),
            ),
          ),
        );

        await Future.delayed(Duration.zero);
        expect(prefs.getBool('olitun_has_local_session'), isFalse);
      },
    );

    test(
      '12. deleteAccount HTTP 500 without authDeleted: true preserves local state',
      () async {
        SharedPreferences.setMockInitialValues({
          'olitun_has_local_session': true,
          'olitun_appwrite_session_secret': 'secret',
          'olitun_web_session_ts': DateTime.now().millisecondsSinceEpoch,
        });
        final prefs = await SharedPreferences.getInstance();

        when(() => mockClient.setSession(any())).thenReturn(mockClient);
        when(
          () => mockExecution.status,
        ).thenReturn(enums.ExecutionStatus.failed);
        when(() => mockExecution.responseStatusCode).thenReturn(500);
        when(() => mockExecution.responseBody).thenReturn(
          '{"ok": false, "authDeleted": false, "message": "server error"}',
        );

        when(
          () => mockFunctions.createExecution(functionId: 'delete-account'),
        ).thenAnswer((_) async => mockExecution);

        final service = AppwriteAuthService.forTesting(
          client: mockClient,
          account: mockAccount,
          functions: mockFunctions,
          prefs: prefs,
          isWebOverride: true,
        );

        expect(
          () => service.deleteAccount(),
          throwsA(isA<AppwriteException>()),
        );

        await Future.delayed(Duration.zero);
        expect(prefs.getBool('olitun_has_local_session'), isTrue);
      },
    );
  });
}
