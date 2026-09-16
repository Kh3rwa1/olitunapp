import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:itun/core/offline/mutation_outbox_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<MutationOutboxService> openService() async {
    final service = MutationOutboxService();
    await service.initialize();
    return service;
  }

  setUp(() async {
    await Hive.deleteBoxFromDisk('mutation_outbox_v1');
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk('mutation_outbox_v1');
  });

  test('mutation survives close and reopen', () async {
    final first = await openService();
    await first.enqueueMutation(
      PendingMutation(
        operationId: 'restart-safe-op',
        userId: 'user-a',
        operationType: 'review.upsert',
        entityId: 'lesson-1',
        payload: const {'score': 0.8},
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await Hive.box<String>('mutation_outbox_v1').close();
    await first.dispose();

    final second = await openService();
    final restored = await second.getPendingMutations('user-a');

    expect(restored, hasLength(1));
    expect(restored.single.operationId, 'restart-safe-op');
    expect(restored.single.payload['score'], 0.8);
    await Hive.box<String>('mutation_outbox_v1').close();
    await second.dispose();
  });

  test('similar user identifiers do not share mutations', () async {
    final service = await openService();
    for (final userId in ['user', 'user-extra']) {
      await service.enqueueMutation(
        PendingMutation(
          operationId: 'op-$userId',
          userId: userId,
          operationType: 'review.delete',
          entityId: 'item',
          payload: const {},
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
    }

    final shortUser = await service.getPendingMutations('user');
    final longUser = await service.getPendingMutations('user-extra');

    expect(shortUser.map((item) => item.userId), ['user']);
    expect(longUser.map((item) => item.userId), ['user-extra']);
    await Hive.box<String>('mutation_outbox_v1').close();
    await service.dispose();
  });

  test(
    'transient failures keep retrying beyond the former threshold',
    () async {
      final service = await openService();
      await service.enqueueMutation(
        PendingMutation(
          operationId: 'retry-op',
          userId: 'user-a',
          operationType: 'review.upsert',
          entityId: 'item',
          payload: const {},
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );

      for (var attempt = 0; attempt < 8; attempt++) {
        await service.recordAttemptFailed(
          userId: 'user-a',
          operationId: 'retry-op',
          error: StateError('temporary outage'),
          now: DateTime.utc(2026, 1, 1, 0, attempt),
        );
      }

      final failed = (await service.getPendingMutations('user-a')).single;
      expect(failed.status, MutationStatus.failed);
      expect(failed.attemptCount, 8);
      expect(failed.nextRetryAt, isNotNull);

      await Hive.box<String>('mutation_outbox_v1').close();
      await service.dispose();
      final reopened = await openService();
      final restored = (await reopened.getPendingMutations('user-a')).single;
      expect(restored.status, MutationStatus.failed);
      expect(restored.attemptCount, 8);
      await Hive.box<String>('mutation_outbox_v1').close();
      await reopened.dispose();
    },
  );

  test('permanent failures can be explicitly requeued', () async {
    final service = await openService();
    await service.enqueueMutation(
      PendingMutation(
        operationId: 'permanent-op',
        userId: 'user-a',
        operationType: 'review.upsert',
        entityId: 'item',
        payload: const {},
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );

    await service.recordAttemptFailed(
      userId: 'user-a',
      operationId: 'permanent-op',
      error: const FormatException('invalid payload'),
      isPermanent: true,
      now: DateTime.utc(2026, 1, 1, 0, 1),
    );

    var mutation = (await service.getPendingMutations('user-a')).single;
    expect(mutation.status, MutationStatus.deadLetter);
    expect(mutation.lastError, contains('invalid payload'));

    await service.retryDeadLetter(
      userId: 'user-a',
      operationId: 'permanent-op',
    );
    mutation = (await service.getPendingMutations('user-a')).single;
    expect(mutation.status, MutationStatus.pending);
    expect(mutation.attemptCount, 0);
    expect(mutation.lastError, isNull);
    expect(mutation.nextRetryAt, isNull);

    await Hive.box<String>('mutation_outbox_v1').close();
    await service.dispose();
  });

  test('sensitive details are redacted before persistence', () async {
    final service = await openService();
    await service.enqueueMutation(
      PendingMutation(
        operationId: 'redaction-op',
        userId: 'user-a',
        operationType: 'review.upsert',
        entityId: 'item',
        payload: const {},
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );

    await service.recordAttemptFailed(
      userId: 'user-a',
      operationId: 'redaction-op',
      error: StateError(
        'email=person@example.com token=top-secret password=hunter2',
      ),
      now: DateTime.utc(2026, 1, 1, 0, 1),
    );

    final failed = (await service.getPendingMutations('user-a')).single;
    expect(failed.lastError, isNot(contains('person@example.com')));
    expect(failed.lastError, isNot(contains('top-secret')));
    expect(failed.lastError, isNot(contains('hunter2')));
    expect(failed.lastError, contains('[redacted-email]'));
    expect(failed.lastError, contains('[redacted]'));
    await Hive.box<String>('mutation_outbox_v1').close();
    await service.dispose();
  });
}
