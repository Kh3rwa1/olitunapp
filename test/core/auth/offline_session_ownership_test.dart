import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/core/auth/account_scope.dart';
import 'package:itun/core/auth/appwrite_auth_service.dart';

class _Client extends Mock implements Client {}

class _Account extends Mock implements Account {}

class _Functions extends Mock implements Functions {}

class _Session extends Mock implements models.Session {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  late _Client client;
  late _Account account;
  late AppwriteAuthService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'olitun_has_local_session': true,
      'olitun_web_session_ts': DateTime.now()
          .subtract(const Duration(days: 2))
          .millisecondsSinceEpoch,
    });
    prefs = await SharedPreferences.getInstance();
    await (await AccountScope.beginSignIn(prefs)).identify('alice');
    client = _Client();
    account = _Account();
    when(() => client.setSession(any())).thenReturn(client);
    service = AppwriteAuthService.forTesting(
      client: client,
      account: account,
      functions: _Functions(),
      prefs: prefs,
      isWebOverride: true,
    );
  });

  test(
    'expired web metadata plus offline validation preserves progress owner',
    () async {
      when(
        () => account.getSession(sessionId: 'current'),
      ).thenThrow(TimeoutException('offline'));
      expect(await service.isLoggedIn(), isFalse);
      final scope = AccountScope.capture(prefs);
      expect(scope.userId, 'alice');
      expect(scope.isGuest, isFalse);
      expect(scope.statsKey, 'user_stats_alice');
      expect(prefs.getBool('olitun_has_local_session'), isFalse);
    },
  );

  test(
    '401 invalidates credentials without redirecting pending progress to guest',
    () async {
      when(
        () => account.getSession(sessionId: 'current'),
      ).thenThrow(AppwriteException('expired', 401));
      expect(await service.isLoggedIn(), isFalse);
      expect(AccountScope.capture(prefs).userId, 'alice');
    },
  );

  test('synchronous startup expiry also preserves ownership', () async {
    service.restoreWebSessionSync(prefs);
    await Future<void>.delayed(Duration.zero);
    expect(AccountScope.capture(prefs).userId, 'alice');
    expect(prefs.getBool('olitun_has_local_session'), isFalse);
  });

  test('explicit logout still blocks surviving cookie adoption', () async {
    when(
      () => account.deleteSession(sessionId: 'current'),
    ).thenAnswer((_) async => {});
    await service.signOut();
    expect(AccountScope.capture(prefs).isExplicitlySignedOut, isTrue);
    expect(await service.isLoggedIn(), isFalse);
    verifyNever(() => account.getSession(sessionId: 'current'));
  });

  test(
    'a validated different cookie creates a new owner incarnation',
    () async {
      final old = AccountScope.capture(prefs);
      final session = _Session();
      when(() => session.userId).thenReturn('bob');
      when(
        () => account.getSession(sessionId: 'current'),
      ).thenAnswer((_) async => session);
      expect(await service.isLoggedIn(), isTrue);
      expect(AccountScope.capture(prefs).userId, 'bob');
      expect(old.isCurrent, isFalse);
    },
  );
}
