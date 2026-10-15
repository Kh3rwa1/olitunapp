import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/core/auth/appwrite_auth_service.dart';
import 'package:itun/core/auth/edge_auth.dart';
import 'package:itun/core/config/cloudflare_config.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeletionClient extends Mock implements Client {}

class DeletionAccount extends Mock implements Account {}

class DeletionFunctions extends Mock implements Functions {}

class DeletionJwt extends Mock implements models.Jwt {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Deletion confirmation contract', () {
    for (final status in [
      'completed',
      'ExecutionStatus.completed',
      'COMPLETED',
    ]) {
      test('accepts the existing server confirmation with $status', () {
        final result = parseAccountDeletionExecution(
          status: status,
          statusCode: 200,
          responseBody: '{"ok":true,"code":"account_deleted"}',
        );
        expect(result.isFullSuccess, isTrue);
        expect(result.isAuthDeleted, isTrue);
      });
    }

    test('accepts a blocked login as the login being removed', () {
      final result = parseAccountDeletionExecution(
        status: 'completed',
        statusCode: 200,
        responseBody:
            '{"ok":true,"code":"account_deleted","authDeleted":false,'
            '"loginBlocked":true}',
      );
      expect(result.isFullSuccess, isTrue);
      expect(result.isAuthDeleted, isTrue);
    });

    for (final body in [
      '{"ok":true}',
      '{"ok":true,"loginBlocked":false}',
      '{"ok":true,"authDeleted":false}',
      '{"ok":true,"code":"account_deleted","authDeleted":false}',
    ]) {
      test('rejects unconfirmed deletion: $body', () {
        final result = parseAccountDeletionExecution(
          status: 'completed',
          statusCode: 200,
          responseBody: body,
        );
        expect(result.isFullSuccess, isFalse);
        expect(result.isAuthDeleted, isFalse);
      });
    }

    for (final status in ['waiting', 'processing', 'unknown', '']) {
      test('does not treat $status as a completed execution', () {
        final result = parseAccountDeletionExecution(
          status: status,
          statusCode: 200,
          responseBody: '{"ok":true,"authDeleted":true}',
        );
        expect(result.isFullSuccess, isFalse);
      });
    }
  });

  group('Deletion service regression', () {
    late DeletionClient client;
    late DeletionFunctions functions;
    late SharedPreferences prefs;
    late AppwriteAuthService service;
    late AccountDeletionRequest request;
    var requests = 0;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'olitun_has_local_session': true,
        'olitun_appwrite_session_secret': 'test-session',
        'olitun_web_session_ts': DateTime.now().millisecondsSinceEpoch,
      });
      prefs = await SharedPreferences.getInstance();
      client = DeletionClient();
      functions = DeletionFunctions();
      when(() => client.setSession(any())).thenReturn(client);
      requests = 0;
      request = () async => throw StateError('no response configured');
      service = AppwriteAuthService.forTesting(
        client: client,
        account: DeletionAccount(),
        functions: functions,
        prefs: prefs,
        isWebOverride: false,
        accountDeletionRequest: () {
          requests++;
          return request();
        },
      );
    });

    void execution(int code, String body) {
      request = () async => AccountDeletionResponse(code, body);
    }

    test('deletion goes to the Worker, never Appwrite Functions', () async {
      execution(200, '{"ok":true,"code":"account_deleted","authDeleted":true}');
      await service.deleteAccount();
      expect(requests, 1);
      verifyZeroInteractions(functions);
    });

    test('transport 401 requires sign-in and never returns success', () async {
      request = () async => throw AppwriteException('Expired session', 401);
      await expectLater(
        service.deleteAccount(),
        throwsA(
          isA<AppwriteException>().having(
            (error) => error.type,
            'type',
            'account_deletion_reauthentication_required',
          ),
        ),
      );
      expect(prefs.getBool('olitun_has_local_session'), isFalse);
    });

    test('network failure does not imply deletion', () async {
      final sessionTimestamp = prefs.getInt('olitun_web_session_ts');
      request = () async => throw http.ClientException('offline');
      await expectLater(
        service.deleteAccount(),
        throwsA(isA<AppwriteException>().having((e) => e.code, 'code', 500)),
      );
      expect(prefs.getBool('olitun_has_local_session'), isTrue);
      // Legacy preference cleanup must not be mistaken for signing out.
      expect(prefs.getString('olitun_appwrite_session_secret'), isNull);
      expect(prefs.getInt('olitun_web_session_ts'), sessionTimestamp);
      verifyNever(() => client.setSession(''));
    });

    test('worker 404 is not proof that the user is absent', () async {
      execution(404, '{"ok":false,"message":"Resource not found"}');
      await expectLater(
        service.deleteAccount(),
        throwsA(isA<AppwriteException>()),
      );
      expect(prefs.getBool('olitun_has_local_session'), isTrue);
    });

    test('worker 401 requires reauthentication', () async {
      execution(401, '{"ok":false,"code":"unauthenticated"}');
      await expectLater(
        service.deleteAccount(),
        throwsA(isA<AppwriteException>()),
      );
      expect(prefs.getBool('olitun_has_local_session'), isFalse);
    });

    test('generic success payload cannot clear the session', () async {
      execution(200, '{"ok":true}');
      await expectLater(
        service.deleteAccount(),
        throwsA(isA<AppwriteException>()),
      );
      expect(prefs.getBool('olitun_has_local_session'), isTrue);
    });

    for (final code in [502, 503]) {
      test('worker $code (login not removed) keeps the session', () async {
        execution(code, '{"ok":false,"code":"deletion_failed"}');
        await expectLater(
          service.deleteAccount(),
          throwsA(isA<AppwriteException>().having((e) => e.code, 'code', code)),
        );
        expect(prefs.getBool('olitun_has_local_session'), isTrue);
      });
    }

    test('confirmed server deletion clears persisted session state', () async {
      execution(200, '{"ok":true,"code":"account_deleted"}');
      await service.deleteAccount();
      expect(prefs.getBool('olitun_has_local_session'), isFalse);
      expect(prefs.containsKey('olitun_appwrite_session_secret'), isFalse);
      expect(prefs.containsKey('olitun_web_session_ts'), isFalse);
      verify(() => client.setSession('')).called(greaterThanOrEqualTo(1));
    });

    for (final code in [401, 500]) {
      test('partial deletion stays pending ($code)', () async {
        execution(code, '{"ok":false,"authDeleted":true}');
        await expectLater(
          service.deleteAccount(),
          throwsA(
            isA<AppwriteException>().having(
              (error) => error.type,
              'type',
              'account_deletion_pending',
            ),
          ),
        );
        expect(prefs.getBool('olitun_has_local_session'), isFalse);
      });
    }
  });

  group('Edge deletion transport', () {
    late DeletionAccount account;

    setUp(() {
      account = DeletionAccount();
    });

    void jwt(String value) {
      final token = DeletionJwt();
      when(() => token.jwt).thenReturn(value);
      when(() => account.createJWT()).thenAnswer((_) async => token);
    }

    test('posts to the Worker with the session JWT', () async {
      jwt('jwt-abc');
      late http.Request sent;
      final request = edgeAccountDeletionRequest(
        edgeAuth: EdgeAuth(account),
        httpClient: MockClient((req) async {
          sent = req;
          return http.Response(
            jsonEncode({'ok': true, 'code': 'account_deleted'}),
            200,
          );
        }),
      );
      final res = await request();
      expect(res.statusCode, 200);
      expect(sent.method, 'POST');
      expect(sent.url.toString(), CloudflareConfig.deleteAccountEndpoint);
      expect(sent.headers['Authorization'], 'Bearer jwt-abc');
    });

    test('no session means 401 without calling the Worker', () async {
      when(() => account.createJWT()).thenThrow(AppwriteException('guest'));
      var called = false;
      final request = edgeAccountDeletionRequest(
        edgeAuth: EdgeAuth(account),
        httpClient: MockClient((_) async {
          called = true;
          return http.Response('{}', 200);
        }),
      );
      await expectLater(
        request(),
        throwsA(isA<AppwriteException>().having((e) => e.code, 'code', 401)),
      );
      expect(called, isFalse);
    });
  });
}
