import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/core/auth/account_scope.dart';
import 'package:itun/core/auth/appwrite_auth_service.dart';
import 'package:itun/core/network/network_info.dart';
import 'package:itun/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:itun/features/auth/data/repositories/auth_repository_impl.dart';

class _Client extends Mock implements Client {
  _Client() { when(() => setSession(any())).thenReturn(this); }
}
class _Account extends Mock implements Account {}
class _Functions extends Mock implements Functions {}
class _Session extends Mock implements models.Session {}
class _Network extends Mock implements NetworkInfo {}
class _Preferences extends Mock implements models.Preferences {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  late _Account account;
  late AppwriteAuthService service;
  late _Session session;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    account = _Account();
    session = _Session();
    when(() => session.userId).thenReturn('a');
    service = AppwriteAuthService.forTesting(
      client: _Client(), account: account, functions: _Functions(), prefs: prefs,
      isWebOverride: false,
      connectivity: () async => [ConnectivityResult.none],
    );
  });

  for (final path in ['email', 'otp', 'anonymous', 'oauth']) {
    test('$path persists session owner before a profile fetch can fail', () async {
      when(() => account.createEmailPasswordSession(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => session);
      when(() => account.createSession(userId: any(named: 'userId'), secret: any(named: 'secret')))
          .thenAnswer((_) async => session);
      when(account.createAnonymousSession).thenAnswer((_) async => session);
      switch (path) {
        case 'email': await service.signInWithEmail(email: 'a@example.test', password: 'not-a-real-password'); break;
        case 'otp': await service.verifyOtp(userId: 'a', secret: 'test-otp'); break;
        case 'anonymous': await service.signInAnonymously(); break;
        default: expect(await service.exchangeOAuthToken('a', 'test-otp'), isTrue);
      }
      expect(AccountScope.capture(prefs).userId, 'a');
      expect(prefs.getBool(SessionPersistence.hasLocalSessionKey), isTrue);
      await expectLater(service.getMe(), throwsA(isA<AppwriteException>()));
      expect(AccountScope.capture(prefs).userId, 'a');
    });
  }

  test('used repository logout path clears identity offline and prevents cookie resurrection', () async {
    await AccountScope.capture(prefs).identify('a');
    await prefs.setBool(SessionPersistence.hasLocalSessionKey, true);
    await prefs.setString(SessionPersistence.webSessionSecretKey, 'test-only');
    await prefs.setInt(SessionPersistence.webSessionTimestampKey, 1);
    await prefs.setString('user_stats_a', 'preserve-account-cache');
    final old = AccountScope.capture(prefs);
    when(() => account.deleteSession(sessionId: 'current'))
        .thenThrow(AppwriteException('offline', 0));
    final network = _Network();
    when(() => network.isConnected).thenAnswer((_) async => false);
    final repo = AuthRepositoryImpl(
      remoteDataSource: AuthRemoteDataSourceImpl(service), networkInfo: network,
    );
    expect((await repo.signOut()).isRight(), isTrue);
    expect(old.isCurrent, isFalse);
    expect(AccountScope.capture(prefs).isGuest, isTrue);
    expect(prefs.getBool(SessionPersistence.hasLocalSessionKey), isFalse);
    expect(prefs.getString(SessionPersistence.webSessionSecretKey), isNull);
    expect(prefs.getInt(SessionPersistence.webSessionTimestampKey), isNull);
    expect(prefs.getString('user_stats_a'), 'preserve-account-cache');
    expect(await service.isLoggedIn(), isFalse);
    await expectLater(service.getMe(), throwsA(isA<AppwriteException>()));
    verifyNever(() => account.getSession(sessionId: any(named: 'sessionId')));
    verifyNever(() => network.isConnected);
  });

  test('legacy session validation learns owner; transient validation keeps it', () async {
    await prefs.setBool(SessionPersistence.hasLocalSessionKey, true);
    when(() => account.getSession(sessionId: 'current')).thenAnswer((_) async => session);
    expect(await service.isLoggedIn(), isTrue);
    expect(AccountScope.capture(prefs).userId, 'a');
    when(() => account.getSession(sessionId: 'current')).thenThrow(AppwriteException('offline', 0));
    expect(await service.isLoggedIn(), isTrue);
    expect(AccountScope.capture(prefs).userId, 'a');
    when(() => account.getSession(sessionId: 'current')).thenThrow(AppwriteException('expired', 401));
    expect(await service.isLoggedIn(), isFalse);
    expect(AccountScope.capture(prefs).isGuest, isTrue);
  });

  test('late current-session validation cannot restore signed-out identity', () async {
    await prefs.setBool(SessionPersistence.hasLocalSessionKey, true);
    await AccountScope.capture(prefs).identify('a');
    final started = Completer<void>();
    final response = Completer<models.Session>();
    when(() => account.getSession(sessionId: 'current')).thenAnswer((_) {
      started.complete(); return response.future;
    });
    final pending = service.isLoggedIn();
    await started.future;
    await AccountScope.signOut(prefs);
    response.complete(session);
    expect(await pending, isFalse);
    expect(AccountScope.capture(prefs).isGuest, isTrue);
  });

  test('SDK dispatch rechecks scope after connectivity awaits', () async {
    await AccountScope.capture(prefs).identify('a');
    final scope = AccountScope.capture(prefs);
    final connectivity = Completer<List<ConnectivityResult>>();
    final guardedService = AppwriteAuthService.forTesting(
      client: _Client(), account: account, functions: _Functions(), prefs: prefs,
      isWebOverride: false, connectivity: () => connectivity.future,
    );
    final pending = scope.run(() => guardedService.updatePrefs({'test': true}));
    final assertion = expectLater(pending, throwsStateError);
    await (await AccountScope.beginSignIn(prefs)).identify('b');
    connectivity.complete([ConnectivityResult.wifi]);
    await assertion;
    verifyNever(() => account.updatePrefs(prefs: any(named: 'prefs')));
  });

  test('session mutation waits for an already dispatched scoped request', () async {
    await AccountScope.capture(prefs).identify('a');
    final scope = AccountScope.capture(prefs);
    final started = Completer<void>();
    final response = Completer<models.Preferences>();
    when(account.getPrefs).thenAnswer((_) { started.complete(); return response.future; });
    when(account.createAnonymousSession).thenAnswer((_) async => session);
    final online = AppwriteAuthService.forTesting(
      client: _Client(), account: account, functions: _Functions(), prefs: prefs,
      isWebOverride: false, connectivity: () async => [ConnectivityResult.wifi],
    );
    final read = scope.run(online.getPrefs);
    final assertion = expectLater(read, throwsStateError);
    await started.future;
    final login = online.signInAnonymously();
    await Future<void>.delayed(Duration.zero);
    verifyNever(account.createAnonymousSession);
    response.complete(_Preferences());
    await assertion;
    await login;
    verify(account.createAnonymousSession).called(1);
    expect(AccountScope.capture(prefs).userId, 'a');
  });

  test('validation during login cannot bind the previous SDK account', () async {
    await AccountScope.capture(prefs).identify('a');
    await prefs.setBool(SessionPersistence.hasLocalSessionKey, true);
    final started = Completer<void>();
    final created = Completer<models.Session>();
    when(account.createAnonymousSession).thenAnswer((_) {
      started.complete(); return created.future;
    });
    when(() => account.getSession(sessionId: 'current')).thenAnswer((_) async => session);
    final login = service.signInAnonymously();
    await started.future;
    expect(await service.isLoggedIn(), isFalse);
    expect(AccountScope.capture(prefs).userId, isNull);
    when(() => session.userId).thenReturn('b');
    created.complete(session);
    await login;
    expect(AccountScope.capture(prefs).userId, 'b');
  });

  test('corrupt metadata and preference clear/relogin fail closed for old work', () async {
    await prefs.setString(AccountScope.storageKey, '{bad');
    expect(AccountScope.capture(prefs).isKnown, isFalse);
    await (await AccountScope.beginSignIn(prefs)).identify('a');
    final old = AccountScope.capture(prefs);
    await prefs.clear();
    await AccountScope.capture(prefs).identify('a');
    expect(old.isCurrent, isFalse);
  });
}
