import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/config/appwrite_config.dart';
import 'package:itun/core/offline/mutation_outbox_service.dart';

void main() {
  group('Production Readiness Invariant Smoke Suite', () {
    test('AppwriteConfig exposes non-empty admin configuration', () {
      expect(AppwriteConfig.adminTeamId, isNotEmpty);
    });

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
