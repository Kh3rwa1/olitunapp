import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:itun/core/offline/mutation_outbox_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const boxName = 'durable_mutation_outbox';
  late Directory directory;
  late MutationOutboxService outbox;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('olitun_outbox_test_');
    Hive.init(directory.path);
    MutationOutboxService.resetForTesting();
    outbox = MutationOutboxService();
  });

  tearDown(() async {
    await Hive.close();
    MutationOutboxService.resetForTesting();
    await directory.delete(recursive: true);
  });

  PendingMutation mutation(String userId, String operationId) {
    return PendingMutation(
      operationId: operationId,
      userId: userId,
      operationType: 'lesson_completed',
      entityId: 'lesson-1',
      payload: {'stars': 5},
      createdAt: DateTime.utc(2026, 9, 5),
    );
  }

  test('queued work survives storage restart', () async {
    await outbox.enqueueMutation(mutation('learner', 'completion-1'));
    await Hive.close();
    Hive.init(directory.path);
    // Intentionally keep the static references: an externally closed box
    // must reopen, not return the completed Future for the now-closed box.
    final restarted = MutationOutboxService();
    final pending = await restarted.getPendingMutations('learner');
    expect(pending.map((item) => item.operationId), ['completion-1']);
    expect(pending.single.payload, {'stars': 5});
  });

  test('failed storage open can be retried', () async {
    final incompatible = await Hive.openBox<int>(boxName);
    await expectLater(
      outbox.getPendingMutations('learner'),
      throwsA(isA<HiveError>()),
    );
    await incompatible.close();
    expect(await outbox.getPendingMutations('learner'), isEmpty);
  });

  test('queue reads enforce exact ownership', () async {
    await outbox.enqueueMutation(mutation('learner', 'mine'));
    await outbox.enqueueMutation(mutation('learner_child', 'theirs'));
    final pending = await outbox.getPendingMutations('learner');
    expect(pending.map((item) => item.operationId), ['mine']);
    expect(pending.every((item) => item.userId == 'learner'), isTrue);
  });

  test('queue clearing enforces exact ownership', () async {
    await outbox.enqueueMutation(mutation('learner', 'mine'));
    await outbox.enqueueMutation(mutation('learner_child', 'theirs'));
    await outbox.clearQueueForUser('learner');
    expect(await outbox.getPendingMutations('learner'), isEmpty);
    final other = await outbox.getPendingMutations('learner_child');
    expect(other.map((item) => item.operationId), ['theirs']);
  });

  test('completion only removes the acknowledged operation', () async {
    await outbox.enqueueMutation(mutation('learner', 'done'));
    await outbox.enqueueMutation(mutation('learner', 'still-pending'));
    await outbox.markCompleted('learner', 'done');
    await Hive.close();
    final pending = await outbox.getPendingMutations('learner');
    expect(pending.map((item) => item.operationId), ['still-pending']);
  });

  test('dead-letter state survives restart', () async {
    await outbox.enqueueMutation(mutation('learner', 'retry-me'));
    for (var i = 0; i < MutationOutboxService.maxRetryAttempts; i++) {
      await outbox.recordAttemptFailed('learner', 'retry-me', 'offline');
    }
    await Hive.close();
    final pending = await outbox.getPendingMutations('learner');
    expect(pending.single.status, MutationStatus.deadLetter);
    expect(pending.single.attemptCount, MutationOutboxService.maxRetryAttempts);
    expect(pending.single.lastError, 'offline');
  });
}
