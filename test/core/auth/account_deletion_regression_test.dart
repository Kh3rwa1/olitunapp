import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/auth/appwrite_auth_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeletionClient extends Mock implements Client {}

class DeletionAccount extends Mock implements Account {}

class DeletionFunctions extends Mock implements Functions {}

class DeletionExecution extends Mock implements models.Execution {}

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

    for (final body in [
      '{"ok":true}',
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
      service = AppwriteAuthService.forTesting(
        client: client,
        account: DeletionAccount(),
        functions: functions,
        prefs: prefs,
        isWebOverride: false,
      );
    });

    void execution(int code, String body) {
      final result = DeletionExecution();
      when(() => result.status).thenReturn(ExecutionStatus.completed);
      when(() => result.responseStatusCode).thenReturn(code);
      when(() => result.responseBody).thenReturn(body);
      when(
        () => functions.createExecution(functionId: 'delete-account'),
      ).thenAnswer((_) async => result);
    }

    test('transport 401 requires sign-in and never returns success', () async {
      when(
        () => functions.createExecution(functionId: 'delete-account'),
      ).thenThrow(AppwriteException('Expired session', 401));
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

    test('missing function does not imply deletion', () async {
      when(
        () => functions.createExecution(functionId: 'delete-account'),
      ).thenThrow(AppwriteException('Function not found', 404));
      await expectLater(
        service.deleteAccount(),
        throwsA(isA<AppwriteException>().having((e) => e.code, 'code', 404)),
      );
      expect(prefs.getBool('olitun_has_local_session'), isTrue);
      expect(prefs.getString('olitun_appwrite_session_secret'), 'test-session');
    });

    test('nested function 404 is not proof that the user is absent', () async {
      execution(404, '{"ok":false,"message":"Resource not found"}');
      await expectLater(
        service.deleteAccount(),
        throwsA(isA<AppwriteException>()),
      );
      expect(prefs.getBool('olitun_has_local_session'), isTrue);
    });

    test('nested function 401 requires reauthentication', () async {
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
}
