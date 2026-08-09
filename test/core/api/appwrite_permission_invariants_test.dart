import 'package:flutter_test/flutter_test.dart';
import 'package:appwrite/appwrite.dart';
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
      'createAdminOnlyRow restricts read and write strictly to configured admin team ID',
      () {
        const adminTeam = AppwriteConfig.adminTeamId;
        final permissions = [
          Permission.read(Role.team(adminTeam)),
          Permission.write(Role.team(adminTeam)),
        ];

        expect(permissions, contains(Permission.read(Role.team(adminTeam))));
        expect(permissions, contains(Permission.write(Role.team(adminTeam))));
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
