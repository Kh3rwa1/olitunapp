from pathlib import Path
p=Path('scripts/apply_priority_hardening.py')
s=p.read_text()
s=s.replace("edit(p, '          await _saveConsentStatus(status);', '          await canRequestAds();\\n          await _saveConsentStatus(status);')\n", '')
s=s.replace("edit(p, '  Future<void>.microtask(safeReplay);', '''  Future<void>.microtask(safeReplay);", "edit(p, '\\n  Future<void>.microtask(safeReplay);\\n', '''\n  Future<void>.microtask(safeReplay);")
s=s.replace("if (!await _ref.read(adServiceProvider).consentManager.canRequestAds()) {{", "if (!await _ref.read(adServiceProvider).consentManager.canRequestAds() ||\n        !_ref.read(adStateProvider).shouldShowAds || {field} == null) {{")
s += r'''
# Follow-up edge cases and regression coverage.
p = 'lib/core/ads/consent_manager.dart'
edit(p, '      } catch (e) {\n        completer.complete(', '      } catch (e) {\n        adsAllowed.value = false;\n        completer.complete(')
p = 'lib/shared/repositories/content_repository.dart'
edit(p, '${DateTime.now().millisecondsSinceEpoch}', '${ID.unique()}')
p = 'lib/shared/offline/content_mutation_replay.dart'
edit(p, '    var skipped = 0;', '    var skipped = 0;\n    final blockedEntities = <String>{};')
edit(p, '      if (mutation.status == MutationStatus.deadLetter ||\n          mutation.nextRetryAt.isAfter(DateTime.now())) {', ''' + "'''" + r'''      final entityKey = '${mutation.payload['kind']}:${mutation.entityId}';
      if (mutation.status == MutationStatus.deadLetter) {
        skipped++;
        continue;
      }
      if (blockedEntities.contains(entityKey) || mutation.nextRetryAt.isAfter(DateTime.now())) {
        blockedEntities.add(entityKey);''' + "'''" + r''')
edit(p, '          (failure) async {\n            failed++;', '          (failure) async {\n            blockedEntities.add(entityKey);\n            failed++;')
edit(p, '      } catch (e) {\n        failed++;', '      } catch (e) {\n        blockedEntities.add(entityKey);\n        failed++;')
# Do not recreate a timer or start another pass after provider disposal.
edit(p, '  Future<void> safeReplay() async {\n    try {', '  var disposed = false;\n  ref.onDispose(() => disposed = true);\n  Future<void> safeReplay() async {\n    if (disposed) return;\n    try {')
# Include resource guard tests in the already-enforced root backend suite.
write('functions/test/translation_resource_budget.test.js', "import '../translator/test/resource_budget.test.js';\n")
# No runtime SDK secret fallback broader than the declared function scopes.
p = 'functions/translator/src/main.js'
edit(p, '  const apiKey = process.env.APPWRITE_API_KEY;', '  const apiKey = process.env.APPWRITE_FUNCTION_API_KEY || process.env.APPWRITE_API_KEY;')

p = 'test/shared/offline/content_mutation_replay_test.dart'
edit(p, "import 'dart:io';", "import 'dart:io';\nimport 'dart:async';\nimport 'package:appwrite/appwrite.dart';\nimport 'package:itun/core/storage/cache_service.dart';")
edit(p, 'void main() {', ''' + "'''" + r'''class FailingOutbox extends MutationOutboxService {
  @override
  Future<void> enqueueMutation(PendingMutation mutation) async => throw StateError('disk full');
}

void main() {''' + "'''" + r''')
edit(p, "  group('ContentMutationReplay', () {", ''' + "'''" + r'''  test('offline save fails when its durable queue is absent or unwritable', () async {
    for (final outbox in <MutationOutboxService?>[null, FailingOutbox()]) {
      final repository = ContentRepository(databases: Databases(Client()),
        networkInfo: FakeNetworkInfo(connected: false), mutationOutbox: outbox);
      final result = await repository.upsert(buildItem());
      expect(result.isLeft(), isTrue);
    }
  });

  test('replay cannot acknowledge an offline re-enqueue as a server success', () async {
    final repository = ContentRepository(databases: Databases(Client()),
      networkInfo: FakeNetworkInfo(connected: false), mutationOutbox: MutationOutboxService());
    final result = await repository.upsert(buildItem(), allowOfflineQueue: false);
    expect(result.isLeft(), isTrue);
    expect(await MutationOutboxService().getPendingMutations(contentMutationQueueUserId), isEmpty);
  });

  test('durable edit survives Hive close and reopen before replay', () async {
    final outbox = MutationOutboxService();
    final repository = ContentRepository(databases: Databases(Client()),
      networkInfo: FakeNetworkInfo(connected: false), mutationOutbox: outbox);
    expect((await repository.upsert(buildItem())).isRight(), isTrue);
    await Hive.close();
    MutationOutboxService.resetForTesting();
    CacheService.resetForTesting();
    final reopened = MutationOutboxService();
    expect(await reopened.getPendingMutations(contentMutationQueueUserId), hasLength(1));
    var calls = 0;
    final replay = ContentMutationReplay(outbox: reopened,
      networkInfo: FakeNetworkInfo(connected: true),
      executeUpsert: (item) async { calls++; return right(item); });
    expect((await replay.replayPending()).replayed, 1);
    expect(calls, 1);
    expect(await reopened.getPendingMutations(contentMutationQueueUserId), isEmpty);
  });

  test('simultaneous replay triggers share one execution and await persistence', () async {
    final outbox = MutationOutboxService();
    final item = buildItem();
    await outbox.enqueueMutation(PendingMutation(operationId: 'single_flight',
      userId: contentMutationQueueUserId, operationType: 'content.upsert', entityId: item.id,
      payload: {'kind': item.kind.name, 'item': item.toJson()}, createdAt: DateTime.now()));
    final entered = Completer<void>();
    final release = Completer<void>();
    var calls = 0;
    final replay = ContentMutationReplay(outbox: outbox, networkInfo: FakeNetworkInfo(connected: true),
      executeUpsert: (item) async { calls++; entered.complete(); await release.future; return right(item); });
    final first = replay.replayPending();
    await entered.future.timeout(const Duration(seconds: 5));
    final second = replay.replayPending();
    expect(identical(first, second), isTrue);
    release.complete();
    await Future.wait([first, second]);
    expect(calls, 1);
    expect(await outbox.getPendingMutations(contentMutationQueueUserId), isEmpty);
  });

  test('a deferred older edit blocks newer edits of the same entity', () async {
    final outbox = MutationOutboxService();
    final item = buildItem();
    for (var i = 0; i < 2; i++) {
      await outbox.enqueueMutation(PendingMutation(operationId: 'ordered_$i',
        userId: contentMutationQueueUserId, operationType: 'content.upsert', entityId: item.id,
        payload: {'kind': item.kind.name, 'item': item.toJson()},
        createdAt: DateTime.now().add(Duration(milliseconds: i)),
        nextRetryAt: i == 0 ? DateTime.now().add(const Duration(hours: 1)) : DateTime.now()));
    }
    final replay = ContentMutationReplay(outbox: outbox, networkInfo: FakeNetworkInfo(connected: true),
      executeUpsert: (_) => throw StateError('must wait for the older edit'));
    final result = await replay.replayPending();
    expect(result.skipped, 2);
    expect(result.replayed, 0);
    expect(await outbox.getPendingMutations(contentMutationQueueUserId), hasLength(2));
  });

  group('ContentMutationReplay', () {''' + "'''" + r''')

p = 'test/core/payments/purchase_repository_entitlements_test.dart'
edit(p, "import 'package:flutter/services.dart';", "import 'package:flutter/services.dart';\nimport 'dart:async';\nimport 'package:appwrite/appwrite.dart';")
edit(p, "  group('PurchaseRepository - Entitlements & User-Scoped Cache', () {", ''' + "'''" + r'''  test('background refund refresh publishes a revision and removes the entitlement', () async {
    const userId = 'reactive_refund';
    await CacheService.set('entitlements:production:$userId', {'ids': ['refunded']});
    when(() => mockDb.listDocuments('course_purchases', queries: any(named: 'queries'))).thenAnswer((_) async => []);
    final container = createContainer();
    addTearDown(container.dispose);
    final changed = Completer<void>();
    container.listen(entitlementRevisionProvider(userId), (_, next) {
      if (next > 0 && !changed.isCompleted) changed.complete();
    });
    final repo = container.read(purchaseRepositoryProvider);
    expect((await repo.fetchEntitlements(userId)).categoryIds, contains('refunded'));
    await changed.future.timeout(const Duration(seconds: 5));
    expect((await repo.fetchEntitlements(userId, skipRevalidate: true)).categoryIds, isEmpty);
  });

  test('permission denial revokes fresh cached access and notifies consumers', () async {
    const userId = 'denied_access';
    await CacheService.set('entitlements:production:$userId', {'ids': ['paid']});
    when(() => mockDb.listDocuments('course_purchases', queries: any(named: 'queries')))
      .thenThrow(AppwriteException('not permitted', 403));
    final container = createContainer();
    addTearDown(container.dispose);
    final changed = Completer<void>();
    container.listen(entitlementRevisionProvider(userId), (_, next) {
      if (next > 0 && !changed.isCompleted) changed.complete();
    });
    final repo = container.read(purchaseRepositoryProvider);
    await repo.fetchEntitlements(userId);
    await changed.future.timeout(const Duration(seconds: 5));
    final result = await repo.fetchEntitlements(userId);
    expect(result.status, EntitlementStatus.permissionDenied);
    expect(result.categoryIds, isEmpty);
    expect(await CacheService.getMeta('entitlements:production:$userId'), isNull);
  });

  test('logout invalidates an in-flight verification before it can repopulate cache', () async {
    const userId = 'logout_race';
    final response = Completer<List<Map<String, dynamic>>>();
    when(() => mockDb.listDocuments('course_purchases', queries: any(named: 'queries'))).thenAnswer((_) => response.future);
    final container = createContainer();
    addTearDown(container.dispose);
    final repo = container.read(purchaseRepositoryProvider);
    final pending = repo.fetchEntitlements(userId);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await repo.clearUserEntitlementCache(userId);
    response.complete([{'categoryId': 'paid', 'status': 'verified'}]);
    expect((await pending).categoryIds, isEmpty);
    expect(await CacheService.getMeta('entitlements:production:$userId'), isNull);
  });

  group('PurchaseRepository - Entitlements & User-Scoped Cache', () {''' + "'''" + r''')
Path('/tmp/priority_changed_paths.json').write_text(json.dumps(sorted(changed)))
'''
p.write_text(s)
