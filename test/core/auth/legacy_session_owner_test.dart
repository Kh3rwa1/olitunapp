import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/core/auth/account_scope.dart';
import 'package:itun/core/auth/appwrite_auth_service.dart';
import 'package:itun/core/auth/auth_repository.dart';
import 'package:itun/features/profile/data/repositories/profile_repository_impl.dart';

import '../../helpers/fake_auth_worker.dart';

class _Client extends Mock implements Client {}

class _Account extends Mock implements Account {}

class _Auth extends Mock implements AuthRepository {}

// A device upgraded from the Appwrite-era app has `olitun_has_local_session`
// and possibly no recorded owner. Its Appwrite session is moved to a Worker
// session once; ownership must never be guessed along the way.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  late FakeAuthWorker worker;

  Future<AppwriteAuthService> service({String? legacySecret}) async {
    final client = _Client();
    when(() => client.setSession(any())).thenReturn(client);
    return AppwriteAuthService.forTesting(
      client: client,
      account: _Account(),
      workerAuth: worker.auth(prefs, legacySecret: legacySecret),
      prefs: prefs,
      isWebOverride: false,
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'olitun_has_local_session': true,
      'user_progress_data':
          'unowned legacy progress must not become guest data',
    });
    prefs = await SharedPreferences.getInstance();
    worker = FakeAuthWorker();
  });

  test(
    'a dead legacy session cannot turn unknown ownership into a guest',
    () async {
      worker.on(
        'POST',
        '/appwrite/migrate',
        (_) => FakeAuthWorker.json({
          'ok': false,
          'error': 'INVALID_APPWRITE_SESSION',
        }, 401),
      );
      final auth = await service(legacySecret: 'expired');
      expect(await auth.isLoggedIn(), false);
      expect(AccountScope.capture(prefs).isKnown, false);
      expect(AccountScope.capture(prefs).isGuest, false);

      final saved = {for (final key in prefs.getKeys()) key: prefs.get(key)!};
      SharedPreferences.setMockInitialValues(saved);
      final restarted = await SharedPreferences.getInstance();
      expect(AccountScope.capture(restarted).isKnown, false);
      final repo = ProfileRepositoryImpl(_Auth(), restarted);
      expect((await repo.getUserStats()).isLeft(), true);
      expect(restarted.getString('user_stats_guest'), isNull);
    },
  );

  test(
    'a migrated legacy session resolves the owner to the Appwrite id',
    () async {
      worker.on(
        'POST',
        '/appwrite/migrate',
        (_) => FakeAuthWorker.json(FakeAuthWorker.session('alice')),
      );
      final auth = await service(legacySecret: 'alive');
      expect(await auth.isLoggedIn(), true);
      expect(AccountScope.capture(prefs).userId, 'alice');
    },
  );

  test(
    'offline at first launch keeps the user signed in and retries',
    () async {
      worker.offline = true;
      final auth = await service(legacySecret: 'alive');
      expect(await auth.isLoggedIn(), true);
      expect(AccountScope.capture(prefs).isGuest, false);

      worker.offline = false;
      worker.on(
        'POST',
        '/appwrite/migrate',
        (_) => FakeAuthWorker.json(FakeAuthWorker.session('alice')),
      );
      expect(await auth.isLoggedIn(), true);
      expect(AccountScope.capture(prefs).userId, 'alice');
    },
  );

  test('validation during a sign-in cannot adopt the old owner', () async {
    final started = Completer<void>();
    final release = Completer<void>();
    worker.on(
      'POST',
      '/appwrite/migrate',
      (_) => FakeAuthWorker.json(FakeAuthWorker.session('alice')),
    );
    final auth = await service(legacySecret: 'alive');
    expect(await auth.isLoggedIn(), true);
    expect(AccountScope.capture(prefs).userId, 'alice');

    // Hold the guest call open so isLoggedIn runs while it is pending.
    worker.on('POST', '/guest', (_) async {
      started.complete();
      await release.future;
      return FakeAuthWorker.json(
        FakeAuthWorker.session('bob', guest: true, refresh: 'sid2.r'),
      );
    });
    worker.on('POST', '/logout', (_) => FakeAuthWorker.json({'ok': true}));
    final login = auth.signInAnonymously();
    await started.future.timeout(const Duration(seconds: 5));
    expect(await auth.isLoggedIn(), false);
    expect(AccountScope.capture(prefs).userId, isNull);
    release.complete();
    await login;
    expect(AccountScope.capture(prefs).userId, 'bob');
    expect(prefs.getBool('olitun_has_local_session'), true);
  });

  test('a Worker that is down never signs the user out', () async {
    worker.on(
      'POST',
      '/appwrite/migrate',
      (_) => http.Response('upstream error', 503),
    );
    final auth = await service(legacySecret: 'alive');
    expect(await auth.isLoggedIn(), true);
    expect(prefs.getBool('olitun_has_local_session'), true);
  });
}
