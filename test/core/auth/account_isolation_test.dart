import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:itun/core/offline/mutation_outbox_service.dart';
import 'package:itun/core/storage/cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync('hive_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    CacheService.resetForTesting();
  });

  group('Account Isolation & Cache Key Isolation Tests', () {
    final outbox = MutationOutboxService();

    test('Pending mutations are strictly isolated per userId', () async {
      const userA = 'user_A_123';
      const userB = 'user_B_456';

      final mutationA = PendingMutation(
        operationId: 'op_1',
        userId: userA,
        operationType: 'record_progress',
        entityId: 'lesson_1',
        payload: {'score': 100},
        createdAt: DateTime.now(),
      );

      await outbox.enqueueMutation(mutationA);

      final listA = await outbox.getPendingMutations(userA);
      final listB = await outbox.getPendingMutations(userB);

      expect(listA.length, equals(1));
      expect(listA.first.userId, equals(userA));
      expect(listB, isEmpty);

      // Cleanup
      await outbox.clearQueueForUser(userA);
    });

    test('Clearing user queue removes only targeted user outbox data', () async {
      const userA = 'user_A_789';
      const userB = 'user_B_789';

      await outbox.enqueueMutation(
        PendingMutation(
          operationId: 'op_a',
          userId: userA,
          operationType: 'quiz',
          entityId: 'q1',
          payload: {},
          createdAt: DateTime.now(),
        ),
      );

      await outbox.enqueueMutation(
        PendingMutation(
          operationId: 'op_b',
          userId: userB,
          operationType: 'quiz',
          entityId: 'q2',
          payload: {},
          createdAt: DateTime.now(),
        ),
      );

      await outbox.clearQueueForUser(userA);

      final listA = await outbox.getPendingMutations(userA);
      final listB = await outbox.getPendingMutations(userB);

      expect(listA, isEmpty);
      expect(listB.length, equals(1));

      // Cleanup
      await outbox.clearQueueForUser(userB);
    });
  });
}
