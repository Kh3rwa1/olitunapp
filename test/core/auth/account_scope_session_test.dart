import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/core/auth/account_scope.dart';
import 'package:itun/core/auth/appwrite_auth_service.dart';
import 'package:itun/core/network/network_info.dart';
import 'package:itun/core/auth/auth_remote_datasource.dart';
import 'package:itun/core/auth/auth_repository_impl.dart';

import '../../helpers/fake_auth_worker.dart';

class _Client extends Mock implements Client {
  _Client() {
    when(() => setSession(any())).thenReturn(this);
  }
}

class _Account extends Mock implements Account {}

class _Network extends Mock implements NetworkInfo {}

// Account-scope invariants for Worker sign-in: the owner is recorded before
// anything else can fail, sign-out wins over late responses, and scoped
// requests never run against a different account.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  late FakeAuthWorker worker;
  late AppwriteAuthService service;

  AppwriteAuthService build({
    Future<List<ConnectivityResult>> Function()? connectivity,
    String? legacySecret,
  }) => AppwriteAuthService.forTesting(
    client: _Client(),
    account: _Account(),
    workerAuth: worker.auth(prefs, legacySecret: legacySecret),
    prefs: prefs,
    isWebOverride: false,
    connectivity: connectivity ?? () async => [ConnectivityResult.none],
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    worker = FakeAuthWorker();
    worker.on('POST', '/logout', (_) => FakeAuthWorker.json({'ok': true}));
    service = build();
  });

  for (final path in ['otp', 'anonymous', 'google']) {
    test(
      '$path persists session owner before a profile fetch can fail',
      () async {
        final ok = FakeAuthWorker.json(FakeAuthWorker.session('a'));
        worker.on('POST', '/email/verify', (_) => ok);
        worker.on('POST', '/guest', (_) => ok);
        worker.on('POST', '/exchange', (_) => ok);
        worker.on(
          'GET',
          '/me',
          (_) => FakeAuthWorker.json({'ok': false, 'error': 'BROKEN'}, 500),
        );
        switch (path) {
          case 'otp':
            await service.verifyOtp(userId: 'a@x.in', secret: '123456');
            break;
          case 'anonymous':
            await service.signInAnonymously();
            break;
          default:
            expect(await service.exchangeLoginCode('one-time'), isTrue);
        }
        expect(AccountScope.capture(prefs).userId, 'a');
        expect(prefs.getBool(SessionPersistence.hasLocalSessionKey), isTrue);
        await expectLater(service.getMe(), throwsA(isA<AppwriteException>()));
        expect(AccountScope.capture(prefs).userId, 'a');
      },
    );
  }

  test(
    'repository logout clears identity offline and prevents resurrection',
    () async {
      worker.on(
        'POST',
        '/guest',
        (_) => FakeAuthWorker.json(FakeAuthWorker.session('a')),
      );
      await service.signInAnonymously();
      await prefs.setString('user_stats_a', 'preserve-account-cache');
      final old = AccountScope.capture(prefs);
      worker.offline = true;
      final network = _Network();
      when(() => network.isConnected).thenAnswer((_) async => false);
      final repo = AuthRepositoryImpl(
        remoteDataSource: AuthRemoteDataSourceImpl(service),
        networkInfo: network,
      );
      expect((await repo.signOut()).isRight(), isTrue);
      expect(old.isCurrent, isFalse);
      expect(AccountScope.capture(prefs).isGuest, isTrue);
      expect(prefs.getBool(SessionPersistence.hasLocalSessionKey), isFalse);
      expect(prefs.getString('user_stats_a'), 'preserve-account-cache');
      expect(await service.isLoggedIn(), isFalse);
      await expectLater(service.getMe(), throwsA(isA<AppwriteException>()));
      verifyNever(() => network.isConnected);
    },
  );

  test(
    'a late session migration cannot restore a signed-out identity',
    () async {
      await prefs.setBool(SessionPersistence.hasLocalSessionKey, true);
      await AccountScope.capture(prefs).identify('a');
      final started = Completer<void>();
      final release = Completer<void>();
      worker.on('POST', '/appwrite/migrate', (_) async {
        started.complete();
        await release.future;
        return FakeAuthWorker.json(FakeAuthWorker.session('a'));
      });
      final migrating = build(legacySecret: 'alive');
      final pending = migrating.isLoggedIn();
      await started.future;
      await AccountScope.signOut(prefs);
      release.complete();
      expect(await pending, isFalse);
      expect(AccountScope.capture(prefs).isGuest, isTrue);
    },
  );

  test(
    'scoped requests recheck the account after connectivity awaits',
    () async {
      worker.on(
        'POST',
        '/guest',
        (_) => FakeAuthWorker.json(FakeAuthWorker.session('a')),
      );
      await service.signInAnonymously();
      final scope = AccountScope.capture(prefs);
      final connectivity = Completer<List<ConnectivityResult>>();
      final guarded = build(connectivity: () => connectivity.future);
      final pending = scope.run(() => guarded.updatePrefs({'test': true}));
      final assertion = expectLater(pending, throwsStateError);
      await (await AccountScope.beginSignIn(prefs)).identify('b');
      connectivity.complete([ConnectivityResult.wifi]);
      await assertion;
      expect(worker.callsTo('/prefs'), isEmpty);
    },
  );

  test('a sign-in waits for an already dispatched scoped request', () async {
    worker.on(
      'POST',
      '/guest',
      (_) => FakeAuthWorker.json(FakeAuthWorker.session('a')),
    );
    await service.signInAnonymously();
    final scope = AccountScope.capture(prefs);
    final started = Completer<void>();
    final release = Completer<void>();
    worker.on('GET', '/prefs', (_) async {
      started.complete();
      await release.future;
      return FakeAuthWorker.json({'ok': true, 'prefs': {}});
    });
    final online = build(connectivity: () async => [ConnectivityResult.wifi]);
    final read = scope.run(online.getPrefs);
    final assertion = expectLater(read, throwsStateError);
    await started.future;
    final guestCallsBefore = worker.callsTo('/guest').length;
    final login = online.signInAnonymously();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(worker.callsTo('/guest').length, guestCallsBefore);
    release.complete();
    await assertion;
    await login;
    expect(worker.callsTo('/guest').length, guestCallsBefore + 1);
    expect(AccountScope.capture(prefs).userId, 'a');
  });

  test('validation during a login cannot bind the previous account', () async {
    worker.on(
      'POST',
      '/guest',
      (_) => FakeAuthWorker.json(FakeAuthWorker.session('a')),
    );
    await service.signInAnonymously();
    final started = Completer<void>();
    final release = Completer<void>();
    worker.on('POST', '/guest', (_) async {
      started.complete();
      await release.future;
      return FakeAuthWorker.json(
        FakeAuthWorker.session('b', refresh: 'sid-b.r'),
      );
    });
    final login = service.signInAnonymously();
    await started.future;
    expect(await service.isLoggedIn(), isFalse);
    expect(AccountScope.capture(prefs).userId, isNull);
    release.complete();
    await login;
    expect(AccountScope.capture(prefs).userId, 'b');
  });

  test(
    'corrupt metadata and preference clear/relogin fail closed for old work',
    () async {
      await prefs.setString(AccountScope.storageKey, '{bad');
      expect(AccountScope.capture(prefs).isKnown, isFalse);
      await (await AccountScope.beginSignIn(prefs)).identify('a');
      final old = AccountScope.capture(prefs);
      await prefs.clear();
      await AccountScope.capture(prefs).identify('a');
      expect(old.isCurrent, isFalse);
    },
  );
}
