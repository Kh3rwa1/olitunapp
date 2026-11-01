import 'package:appwrite/appwrite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/core/auth/account_scope.dart';
import 'package:itun/core/auth/appwrite_auth_service.dart';

import '../../helpers/fake_auth_worker.dart';

class _Client extends Mock implements Client {}

class _Account extends Mock implements Account {}

// Losing credentials (expiry, offline, sign-out) must never move a known
// owner's progress to the guest profile.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  late FakeAuthWorker worker;

  AppwriteAuthService build({String? legacySecret}) {
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
    SharedPreferences.setMockInitialValues({'olitun_has_local_session': true});
    prefs = await SharedPreferences.getInstance();
    await (await AccountScope.beginSignIn(prefs)).identify('alice');
    worker = FakeAuthWorker();
    worker.on('POST', '/logout', (_) => FakeAuthWorker.json({'ok': true}));
  });

  test('offline keeps the session and its owner', () async {
    final service = build();
    await service.worker.adopt(FakeAuthWorker.session('alice'));
    worker.offline = true;
    expect(await service.isLoggedIn(), isTrue);
    final scope = AccountScope.capture(prefs);
    expect(scope.userId, 'alice');
    expect(scope.statsKey, 'user_stats_alice');
  });

  test(
    'a rejected refresh signs out without redirecting progress to guest',
    () async {
      worker.on(
        'POST',
        '/refresh',
        (_) =>
            FakeAuthWorker.json({'ok': false, 'error': 'SESSION_EXPIRED'}, 401),
      );
      final service = build();
      await service.worker.adopt(
        FakeAuthWorker.session(
          'alice',
          expiresAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      );
      expect(await service.worker.accessToken(), isNull);
      expect(await service.isLoggedIn(), isFalse);
      final scope = AccountScope.capture(prefs);
      expect(scope.userId, 'alice');
      expect(scope.isGuest, isFalse);
    },
  );

  test('explicit logout blocks a surviving Appwrite session', () async {
    final service = build(legacySecret: 'still-on-disk');
    await service.signOut();
    expect(AccountScope.capture(prefs).isExplicitlySignedOut, isTrue);
    expect(await service.isLoggedIn(), isFalse);
    expect(worker.callsTo('/appwrite/migrate'), isEmpty);
  });

  test(
    'a migrated different account creates a new owner incarnation',
    () async {
      worker.on(
        'POST',
        '/appwrite/migrate',
        (_) => FakeAuthWorker.json(FakeAuthWorker.session('bob')),
      );
      final old = AccountScope.capture(prefs);
      final service = build(legacySecret: 'bobs-cookie');
      expect(await service.isLoggedIn(), isTrue);
      expect(AccountScope.capture(prefs).userId, 'bob');
      expect(old.isCurrent, isFalse);
    },
  );
}
