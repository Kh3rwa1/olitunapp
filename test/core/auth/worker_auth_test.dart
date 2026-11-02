import 'dart:async';
import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:itun/core/auth/account_scope.dart';
import 'package:itun/core/auth/worker_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_auth_worker.dart';

void main() {
  late FakeAuthWorker worker;
  late SharedPreferences prefs;

  Future<void> reset([Map<String, Object> values = const {}]) async {
    SharedPreferences.setMockInitialValues(values);
    prefs = await SharedPreferences.getInstance();
    worker = FakeAuthWorker();
  }

  group('session storage', () {
    setUp(reset);

    test('adopt persists the session across restarts', () async {
      final auth = worker.auth(prefs);
      await auth.adopt(FakeAuthWorker.session('u1', email: 'a@b.in'));
      expect(prefs.getString(WorkerAuth.storageKey), isNotNull);

      final restarted = worker.auth(prefs);
      final session = await restarted.current();
      expect(session?.user.id, 'u1');
      expect(session?.user.email, 'a@b.in');
      expect(await restarted.accessToken(), 'access-1');
    });

    test('clear signs out locally and revokes on the Worker', () async {
      worker.on('POST', '/logout', (_) => FakeAuthWorker.json({'ok': true}));
      final auth = worker.auth(prefs);
      await auth.adopt(FakeAuthWorker.session('u1'));
      await auth.clear();
      await Future<void>.delayed(Duration.zero);
      expect(await auth.current(), isNull);
      expect(worker.callsTo('/logout'), hasLength(1));
      expect(
        jsonDecode(worker.callsTo('/logout').single.body)['refreshToken'],
        'sid.refresh',
      );
    });

    test('an unreadable stored session is dropped', () async {
      await reset({WorkerAuth.storageKey: '{not json'});
      expect(await worker.auth(prefs).current(), isNull);
      expect(prefs.getString(WorkerAuth.storageKey), isNull);
    });
  });

  group('access token refresh', () {
    setUp(reset);

    test(
      'refreshes shortly before expiry, once for concurrent callers',
      () async {
        var refreshes = 0;
        worker.on('POST', '/refresh', (_) {
          refreshes++;
          return FakeAuthWorker.json(
            FakeAuthWorker.session('u1', access: 'access-2'),
          );
        });
        final auth = worker.auth(prefs);
        await auth.adopt(
          FakeAuthWorker.session(
            'u1',
            expiresAt: DateTime.now().add(const Duration(minutes: 1)),
          ),
        );
        final tokens = await Future.wait([
          auth.accessToken(),
          auth.accessToken(),
          auth.accessToken(),
        ]);
        expect(tokens, everyElement('access-2'));
        expect(refreshes, 1);
      },
    );

    test('a rejected refresh signs the device out', () async {
      worker.on(
        'POST',
        '/refresh',
        (_) => FakeAuthWorker.json({
          'ok': false,
          'error': 'INVALID_REFRESH_TOKEN',
        }, 401),
      );
      final auth = worker.auth(prefs);
      await auth.adopt(
        FakeAuthWorker.session(
          'u1',
          expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      );
      expect(await auth.accessToken(), isNull);
      expect(await auth.cached(), isNull);
    });

    group('a refresh still in flight', () {
      late Completer<http.Response> pending;
      late WorkerAuth auth;

      setUp(() async {
        pending = Completer<http.Response>();
        worker.on('POST', '/refresh', (_) => pending.future);
        worker.on('POST', '/logout', (_) => FakeAuthWorker.json({'ok': true}));
        auth = worker.auth(prefs);
        await auth.adopt(
          FakeAuthWorker.session(
            'u1',
            expiresAt: DateTime.now().add(const Duration(minutes: 1)),
          ),
        );
      });

      test('cannot bring a session back after sign-out', () async {
        final token = auth.accessToken();
        await Future<void>.delayed(Duration.zero);
        await auth.clear();
        pending.complete(
          FakeAuthWorker.json(FakeAuthWorker.session('u1', access: 'late')),
        );
        expect(await token, isNull);
        expect(await auth.cached(), isNull);
        expect(prefs.getString(WorkerAuth.storageKey), isNull);
        expect(await worker.auth(prefs).current(), isNull);
      });

      test('cannot overwrite the account signed in meanwhile', () async {
        final token = auth.accessToken();
        await Future<void>.delayed(Duration.zero);
        await auth.adopt(
          FakeAuthWorker.session('u2', access: 'access-u2', refresh: 'sid2.r'),
        );
        pending.complete(
          FakeAuthWorker.json(FakeAuthWorker.session('u1', access: 'late')),
        );
        expect(await token, 'access-u2');
        expect((await auth.cached())?.user.id, 'u2');
        expect((await worker.auth(prefs).current())?.user.id, 'u2');
        await Future<void>.delayed(Duration.zero);
        final revoked = worker
            .callsTo('/logout')
            .map((c) => jsonDecode(c.body)['refreshToken']);
        expect(revoked, contains('sid.refresh'));
        expect(revoked, isNot(contains('sid2.r')));
      });

      test('is still adopted after a profile update', () async {
        final token = auth.accessToken();
        await Future<void>.delayed(Duration.zero);
        final current = (await auth.cached())!;
        await auth.updateUser(
          WorkerUser.fromJson({...current.user.toJson(), 'name': 'Renamed'}),
        );
        pending.complete(
          FakeAuthWorker.json(FakeAuthWorker.session('u1', access: 'fresh')),
        );
        expect(await token, 'fresh');
        expect((await auth.cached())?.accessToken, 'fresh');
      });

      test('a late rejection does not sign out the next account', () async {
        final token = auth.accessToken();
        await Future<void>.delayed(Duration.zero);
        await auth.adopt(
          FakeAuthWorker.session('u2', access: 'access-u2', refresh: 'sid2.r'),
        );
        pending.complete(
          FakeAuthWorker.json({
            'ok': false,
            'error': 'INVALID_REFRESH_TOKEN',
          }, 401),
        );
        expect(await token, 'access-u2');
        expect((await auth.cached())?.user.id, 'u2');
      });
    });

    test('offline keeps a still-valid token and the session', () async {
      final auth = worker.auth(prefs);
      await auth.adopt(
        FakeAuthWorker.session(
          'u1',
          expiresAt: DateTime.now().add(const Duration(minutes: 1)),
        ),
      );
      worker.offline = true;
      expect(await auth.accessToken(), 'access-1');
      expect((await auth.cached())?.user.id, 'u1');
    });
  });

  group('Appwrite session migration', () {
    test('moves a legacy session once and keeps the Appwrite id', () async {
      await reset({WorkerAuth.legacySessionFlagKey: true});
      var cleared = 0;
      worker.on('POST', '/appwrite/migrate', (request) {
        expect(jsonDecode(request.body)['session'], 'legacy-secret');
        return FakeAuthWorker.json(
          FakeAuthWorker.session('appwrite_alice', email: 'alice@x.in'),
        );
      });
      final auth = worker.auth(
        prefs,
        legacySecret: 'legacy-secret',
        onLegacyCleared: () => cleared++,
      );
      final session = await auth.current();
      expect(session?.user.id, 'appwrite_alice');
      expect(prefs.getBool(WorkerAuth.legacyMigratedKey), isTrue);
      expect(cleared, 1);

      // Second call uses the stored session; no new migration.
      await auth.current();
      expect(worker.callsTo('/appwrite/migrate'), hasLength(1));
    });

    test(
      'a dead legacy session signs out but keeps the owner unknown',
      () async {
        await reset({WorkerAuth.legacySessionFlagKey: true});
        worker.on(
          'POST',
          '/appwrite/migrate',
          (_) => FakeAuthWorker.json({
            'ok': false,
            'error': 'INVALID_APPWRITE_SESSION',
          }, 401),
        );
        final auth = worker.auth(prefs, legacySecret: 'dead');
        expect(await auth.current(), isNull);
        expect(prefs.getBool(WorkerAuth.legacySessionFlagKey), isFalse);
        final scope = AccountScope.capture(prefs);
        expect(scope.isGuest, isFalse);
        expect(scope.isKnown, isFalse);
      },
    );

    test('offline migration is retried later instead of signing out', () async {
      await reset({WorkerAuth.legacySessionFlagKey: true});
      final auth = worker.auth(prefs, legacySecret: 'legacy-secret');
      worker.offline = true;
      await expectLater(auth.current(), throwsA(isA<AppwriteException>()));
      expect(prefs.getBool(WorkerAuth.legacySessionFlagKey), isTrue);

      worker.offline = false;
      worker.on(
        'POST',
        '/appwrite/migrate',
        (_) => FakeAuthWorker.json(FakeAuthWorker.session('appwrite_bob')),
      );
      expect((await auth.current())?.user.id, 'appwrite_bob');
    });

    test('no cookie means nothing to move', () async {
      await reset({WorkerAuth.legacySessionFlagKey: true});
      final auth = worker.auth(prefs);
      expect(await auth.current(), isNull);
      expect(worker.calls, isEmpty);
      expect(prefs.getBool(WorkerAuth.legacyMigratedKey), isTrue);
    });

    test('the web build never tries to migrate', () async {
      await reset({WorkerAuth.legacySessionFlagKey: true});
      final auth = worker.auth(prefs, legacySecret: 'x', isWeb: true);
      expect(await auth.current(), isNull);
      expect(worker.calls, isEmpty);
    });
  });

  group('WorkerUser', () {
    test('maps to an Appwrite user for older callers', () {
      final user = WorkerUser.fromJson(
        FakeAuthWorker.session('u9', email: 'm@x.in', name: 'Mani')['user']
            as Map<String, dynamic>,
      );
      final appwrite = user.toAppwriteUser();
      expect(appwrite.$id, 'u9');
      expect(appwrite.email, 'm@x.in');
      expect(appwrite.name, 'Mani');
      expect(appwrite.emailVerification, isTrue);
      expect(appwrite.registration, '2026-11-01T00:00:00.000Z');
    });
  });
}
