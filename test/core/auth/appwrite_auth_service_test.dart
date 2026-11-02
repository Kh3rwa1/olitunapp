import 'dart:async';
import 'package:itun/core/auth/account_scope.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appwrite/appwrite.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/core/auth/appwrite_auth_service.dart';
import 'package:itun/core/config/appwrite_config.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';

import '../../helpers/fake_auth_worker.dart';

class MockClient extends Mock implements Client {}

class MockAccount extends Mock implements Account {}

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

  group('AppwriteAuthService on Worker sign-in', () {
    late SharedPreferences prefs;
    late FakeAuthWorker worker;
    late MockClient client;

    AppwriteAuthService build({
      AccountDeletionRequest? deletion,
      Future<String> Function({
        required String url,
        required String callbackUrlScheme,
      })?
      browser,
    }) {
      return AppwriteAuthService.forTesting(
        client: client,
        account: MockAccount(),
        workerAuth: worker.auth(prefs),
        prefs: prefs,
        isWebOverride: false,
        connectivity: () async => [ConnectivityResult.wifi],
        accountDeletionRequest: deletion,
        browserAuthenticate: browser,
      );
    }

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      worker = FakeAuthWorker();
      client = MockClient();
      when(() => client.setSession(any())).thenReturn(client);
      worker.on('POST', '/logout', (_) => FakeAuthWorker.json({'ok': true}));
    });

    test('guest sign-in identifies the account and marks a session', () async {
      worker.on(
        'POST',
        '/guest',
        (_) => FakeAuthWorker.json(FakeAuthWorker.session('g1', guest: true)),
      );
      final service = build();
      final session = await service.signInAnonymously();
      expect(session.user.isGuest, isTrue);
      expect(AccountScope.capture(prefs).userId, 'g1');
      expect(prefs.getBool('olitun_has_local_session'), isTrue);
      expect(await service.isLoggedIn(), isTrue);
    });

    test('email code: send returns the address, verify signs in', () async {
      worker.on('POST', '/email/start', (request) {
        expect(jsonDecode(request.body)['email'], 'mani@x.in');
        return FakeAuthWorker.json({'ok': true});
      });
      worker.on('POST', '/email/verify', (request) {
        expect(jsonDecode(request.body), {
          'email': 'mani@x.in',
          'code': '123456',
        });
        return FakeAuthWorker.json(
          FakeAuthWorker.session('u_mani', email: 'mani@x.in'),
        );
      });
      final service = build();
      final token = await service.sendOtpCode('  Mani@X.in ');
      expect(token, 'mani@x.in');
      final session = await service.verifyOtp(
        userId: token,
        secret: ' 123456 ',
      );
      expect(session.user.id, 'u_mani');
      expect(AccountScope.capture(prefs).userId, 'u_mani');
    });

    test(
      'a wrong code surfaces the Worker message as AppwriteException',
      () async {
        worker.on(
          'POST',
          '/email/verify',
          (_) => FakeAuthWorker.json({
            'ok': false,
            'error': 'INVALID_CODE',
            'message': 'That code is not right. Please check it and try again.',
          }, 400),
        );
        final service = build();
        await expectLater(
          service.verifyOtp(userId: 'a@b.in', secret: '000000'),
          throwsA(
            isA<AppwriteException>()
                .having((e) => e.code, 'code', 400)
                .having((e) => e.type, 'type', 'INVALID_CODE')
                .having((e) => e.message, 'message', contains('not right')),
          ),
        );
        expect(await service.isLoggedIn(), isFalse);
      },
    );

    test('Google on mobile exchanges the Worker login code', () async {
      String? openedUrl;
      String? scheme;
      worker.on('POST', '/exchange', (request) {
        expect(jsonDecode(request.body)['code'], 'one-time');
        return FakeAuthWorker.json(
          FakeAuthWorker.session('u_google', email: 'g@x.in'),
        );
      });
      final service = build(
        browser: ({required url, required callbackUrlScheme}) async {
          openedUrl = url;
          scheme = callbackUrlScheme;
          return '$callbackUrlScheme://auth?olitun_code=one-time';
        },
      );
      await service.signInWithGoogle();
      expect(openedUrl, contains('/api/v1/auth/google/start'));
      expect(openedUrl, contains('platform=android'));
      expect(scheme, 'appwrite-callback-${AppwriteConfig.projectId}');
      expect(AccountScope.capture(prefs).userId, 'u_google');
    });

    test('Google errors from the Worker become readable messages', () async {
      final service = build(
        browser: ({required url, required callbackUrlScheme}) async =>
            '$callbackUrlScheme://auth?error=GOOGLE_UNAVAILABLE',
      );
      await expectLater(
        service.signInWithGoogle(),
        throwsA(
          isA<AppwriteException>().having(
            (e) => e.message,
            'message',
            contains('not available'),
          ),
        ),
      );
      expect(worker.callsTo('/exchange'), isEmpty);
    });

    test('prefs round-trip through the Worker', () async {
      Map<String, dynamic>? stored;
      worker.on(
        'POST',
        '/guest',
        (_) => FakeAuthWorker.json(FakeAuthWorker.session('g1', guest: true)),
      );
      worker.on('PUT', '/prefs', (request) {
        expect(request.headers['Authorization'], 'Bearer access-1');
        stored = Map<String, dynamic>.from(
          jsonDecode(request.body)['prefs'] as Map,
        );
        return FakeAuthWorker.json({'ok': true});
      });
      worker.on(
        'GET',
        '/prefs',
        (_) => FakeAuthWorker.json({'ok': true, 'prefs': stored ?? {}}),
      );
      final service = build();
      await service.signInAnonymously();
      await service.updatePrefs({'xp': 40});
      expect((await service.getPrefs()).data, {'xp': 40});
    });

    test('getMe falls back to the cached user when offline', () async {
      worker.on(
        'POST',
        '/guest',
        (_) => FakeAuthWorker.json(
          FakeAuthWorker.session('g1', guest: true, name: 'Cached'),
        ),
      );
      final service = build();
      await service.signInAnonymously();
      worker.offline = true;
      final me = await service.getMe();
      expect(me.$id, 'g1');
      expect(me.name, 'Cached');
    });

    test('getMe clears a session the Worker rejects', () async {
      worker.on(
        'POST',
        '/guest',
        (_) => FakeAuthWorker.json(FakeAuthWorker.session('g1', guest: true)),
      );
      worker.on(
        'GET',
        '/me',
        (_) =>
            FakeAuthWorker.json({'ok': false, 'error': 'UNAUTHENTICATED'}, 401),
      );
      final service = build();
      await service.signInAnonymously();
      await expectLater(service.getMe(), throwsA(isA<AppwriteException>()));
      expect(await service.worker.cached(), isNull);
    });

    test(
      'signOut ends the Worker session and marks the device signed out',
      () async {
        worker.on(
          'POST',
          '/guest',
          (_) => FakeAuthWorker.json(FakeAuthWorker.session('g1', guest: true)),
        );
        final service = build();
        await service.signInAnonymously();
        await service.signOut();
        await Future<void>.delayed(Duration.zero);
        expect(worker.callsTo('/logout'), hasLength(1));
        expect(await service.worker.cached(), isNull);
        expect(AccountScope.capture(prefs).isExplicitlySignedOut, isTrue);
        expect(await service.isLoggedIn(), isFalse);
      },
    );

    test('deleteAccount success clears every session layer', () async {
      worker.on(
        'POST',
        '/guest',
        (_) => FakeAuthWorker.json(FakeAuthWorker.session('g1', guest: true)),
      );
      final service = build(
        deletion: () async => const AccountDeletionResponse(
          200,
          '{"ok":true,"code":"account_deleted","authDeleted":true}',
        ),
      );
      await service.signInAnonymously();
      await service.deleteAccount();
      expect(await service.worker.cached(), isNull);
      expect(prefs.getBool('olitun_has_local_session'), isFalse);
      verify(() => client.setSession('')).called(greaterThanOrEqualTo(1));
    });

    test('deleteAccount failure keeps the session', () async {
      worker.on(
        'POST',
        '/guest',
        (_) => FakeAuthWorker.json(FakeAuthWorker.session('g1', guest: true)),
      );
      final service = build(
        deletion: () async => const AccountDeletionResponse(
          500,
          '{"ok":false,"authDeleted":false,"message":"Server error"}',
        ),
      );
      await service.signInAnonymously();
      await expectLater(
        service.deleteAccount,
        throwsA(isA<AppwriteException>()),
      );
      expect((await service.worker.cached())?.user.id, 'g1');
    });

    test('password sign-in explains the replacement', () async {
      await expectLater(
        build().signInWithEmail(email: 'a@b.in', password: 'pw'),
        throwsA(
          isA<AppwriteException>().having(
            (e) => e.type,
            'type',
            'password_signin_removed',
          ),
        ),
      );
    });
  });

  group('parseWorkerOAuthCallback', () {
    test('returns the one-time code', () {
      expect(
        parseWorkerOAuthCallback('appwrite-callback-x://auth?olitun_code=abc'),
        'abc',
      );
    });

    test('maps a cancelled consent to a silent message', () {
      expect(
        () => parseWorkerOAuthCallback('scheme://auth?error=GOOGLE_CANCELLED'),
        throwsA(
          isA<AppwriteException>().having(
            (e) => e.message,
            'message',
            contains('cancelled'),
          ),
        ),
      );
    });

    test('rejects a callback without a code', () {
      expect(
        () => parseWorkerOAuthCallback('scheme://auth'),
        throwsA(isA<AppwriteException>()),
      );
    });
  });
}
