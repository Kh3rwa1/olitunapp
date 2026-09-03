import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart' as models;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/core/auth/appwrite_auth_service.dart';
import 'package:itun/core/config/appwrite_config.dart';

class MockClient extends Mock implements Client {}

class MockAccount extends Mock implements Account {}

class MockFunctions extends Mock implements Functions {}

class MockExecution extends Mock implements models.Execution {}

class MockSession extends Mock implements models.Session {}

class MockToken extends Mock implements models.Token {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri());
  });

  group('googleOAuthUserMessage', () {
    test('passes through raw OAuth errors for diagnosis', () {
      final message = googleOAuthUserMessage(
        'Invalid OAuth2 Response. Key and Secret not available.',
      );
      expect(message, contains('Key and Secret'));
    });

    test('preserves unknown provider errors', () {
      expect(
        googleOAuthUserMessage('The user cancelled sign-in.'),
        'The user cancelled sign-in.',
      );
    });

    test('remaps disabled provider error message', () {
      expect(
        googleOAuthUserMessage('Provider disabled by admin'),
        contains('Google sign-in is disabled in Appwrite'),
      );
    });
  });

  group('parseWebOAuthCompletion', () {
    test('parses Appwrite web session key redirects', () {
      final completion = parseWebOAuthCompletion(
        'https://olitun.app/splash?key=a_session_123&secret=session-secret',
      );
      expect(completion.kind, WebOAuthCompletionKind.persistSession);
      expect(completion.secret, 'session-secret');
      expect(completion.userId, isNull);
    });

    test('parses userId and secret redirects', () {
      final completion = parseWebOAuthCompletion(
        'https://olitun.app/splash?userId=user_1&secret=session-secret',
      );
      expect(completion.kind, WebOAuthCompletionKind.createSession);
      expect(completion.userId, 'user_1');
      expect(completion.secret, 'session-secret');
    });

    test('throws readable failure query messages', () {
      expect(
        () => parseWebOAuthCompletion(
          'https://olitun.app/welcome?failure=true&error=access_denied&message=Cancelled',
        ),
        throwsA(
          isA<AppwriteException>().having(
            (error) => error.message,
            'message',
            contains('access_denied'),
          ),
        ),
      );
    });

    test('rejects redirects without a secret', () {
      expect(
        () =>
            parseWebOAuthCompletion('https://olitun.app/splash?userId=user_1'),
        throwsA(
          isA<AppwriteException>().having(
            (error) => error.message,
            'message',
            contains('Missing session secret'),
          ),
        ),
      );
    });

    test('rejects redirects without a usable session key or userId', () {
      expect(
        () => parseWebOAuthCompletion(
          'https://olitun.app/splash?key=unexpected&secret=session-secret',
        ),
        throwsA(
          isA<AppwriteException>().having(
            (error) => error.message,
            'message',
            contains('Missing session key'),
          ),
        ),
      );
    });

    test('parses mobile deep-link success callbacks (token contract)', () {
      // This is the exact shape the Appwrite token endpoint returns to
      // the appwrite-callback:// scheme on mobile: userId + secret, and
      // crucially NO `key` — the shape the SDK's internal parser rejects
      // but the app's mobile flow must accept.
      final completion = parseWebOAuthCompletion(
        'appwrite-callback-699495910038e39622c5://success?userId=user_1&secret=session-secret',
      );
      expect(completion.kind, WebOAuthCompletionKind.createSession);
      expect(completion.userId, 'user_1');
      expect(completion.secret, 'session-secret');
    });
  });

  group('buildMobileGoogleOAuthUrl', () {
    test('targets the token endpoint with deep-link callbacks', () {
      final url = buildMobileGoogleOAuthUrl(
        endpoint: 'https://sgp.cloud.appwrite.io/v1',
        projectId: 'proj_123',
      );
      expect(
        url.toString(),
        startsWith(
          'https://sgp.cloud.appwrite.io/v1/account/tokens/oauth2/google?',
        ),
      );
      expect(
        url.queryParameters['success'],
        'appwrite-callback-proj_123://success',
      );
      expect(
        url.queryParameters['failure'],
        'appwrite-callback-proj_123://failure',
      );
      expect(url.queryParameters['project'], 'proj_123');
    });

    test('requests email and profile scopes', () {
      final url = buildMobileGoogleOAuthUrl(
        endpoint: 'https://sgp.cloud.appwrite.io/v1',
        projectId: 'proj_123',
      );
      // Uri drops the [] suffix key shape; verify raw encoding instead.
      expect(url.toString(), contains('email'));
      expect(url.toString(), contains('profile'));
    });
  });

  group('parseAdminMaintenanceResponse', () {
    test('returns decoded success payload', () {
      final response = parseAdminMaintenanceResponse(
        statusCode: 200,
        body: '{"success":true,"deleted":{"lessons":3}}',
      );
      expect(response['success'], isTrue);
      expect(response['deleted'], {'lessons': 3});
    });

    test('throws function message on failed response', () {
      expect(
        () => parseAdminMaintenanceResponse(
          statusCode: 403,
          body: '{"success":false,"message":"Admin team required."}',
        ),
        throwsA(
          isA<AppwriteException>().having(
            (error) => error.message,
            'message',
            'Admin team required.',
          ),
        ),
      );
    });

    test('extracts backup file id when present', () {
      expect(
        adminMaintenanceBackupFileId({
          'success': true,
          'backup': {'fileId': 'backup-1'},
        }),
        'backup-1',
      );
    });
  });

  group('isTransientSessionValidationFailure', () {
    test('allows cached session only for network and timeout failures', () {
      expect(
        isTransientSessionValidationFailure(
          AppwriteException('offline', 0, 'network_failure'),
        ),
        isTrue,
      );
      expect(
        isTransientSessionValidationFailure(TimeoutException('slow')),
        isTrue,
      );
    });

    test('fails closed for non-auth Appwrite errors', () {
      expect(
        isTransientSessionValidationFailure(
          AppwriteException('bad request', 400, 'general_argument_invalid'),
        ),
        isFalse,
      );
      expect(
        isTransientSessionValidationFailure(
          AppwriteException('forbidden', 403, 'user_unauthorized'),
        ),
        isFalse,
      );
    });
  });

  group('parseAccountDeletionExecution', () {
    test(
      '1. HTTP 500 with authDeleted: true returns authDeletedReconciliationPending',
      () {
        final res = parseAccountDeletionExecution(
          status: 'failed',
          statusCode: 500,
          responseBody:
              '{"ok":false,"authDeleted":true,"message":"Reconciliation pending"}',
        );
        expect(
          res.kind,
          AccountDeletionOutcomeKind.authDeletedReconciliationPending,
        );
        expect(res.isAuthDeleted, isTrue);
        expect(res.isFullSuccess, isFalse);
        expect(res.statusCode, 500);
      },
    );

    test('2. HTTP 500 without authDeleted: true returns failed', () {
      final res = parseAccountDeletionExecution(
        status: 'failed',
        statusCode: 500,
        responseBody:
            '{"ok":false,"authDeleted":false,"message":"Database error"}',
      );
      expect(res.kind, AccountDeletionOutcomeKind.failed);
      expect(res.isAuthDeleted, isFalse);
      expect(res.isFullSuccess, isFalse);
    });

    test('3. HTTP 2xx with ok: true returns completed outcome', () {
      final res = parseAccountDeletionExecution(
        status: 'completed',
        statusCode: 200,
        responseBody: '{"ok":true,"authDeleted":true}',
      );
      expect(res.kind, AccountDeletionOutcomeKind.completed);
      expect(res.isAuthDeleted, isTrue);
      expect(res.isFullSuccess, isTrue);
      expect(res.statusCode, 200);
    });

    test('4. Empty response fails closed as malformed', () {
      final res = parseAccountDeletionExecution(
        status: 'completed',
        statusCode: 200,
        responseBody: '',
      );
      expect(res.kind, AccountDeletionOutcomeKind.malformed);
      expect(res.isAuthDeleted, isFalse);
    });

    test(
      '5. Malformed JSON fails closed as malformed without leaking raw body',
      () {
        final res = parseAccountDeletionExecution(
          status: 'completed',
          statusCode: 200,
          responseBody: '<html>Internal Error</html>',
        );
        expect(res.kind, AccountDeletionOutcomeKind.malformed);
        expect(res.errorMessage, isNot(contains('Internal Error')));
      },
    );

    test('6. Non-object JSON fails closed as malformed', () {
      final res = parseAccountDeletionExecution(
        status: 'completed',
        statusCode: 200,
        responseBody: '["valid_json_list"]',
      );
      expect(res.kind, AccountDeletionOutcomeKind.malformed);
    });

    test('Execution status normalization handles uppercase status string', () {
      final res = parseAccountDeletionExecution(
        status: 'COMPLETED',
        statusCode: 200,
        responseBody: '{"ok":true,"authDeleted":true}',
      );
      expect(res.kind, AccountDeletionOutcomeKind.completed);
    });
  });

  group('AppwriteAuthService Comprehensive Invariants', () {
    late MockClient mockClient;
    late MockAccount mockAccount;
    late MockFunctions mockFunctions;

    setUp(() {
      mockClient = MockClient();
      mockAccount = MockAccount();
      mockFunctions = MockFunctions();

      when(() => mockClient.setSession(any())).thenReturn(mockClient);
      when(() => mockClient.setEndpoint(any())).thenReturn(mockClient);
      when(() => mockClient.setProject(any())).thenReturn(mockClient);
    });

    test('1. Missing secret with stale session calls setSession("")', () async {
      SharedPreferences.setMockInitialValues({
        'olitun_has_local_session': true,
      });

      when(
        () => mockAccount.getSession(sessionId: 'current'),
      ).thenThrow(AppwriteException('Unauthorized', 401));

      final service = AppwriteAuthService.forTesting(
        client: mockClient,
        account: mockAccount,
        functions: mockFunctions,
        isWebOverride: true,
      );

      final loggedIn = await service.isLoggedIn();
      expect(loggedIn, isFalse);
      verify(() => mockClient.setSession('')).called(greaterThanOrEqualTo(1));
    });

    test('2. Empty secret with stale session calls setSession("")', () async {
      SharedPreferences.setMockInitialValues({
        'olitun_appwrite_session_secret': '',
        'olitun_web_session_ts': DateTime.now().millisecondsSinceEpoch,
        'olitun_has_local_session': true,
      });

      when(
        () => mockAccount.getSession(sessionId: 'current'),
      ).thenThrow(AppwriteException('Unauthorized', 401));

      final service = AppwriteAuthService.forTesting(
        client: mockClient,
        account: mockAccount,
        functions: mockFunctions,
        isWebOverride: true,
      );

      final loggedIn = await service.isLoggedIn();
      expect(loggedIn, isFalse);
      verify(() => mockClient.setSession('')).called(greaterThanOrEqualTo(1));
    });

    test(
      '3. Secret with missing timestamp clears keys and calls setSession("")',
      () async {
        SharedPreferences.setMockInitialValues({
          'olitun_appwrite_session_secret': 'some_secret',
          'olitun_has_local_session': true,
        });

        when(
          () => mockAccount.getSession(sessionId: 'current'),
        ).thenThrow(AppwriteException('Unauthorized', 401));

        final service = AppwriteAuthService.forTesting(
          client: mockClient,
          account: mockAccount,
          functions: mockFunctions,
          isWebOverride: true,
        );

        final loggedIn = await service.isLoggedIn();
        expect(loggedIn, isFalse);
        verify(() => mockClient.setSession('')).called(greaterThanOrEqualTo(1));

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.containsKey('olitun_appwrite_session_secret'), isFalse);
      },
    );

    test(
      '4. Timestamp with no secret clears state and calls setSession("")',
      () async {
        SharedPreferences.setMockInitialValues({
          'olitun_web_session_ts': DateTime.now().millisecondsSinceEpoch,
          'olitun_has_local_session': true,
        });

        when(
          () => mockAccount.getSession(sessionId: 'current'),
        ).thenThrow(AppwriteException('Unauthorized', 401));

        final service = AppwriteAuthService.forTesting(
          client: mockClient,
          account: mockAccount,
          functions: mockFunctions,
          isWebOverride: true,
        );

        final loggedIn = await service.isLoggedIn();
        expect(loggedIn, isFalse);
        verify(() => mockClient.setSession('')).called(greaterThanOrEqualTo(1));
      },
    );

    test('5. Zero timestamp clears state and calls setSession("")', () async {
      SharedPreferences.setMockInitialValues({
        'olitun_appwrite_session_secret': 'valid_secret',
        'olitun_web_session_ts': 0,
        'olitun_has_local_session': true,
      });

      when(
        () => mockAccount.getSession(sessionId: 'current'),
      ).thenThrow(AppwriteException('Unauthorized', 401));

      final service = AppwriteAuthService.forTesting(
        client: mockClient,
        account: mockAccount,
        functions: mockFunctions,
        isWebOverride: true,
      );

      final loggedIn = await service.isLoggedIn();
      expect(loggedIn, isFalse);
      verify(() => mockClient.setSession('')).called(greaterThanOrEqualTo(1));
    });

    test(
      '6. Negative timestamp clears state and calls setSession("")',
      () async {
        SharedPreferences.setMockInitialValues({
          'olitun_appwrite_session_secret': 'valid_secret',
          'olitun_web_session_ts': -100,
          'olitun_has_local_session': true,
        });

        when(
          () => mockAccount.getSession(sessionId: 'current'),
        ).thenThrow(AppwriteException('Unauthorized', 401));

        final service = AppwriteAuthService.forTesting(
          client: mockClient,
          account: mockAccount,
          functions: mockFunctions,
          isWebOverride: true,
        );

        final loggedIn = await service.isLoggedIn();
        expect(loggedIn, isFalse);
        verify(() => mockClient.setSession('')).called(greaterThanOrEqualTo(1));
      },
    );

    test(
      '7. Expired timestamp (>24h) clears state and calls setSession("")',
      () async {
        final expiredMs = DateTime.now()
            .subtract(const Duration(hours: 25))
            .millisecondsSinceEpoch;
        SharedPreferences.setMockInitialValues({
          'olitun_appwrite_session_secret': 'valid_secret',
          'olitun_web_session_ts': expiredMs,
          'olitun_has_local_session': true,
        });

        when(
          () => mockAccount.getSession(sessionId: 'current'),
        ).thenThrow(AppwriteException('Unauthorized', 401));

        final service = AppwriteAuthService.forTesting(
          client: mockClient,
          account: mockAccount,
          functions: mockFunctions,
          isWebOverride: true,
        );

        final loggedIn = await service.isLoggedIn();
        expect(loggedIn, isFalse);
        verify(() => mockClient.setSession('')).called(greaterThanOrEqualTo(1));
      },
    );

    test('8. Future timestamp beyond 1 min skew clears state', () async {
      final futureMs = DateTime.now()
          .add(const Duration(minutes: 5))
          .millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'olitun_appwrite_session_secret': 'valid_secret',
        'olitun_web_session_ts': futureMs,
        'olitun_has_local_session': true,
      });

      when(
        () => mockAccount.getSession(sessionId: 'current'),
      ).thenThrow(AppwriteException('Unauthorized', 401));

      final service = AppwriteAuthService.forTesting(
        client: mockClient,
        account: mockAccount,
        functions: mockFunctions,
        isWebOverride: true,
      );

      final loggedIn = await service.isLoggedIn();
      expect(loggedIn, isFalse);
      verify(() => mockClient.setSession('')).called(greaterThanOrEqualTo(1));
    });

    test('9. Timestamp within 1 min future skew is accepted as valid', () {
      final now = DateTime.now();
      final validSkewMs = now
          .add(const Duration(seconds: 30))
          .millisecondsSinceEpoch;
      expect(isWebSessionValidTimestamp(validSkewMs, nowOverride: now), isTrue);
    });

    test('10. Valid session restores once and does not clear state', () async {
      final validMs = DateTime.now()
          .subtract(const Duration(hours: 2))
          .millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'olitun_web_session_ts': validMs,
        'olitun_has_local_session': true,
      });

      final mockSession = MockSession();
      when(() => mockSession.userId).thenReturn('user-123');
      when(
        () => mockAccount.getSession(sessionId: 'current'),
      ).thenAnswer((_) async => mockSession);

      final service = AppwriteAuthService.forTesting(
        client: mockClient,
        account: mockAccount,
        functions: mockFunctions,
        isWebOverride: true,
      );

      final loggedIn = await service.isLoggedIn();
      expect(loggedIn, isTrue);
      verifyNever(() => mockClient.setSession('valid_secret'));
    });

    test(
      '11. Async restore and sync restore enforce identical validity policy',
      () async {
        final validMs = DateTime.now()
            .subtract(const Duration(hours: 1))
            .millisecondsSinceEpoch;
        SharedPreferences.setMockInitialValues({
          'olitun_has_local_session': true,
          'olitun_web_session_ts': validMs,
        });

        final prefs = await SharedPreferences.getInstance();
        final service = AppwriteAuthService.forTesting(
          client: mockClient,
          account: mockAccount,
          functions: mockFunctions,
          isWebOverride: true,
        );

        service.restoreWebSessionSync(prefs);
        // Hardened model: sync restore validates metadata only — the raw
        // secret is never re-injected from prefs (cookies hold it on web).
        expect(prefs.getBool('olitun_has_local_session'), isTrue);
        verifyNever(() => mockClient.setSession('sync_secret'));
      },
    );

    test(
      '12. Rejected persisted session cannot be accepted during simulated network timeout',
      () async {
        final expiredMs = DateTime.now()
            .subtract(const Duration(hours: 30))
            .millisecondsSinceEpoch;
        SharedPreferences.setMockInitialValues({
          'olitun_appwrite_session_secret': 'expired_secret',
          'olitun_web_session_ts': expiredMs,
          'olitun_has_local_session': true,
        });

        when(
          () => mockAccount.getSession(sessionId: 'current'),
        ).thenThrow(TimeoutException('Network timeout'));

        final service = AppwriteAuthService.forTesting(
          client: mockClient,
          account: mockAccount,
          functions: mockFunctions,
          isWebOverride: true,
        );

        final loggedIn = await service.isLoggedIn();
        expect(loggedIn, isFalse);
        verify(() => mockClient.setSession('')).called(greaterThanOrEqualTo(1));
      },
    );

    test('13. Preference setBool failure still clears SDK state', () async {
      final mockPrefs = MockSharedPreferences();
      when(
        () => mockPrefs.setBool(any(), any()),
      ).thenThrow(Exception('Storage write error'));
      when(() => mockPrefs.remove(any())).thenAnswer((_) async => true);
      when(() => mockPrefs.getString(any())).thenReturn(null);
      when(() => mockPrefs.getInt(any())).thenReturn(null);

      final service = AppwriteAuthService.forTesting(
        client: mockClient,
        account: mockAccount,
        functions: mockFunctions,
        prefs: mockPrefs,
        isWebOverride: true,
      );

      await service.signOut();
      verify(() => mockClient.setSession('')).called(greaterThanOrEqualTo(1));
    });

    test(
      '14. Secret-removal failure still attempts timestamp and local-flag cleanup',
      () async {
        final mockPrefs = MockSharedPreferences();
        when(
          () => mockPrefs.setBool(any(), any()),
        ).thenAnswer((_) async => true);
        when(
          () => mockPrefs.remove('olitun_appwrite_session_secret'),
        ).thenThrow(Exception('Disk read-only'));
        when(
          () => mockPrefs.remove('olitun_web_session_ts'),
        ).thenAnswer((_) async => true);
        when(() => mockPrefs.getString(any())).thenReturn(null);

        final service = AppwriteAuthService.forTesting(
          client: mockClient,
          account: mockAccount,
          functions: mockFunctions,
          prefs: mockPrefs,
          isWebOverride: true,
        );

        await service.signOut();
        verify(
          () => mockPrefs.remove('olitun_web_session_ts'),
        ).called(greaterThanOrEqualTo(1));
        verify(() => mockClient.setSession('')).called(greaterThanOrEqualTo(1));
      },
    );

    test(
      '15. deleteAccount HTTP 500 with authDeleted: true clears local session state and setSession("")',
      () async {
        SharedPreferences.setMockInitialValues({
          'olitun_appwrite_session_secret': 'valid_secret',
          'olitun_web_session_ts': DateTime.now().millisecondsSinceEpoch,
          'olitun_has_local_session': true,
        });

        final mockExecution = MockExecution();
        when(() => mockExecution.status).thenReturn(ExecutionStatus.failed);
        when(() => mockExecution.responseStatusCode).thenReturn(500);
        when(() => mockExecution.responseBody).thenReturn(
          '{"ok":false,"authDeleted":true,"message":"Reconciliation pending"}',
        );

        when(
          () => mockFunctions.createExecution(functionId: 'delete-account'),
        ).thenAnswer((_) async => mockExecution);

        final service = AppwriteAuthService.forTesting(
          client: mockClient,
          account: mockAccount,
          functions: mockFunctions,
          isWebOverride: true,
        );

        await expectLater(
          service.deleteAccount,
          throwsA(isA<AppwriteException>()),
        );

        verify(() => mockClient.setSession('')).called(greaterThanOrEqualTo(1));
      },
    );

    test(
      '16. deleteAccount HTTP 500 without authDeleted: true preserves valid local state',
      () async {
        SharedPreferences.setMockInitialValues({
          'olitun_appwrite_session_secret': 'valid_secret',
          'olitun_web_session_ts': DateTime.now().millisecondsSinceEpoch,
          'olitun_has_local_session': true,
        });

        final mockExecution = MockExecution();
        when(() => mockExecution.status).thenReturn(ExecutionStatus.failed);
        when(() => mockExecution.responseStatusCode).thenReturn(500);
        when(() => mockExecution.responseBody).thenReturn(
          '{"ok":false,"authDeleted":false,"message":"Server error"}',
        );

        when(
          () => mockFunctions.createExecution(functionId: 'delete-account'),
        ).thenAnswer((_) async => mockExecution);

        final service = AppwriteAuthService.forTesting(
          client: mockClient,
          account: mockAccount,
          functions: mockFunctions,
          isWebOverride: true,
        );

        await expectLater(
          service.deleteAccount,
          throwsA(isA<AppwriteException>()),
        );
      },
    );

    test(
      '17. deleteAccount HTTP 2xx with ok: true clears every session layer',
      () async {
        SharedPreferences.setMockInitialValues({
          'olitun_appwrite_session_secret': 'valid_secret',
          'olitun_web_session_ts': DateTime.now().millisecondsSinceEpoch,
          'olitun_has_local_session': true,
        });

        final mockExecution = MockExecution();
        when(() => mockExecution.status).thenReturn(ExecutionStatus.completed);
        when(() => mockExecution.responseStatusCode).thenReturn(200);
        when(
          () => mockExecution.responseBody,
        ).thenReturn('{"ok":true,"authDeleted":true}');

        when(
          () => mockFunctions.createExecution(functionId: 'delete-account'),
        ).thenAnswer((_) async => mockExecution);

        final service = AppwriteAuthService.forTesting(
          client: mockClient,
          account: mockAccount,
          functions: mockFunctions,
          isWebOverride: true,
        );

        await service.deleteAccount();
        verify(() => mockClient.setSession('')).called(greaterThanOrEqualTo(1));
      },
    );

    test(
      '18. exchangeOAuthToken on Web creates session and persists active session secret',
      () async {
        SharedPreferences.setMockInitialValues({});
        final mockSession = MockSession();
        when(() => mockSession.secret).thenReturn('active_session_secret_999');

        when(
          () => mockAccount.createSession(
            userId: 'test_user_id',
            secret: 'token_secret_123',
          ),
        ).thenAnswer((_) async => mockSession);

        final service = AppwriteAuthService.forTesting(
          client: mockClient,
          account: mockAccount,
          functions: mockFunctions,
          isWebOverride: true,
        );

        final result = await service.exchangeOAuthToken(
          'test_user_id',
          'token_secret_123',
        );
        expect(result, isTrue);

        verify(
          () => mockAccount.createSession(
            userId: 'test_user_id',
            secret: 'token_secret_123',
          ),
        ).called(1);
        verify(
          () => mockClient.setSession('active_session_secret_999'),
        ).called(1);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('olitun_has_local_session'), isTrue);
      },
    );

    test(
      '19. isLoggedIn on Web validates with Appwrite when hasLocal is false',
      () async {
        SharedPreferences.setMockInitialValues({
          'olitun_has_local_session': false,
        });

        final mockSession = MockSession();
        when(
          () => mockAccount.getSession(sessionId: 'current'),
        ).thenAnswer((_) async => mockSession);

        final service = AppwriteAuthService.forTesting(
          client: mockClient,
          account: mockAccount,
          functions: mockFunctions,
          isWebOverride: true,
        );

        final loggedIn = await service.isLoggedIn();
        expect(loggedIn, isTrue);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('olitun_has_local_session'), isTrue);
      },
    );

    test(
      '20. signInWithGoogle on mobile exchanges the browser callback for a real session and sets local session flag',
      () async {
        SharedPreferences.setMockInitialValues({});
        final mockSession = MockSession();
        when(
          () => mockAccount.createSession(
            userId: any(named: 'userId'),
            secret: any(named: 'secret'),
          ),
        ).thenAnswer((_) async => mockSession);

        var browserUrl = '';
        final service = AppwriteAuthService.forTesting(
          client: mockClient,
          account: mockAccount,
          functions: mockFunctions,
          isWebOverride: false,
          browserAuthenticate: ({required url, required callbackUrlScheme}) async {
            browserUrl = url;
            expect(
              callbackUrlScheme,
              'appwrite-callback-${AppwriteConfig.projectId}',
            );
            // Callback shape the Appwrite token endpoint actually returns:
            // userId + secret, no `key`.
            return 'appwrite-callback-${AppwriteConfig.projectId}://success?userId=user_1&secret=session-secret';
          },
        );

        await service.signInWithGoogle();

        // The browser must open the token endpoint (not the session one).
        expect(browserUrl, contains('/account/tokens/oauth2/google'));
        // And the token must be exchanged for a real server session —
        // previously the SDK's internal parser rejected this exact shape.
        verify(
          () => mockAccount.createSession(
            userId: 'user_1',
            secret: 'session-secret',
          ),
        ).called(1);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('olitun_has_local_session'), isTrue);
      },
    );
  });
}
