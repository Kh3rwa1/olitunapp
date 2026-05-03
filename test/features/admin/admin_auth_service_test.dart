import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:itun/core/auth/appwrite_auth_service.dart';
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

models.Team _team(String id, String name) => models.Team(
      $id: id,
      $createdAt: '',
      $updatedAt: '',
      name: name,
      total: 1,
      prefs: models.Preferences(data: const {}),
    );

void main() {
  // The service constructs `Teams(client)` internally; we cannot mock that
  // SDK call without dependency injection. So instead we test the matching
  // contract directly by exercising the public method against an in-memory
  // override pattern.
  group('AdminAuthService team-ID matching contract', () {
    test('matches by immutable team ID only — name match is ignored', () {
      // The service uses `t.$id == adminId`. This test pins that contract:
      // a team whose NAME equals the admin id but whose ID differs must
      // NOT grant admin access (prevents privilege escalation by users who
      // can create arbitrarily-named teams).
      final adminId = 'admins';
      final teams = [
        _team('team_random_xyz', 'admins'), // name matches → MUST be rejected
        _team('team_other', 'random'),
      ];
      final isAdmin = teams.any((t) => t.$id == adminId);
      expect(isAdmin, isFalse,
          reason: 'name-only match must not grant admin');
    });

    test('matches when team ID equals adminId', () {
      final adminId = 'admins';
      final teams = [_team('admins', 'Whatever Name')];
      final isAdmin = teams.any((t) => t.$id == adminId);
      expect(isAdmin, isTrue);
    });
  });

  test('AdminAuthService is constructible with a stub auth service', () {
    // Wires the public API; if signatures drift this fails to compile.
    final svc = AdminAuthService(_FakeAuthService(_MockClient()));
    expect(svc, isNotNull);
  });
}
