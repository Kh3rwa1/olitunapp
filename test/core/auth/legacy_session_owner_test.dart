import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/core/auth/account_scope.dart';
import 'package:itun/core/auth/appwrite_auth_service.dart';
import 'package:itun/features/auth/domain/repositories/auth_repository.dart';
import 'package:itun/features/profile/data/repositories/profile_repository_impl.dart';

class _Client extends Mock implements Client {}

class _Account extends Mock implements Account {}

class _Functions extends Mock implements Functions {}

class _Session extends Mock implements models.Session {}

class _Auth extends Mock implements AuthRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  late _Account account;
  late AppwriteAuthService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'olitun_has_local_session': true,
      'olitun_web_session_ts': 1,
      'user_progress_data':
          'unowned legacy progress must not become guest data',
    });
    prefs = await SharedPreferences.getInstance();
    final client = _Client();
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

  test('legacy expiry cannot convert unknown ownership into a guest', () async {
    when(
      () => account.getSession(sessionId: 'current'),
    ).thenThrow(TimeoutException('offline'));
    expect(await service.isLoggedIn(), false);
    expect(AccountScope.capture(prefs).isKnown, false);
    expect(AccountScope.capture(prefs).isGuest, false);
    final saved = {for (final key in prefs.getKeys()) key: prefs.get(key)!};
    SharedPreferences.setMockInitialValues(saved);
    final restarted = await SharedPreferences.getInstance();
    expect(AccountScope.capture(restarted).isKnown, false);
    final auth = _Auth();
    final repo = ProfileRepositoryImpl(auth, restarted);
    expect((await repo.getUserStats()).isLeft(), true);
    expect(restarted.getString('user_stats_guest'), isNull);
    verifyNever(auth.getUserPrefs);
  });

  test(
    'a server-validated session can resolve a legacy owner after expiry',
    () async {
      final session = _Session();
      when(() => session.userId).thenReturn('alice');
      when(
        () => account.getSession(sessionId: 'current'),
      ).thenAnswer((_) async => session);
      expect(await service.isLoggedIn(), true);
      expect(AccountScope.capture(prefs).userId, 'alice');
    },
  );

  test(
    'web validation during sign-in cannot clear or adopt the old cookie',
    () async {
      final started = Completer<void>();
      final created = Completer<models.Session>();
      final oldSession = _Session();
      when(() => oldSession.userId).thenReturn('alice');
      when(
        () => account.getSession(sessionId: 'current'),
      ).thenAnswer((_) async => oldSession);
      when(account.createAnonymousSession).thenAnswer((_) {
        started.complete();
        return created.future;
      });
      final login = service.signInAnonymously();
      await started.future;
      expect(await service.isLoggedIn(), false);
      expect(AccountScope.capture(prefs).userId, isNull);
      final newSession = _Session();
      when(() => newSession.userId).thenReturn('bob');
      created.complete(newSession);
      await login;
      expect(AccountScope.capture(prefs).userId, 'bob');
      expect(prefs.getBool('olitun_has_local_session'), true);
    },
  );
}
