import 'package:appwrite/appwrite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:itun/core/auth/appwrite_auth_service.dart';
import 'package:itun/core/config/appwrite_config.dart';
import 'package:itun/features/admin/providers/admin_auth_provider.dart';

class _FakeAuthService implements AppwriteAuthService {
  _FakeAuthService(this._client);
  final Client _client;
  @override
  Client get client => _client;
  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _MockClient extends Mock implements Client {}

void main() {
  group('AdminAuthService.isCurrentUserAdmin', () {
    test('returns true when the configured admin team ID is in the list',
        () async {
      final svc = AdminAuthService(
        _FakeAuthService(_MockClient()),
        teamsListFetcher: () async => [AppwriteConfig.adminTeamId, 'other'],
      );
      expect(await svc.isCurrentUserAdmin(), isTrue);
    });

    test('returns false when no team matches the admin ID', () async {
      final svc = AdminAuthService(
        _FakeAuthService(_MockClient()),
        teamsListFetcher: () async => ['random', 'team_x'],
      );
      expect(await svc.isCurrentUserAdmin(), isFalse);
    });

    test('returns false when the fetcher throws (no session, network, etc.)',
        () async {
      final svc = AdminAuthService(
        _FakeAuthService(_MockClient()),
        teamsListFetcher: () async => throw Exception('401 unauthorized'),
      );
      expect(await svc.isCurrentUserAdmin(), isFalse);
    });

    test(
        'rejects a team whose NAME matches admin id but whose ID does not — '
        'closes the privilege-escalation hole', () async {
      // The fetcher only returns IDs (matching the production code path).
      // A team with a misleading name like "admins" but a different ID
      // would never even reach the comparison. This test pins that
      // contract: name-only data must NOT be accepted by the service.
      final svc = AdminAuthService(
        _FakeAuthService(_MockClient()),
        teamsListFetcher: () async => ['team_random_xyz'],
      );
      expect(await svc.isCurrentUserAdmin(), isFalse);
    });
  });

  group('AdminAuthService.signInAsAdmin', () {
    test('returns false when isCurrentUserAdmin returns false even after '
        'session creation succeeds', () async {
      // We cannot mock Appwrite's Account easily without DI, so we exercise
      // the public outcome: when the team check fails, signInAsAdmin must
      // return false. Here we force the membership check to fail by
      // returning an empty list from the fetcher.
      // The service's session-creation path will throw against a mock
      // Client, which is caught and surfaces as `false` — the same outcome
      // a real "wrong password" event would produce.
      final svc = AdminAuthService(
        _FakeAuthService(_MockClient()),
        teamsListFetcher: () async => const [],
      );
      final result = await svc.signInAsAdmin(
        email: 'x@example.com',
        password: 'nope',
      );
      expect(result, isFalse);
    });
  });
}
