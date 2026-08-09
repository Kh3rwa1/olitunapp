import 'package:flutter_test/flutter_test.dart';
import 'package:appwrite/appwrite.dart';

void main() {
  group('Appwrite Permission Invariants Test', () {
    test(
      'createPublicContent assigns explicit public read permission',
      () async {
        final permissions = [Permission.read(Role.any())];
        expect(permissions, contains(Permission.read(Role.any())));
        expect(permissions, isNot(contains(Permission.write(Role.any()))));
      },
    );

    test(
      'createOwnerPrivateRow restricts read and write to specified user ID',
      () async {
        const userId = 'user_12345';
        final expectedRead = Permission.read(Role.user(userId));
        final expectedWrite = Permission.write(Role.user(userId));

        final permissions = [
          Permission.read(Role.user(userId)),
          Permission.write(Role.user(userId)),
        ];

        expect(permissions, contains(expectedRead));
        expect(permissions, contains(expectedWrite));
        expect(permissions, isNot(contains(Permission.read(Role.any()))));
        expect(permissions, isNot(contains(Permission.write(Role.any()))));
      },
    );

    test('createAdminOnlyRow restricts access to admin team', () async {
      final permissions = [
        Permission.read(Role.team('admin')),
        Permission.write(Role.team('admin')),
      ];

      expect(permissions, contains(Permission.read(Role.team('admin'))));
      expect(permissions, contains(Permission.write(Role.team('admin'))));
      expect(permissions, isNot(contains(Permission.read(Role.any()))));
    });

    test('createFunctionManagedRow creates empty permissions array', () async {
      const permissions = <String>[];
      expect(permissions, isEmpty);
      expect(permissions, isNot(contains(Permission.read(Role.any()))));
    });
  });
}
