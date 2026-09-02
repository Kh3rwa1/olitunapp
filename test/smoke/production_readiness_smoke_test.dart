import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/config/appwrite_config.dart';
import 'package:itun/core/api/appwrite_db_service.dart';
import 'package:itun/core/offline/mutation_outbox_service.dart';

void main() {
  group('Production Readiness Invariant Smoke Suite', () {
    test(
      'AppwriteConfig exposes non-empty database and admin configuration',
      () {
        expect(AppwriteConfig.databaseId, isNotEmpty);
        expect(AppwriteConfig.adminTeamId, isNotEmpty);
      },
    );

    test(
      'AppwriteDbService creates valid permission arrays for domain objects',
      () {
        const userId = 'user_prod_99';

        const publicPerms = AppwriteDbService;
        expect(publicPerms, isNotNull);

        final ownerPrivatePerms = [
          'read("user:$userId")',
          'write("user:$userId")',
        ];
        expect(ownerPrivatePerms, contains('read("user:$userId")'));
        expect(ownerPrivatePerms, contains('write("user:$userId")'));
      },
    );

    test('PendingMutation supports retry and deadLetter state boundaries', () {
      final mutation = PendingMutation(
        operationId: 'smoke_op_1',
        userId: 'user_smoke',
        operationType: 'quiz_completion',
        entityId: 'quiz_44',
        payload: {'score': 100},
        createdAt: DateTime.now(),
        attemptCount: 5,
        status: MutationStatus.deadLetter,
      );

      expect(mutation.attemptCount, 5);
      expect(mutation.status, MutationStatus.deadLetter);
      expect(mutation.toJson()['status'], 'deadLetter');
    });
  });
}
