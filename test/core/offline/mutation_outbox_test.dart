import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/offline/mutation_outbox_service.dart';

void main() {
  group('PendingMutation Model Tests', () {
    test('serializes and deserializes cleanly with default status', () {
      final mutation = PendingMutation(
        operationId: 'op_1001',
        userId: 'user_42',
        operationType: 'save_progress',
        entityId: 'lesson_block_9',
        payload: {'score': 95, 'completed': true},
        createdAt: DateTime.parse('2026-08-09T08:00:00Z'),
      );

      final json = mutation.toJson();
      expect(json['operationId'], 'op_1001');
      expect(json['userId'], 'user_42');
      expect(json['status'], 'pending');

      final reconstructed = PendingMutation.fromJson(json);
      expect(reconstructed.operationId, mutation.operationId);
      expect(reconstructed.userId, mutation.userId);
      expect(reconstructed.operationType, mutation.operationType);
      expect(reconstructed.entityId, mutation.entityId);
      expect(reconstructed.payload['score'], 95);
      expect(reconstructed.status, MutationStatus.pending);
    });

    test('supports deadLetter status transition', () {
      final mutation = PendingMutation(
        operationId: 'op_1002',
        userId: 'user_42',
        operationType: 'record_mistake',
        entityId: 'mistake_12',
        payload: {'mistake': 'incorrect_char'},
        createdAt: DateTime.now(),
        attemptCount: 5,
        status: MutationStatus.deadLetter,
        lastError: 'Server error 500',
      );

      final json = mutation.toJson();
      expect(json['status'], 'deadLetter');
      expect(json['attemptCount'], 5);

      final reconstructed = PendingMutation.fromJson(json);
      expect(reconstructed.status, MutationStatus.deadLetter);
      expect(reconstructed.lastError, 'Server error 500');
    });
  });
}
