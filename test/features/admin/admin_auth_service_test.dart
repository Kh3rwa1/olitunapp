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

class _FakeTeam {
  _FakeTeam({required this.id, required this.name});
  final String id;
  final String name;
}

abstract class _TeamsApi {
  Future<List<_FakeTeam>> list();
}

class _MockTeamsApi extends Mock implements _TeamsApi {}

AdminAuthService _serviceFor(_TeamsApi teams) => AdminAuthService(
  _FakeAuthService(_MockClient()),
  teamsListFetcher: () async => (await teams.list()).map((t) => t.id).toList(),
);

void main() {
  group('AdminAuthService.isCurrentUserAdmin (Teams.list mocked)', () {
    test(
      'returns true when a team ID matches the configured admin ID',
      () async {
        final teams = _MockTeamsApi();
        when(teams.list).thenAnswer(
          (_) async => [
            _FakeTeam(id: 'random', name: 'random_team'),
            _FakeTeam(id: AppwriteConfig.adminTeamId, name: 'whatever'),
          ],
        );

        expect(await _serviceFor(teams).isCurrentUserAdmin(), isTrue);
        verify(teams.list).called(1);
      },
    );

    test('returns false when no team ID matches', () async {
      final teams = _MockTeamsApi();
      when(teams.list).thenAnswer(
        (_) async => [
          _FakeTeam(id: 'team_a', name: 'A'),
          _FakeTeam(id: 'team_b', name: 'B'),
        ],
      );

      expect(await _serviceFor(teams).isCurrentUserAdmin(), isFalse);
    });

    test(
      'rejects a team whose NAME equals the admin ID but whose ID differs',
      () async {
        final teams = _MockTeamsApi();
        when(teams.list).thenAnswer(
          (_) async => [
            _FakeTeam(id: 'spoof_id', name: AppwriteConfig.adminTeamId),
          ],
        );

        expect(await _serviceFor(teams).isCurrentUserAdmin(), isFalse);
      },
    );

    test('returns false when Teams.list throws', () async {
      final teams = _MockTeamsApi();
      when(teams.list).thenThrow(Exception('401 unauthorized'));

      expect(await _serviceFor(teams).isCurrentUserAdmin(), isFalse);
    });
  });

  group('AdminAuthService.signInAsAdmin', () {
    test('returns false when the membership check fails', () async {
      final teams = _MockTeamsApi();
      when(teams.list).thenAnswer((_) async => const []);

      final result = await _serviceFor(
        teams,
      ).signInAsAdmin(email: 'x@example.com', password: 'nope');
      expect(result, isFalse);
    });
  });
}
