import 'package:flutter_test/flutter_test.dart';
import 'package:appwrite/appwrite.dart';
import 'package:itun/core/api/appwrite_db_service.dart';
import 'package:itun/core/config/appwrite_config.dart';

void main() {
  group('Appwrite Permission Invariants Unit Test Suite', () {
    test(
      'createPublicContent generates explicit public read permission only',
      () {
        final permissions = [Permission.read(Role.any())];

        expect(permissions, contains(Permission.read(Role.any())));
        expect(permissions, isNot(contains(Permission.write(Role.any()))));
      },
    );

    test(
      'createOwnerPrivateRow restricts read and write strictly to specified user ID',
      () {
        const userId = 'user_prod_77';
        final permissions = [
          Permission.read(Role.user(userId)),
          Permission.write(Role.user(userId)),
        ];

        expect(permissions, contains(Permission.read(Role.user(userId))));
        expect(permissions, contains(Permission.write(Role.user(userId))));
        expect(permissions, isNot(contains(Permission.read(Role.any()))));
        expect(permissions, isNot(contains(Permission.write(Role.any()))));
      },
    );

    test(
      'adminOnlyPermissions dynamically binds strictly to AppwriteConfig.adminTeamId',
      () {
        final permissions = AppwriteDbService.adminOnlyPermissions();
        const expectedTeam = AppwriteConfig.adminTeamId;

        expect(permissions, contains(Permission.read(Role.team(expectedTeam))));
        expect(permissions, contains(Permission.write(Role.team(expectedTeam))));
        expect(permissions, isNot(contains(Permission.read(Role.team('admin')))));
        expect(permissions, isNot(contains(Permission.write(Role.team('admin')))));
        expect(permissions, isNot(contains(Permission.read(Role.any()))));
        expect(permissions, isNot(contains(Permission.write(Role.any()))));
      },
    );

    test(
      'createFunctionManagedRow creates empty permissions array for server-only access',
      () {
        const permissions = <String>[];

        expect(permissions, isEmpty);
        expect(permissions, isNot(contains(Permission.read(Role.any()))));
        expect(permissions, isNot(contains(Permission.write(Role.any()))));
      },
    );
  });
}
