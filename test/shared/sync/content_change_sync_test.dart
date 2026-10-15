import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';

import 'package:itun/core/api/content_change_feed.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/core/network/network_info.dart';
import 'package:itun/core/storage/cache_service.dart';
import 'package:itun/features/auth/presentation/providers/auth_providers.dart';
import 'package:itun/features/categories/domain/repositories/category_repository.dart';
import 'package:itun/features/categories/presentation/providers/category_providers.dart';
import 'package:itun/features/lessons/data/di/lesson_di.dart';
import 'package:itun/features/lessons/domain/repositories/lesson_repository.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/shared/repositories/content_repository.dart';
import 'package:itun/shared/sync/content_change_sync.dart';

class _MockContentRepository extends Mock implements ContentRepository {}

class _MockLessonRepository extends Mock implements LessonRepository {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockNetworkInfo extends Mock implements NetworkInfo {}

/// Scripted change feed: answers each fetch from [handler].
class _FakeSource implements ContentChangeSource {
  _FakeSource(this.handler);

  Future<ContentChangePage> Function(int since) handler;
  final calls = <int>[];

  @override
  Future<ContentChangePage> fetch(int since) {
    calls.add(since);
    return handler(since);
  }
}

class _MemoryCursor implements ContentChangeCursorStore {
  _MemoryCursor([this.value]);

  int? value;

  @override
  Future<int?> read() async => value;

  @override
  Future<void> write(int seq) async => value = seq;
}

ContentChange _change(int seq, String table, String rowId) =>
    ContentChange(seq: seq, table: table, rowId: rowId, op: 'update');

ContentChangePage _page(List<ContentChange> changes, int latest) =>
    ContentChangePage(changes: changes, latest: latest);

final _refProvider = Provider<Ref>((ref) => ref);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late _MockNetworkInfo networkInfo;
  late StreamController<List<ConnectivityResult>> connectivity;
  late ProviderContainer container;
  late Ref testRef;

  setUpAll(() async {
    registerFallbackValue(ContentKind.word);
    tempDir = await Directory.systemTemp.createTemp('content_change_sync_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  setUp(() {
    CacheService.resetForTesting();
    networkInfo = _MockNetworkInfo();
    connectivity = StreamController<List<ConnectivityResult>>.broadcast();
    when(
      () => networkInfo.onConnectivityChanged,
    ).thenAnswer((_) => connectivity.stream);
    when(() => networkInfo.isConnected).thenAnswer((_) async => true);

    final contentRepository = _MockContentRepository();
    final lessonRepository = _MockLessonRepository();
    final categoryRepository = _MockCategoryRepository();
    when(
      () => contentRepository.cachedList(
        any(),
        categoryId: any(named: 'categoryId'),
      ),
    ).thenAnswer((_) async => const Right([]));
    when(
      () => contentRepository.list(any(), categoryId: any(named: 'categoryId')),
    ).thenAnswer((_) async => const Right([]));
    when(
      () => lessonRepository.getLessonById(any()),
    ).thenAnswer((_) async => const Left(CacheFailure(message: 'none')));
    when(
      categoryRepository.getCategories,
    ).thenAnswer((_) async => const Right([]));

    container = ProviderContainer(
      overrides: [
        isAuthenticatedProvider.overrideWith((ref) async => false),
        currentUserProvider.overrideWith((ref) async => null),
        contentRepositoryProvider.overrideWithValue(contentRepository),
        lessonRepositoryProvider.overrideWithValue(lessonRepository),
        categoryRepositoryProvider.overrideWithValue(categoryRepository),
      ],
    );
    testRef = container.read(_refProvider);
  });

  tearDown(() async {
    container.dispose();
    CacheService.resetForTesting();
    await connectivity.close();
  });

  ContentChangeSync build(
    _FakeSource source,
    _MemoryCursor cursor, {
    Duration pollInterval = const Duration(minutes: 5),
    void Function(ContentKind, String?, String?)? onInvalidated,
    void Function()? onSyncAll,
  }) => ContentChangeSync(
    ref: testRef,
    networkInfo: networkInfo,
    source: source,
    cursorStore: cursor,
    pollInterval: pollInterval,
    onInvalidated: onInvalidated,
    onSyncAll: onSyncAll,
  );

  test('first run only records the latest sequence', () async {
    final source = _FakeSource(
      (_) async => _page([_change(5, 'words', 'w')], 9),
    );
    final cursor = _MemoryCursor();
    var invalidations = 0;
    final sync = build(
      source,
      cursor,
      onInvalidated: (_, _, _) => invalidations++,
    );

    await sync.poll();

    expect(source.calls, [0]);
    expect(cursor.value, 9);
    expect(invalidations, 0);
    sync.dispose();
  });

  test('a word change evicts its caches and invalidates providers', () async {
    await CacheService.set('content_list_word_all', [
      {'id': 'w_1'},
    ]);
    await CacheService.set('content_list_word_cat_vocab', [
      {'id': 'w_1'},
    ]);
    await CacheService.set('content_item_word_w_1', {'id': 'w_1'});
    await CacheService.set('content_item_word_w_2', {'id': 'w_2'});

    final source = _FakeSource(
      (since) async => _page(since == 3 ? [_change(4, 'words', 'w_1')] : [], 4),
    );
    final cursor = _MemoryCursor(3);
    final invalidated = <(ContentKind, String?)>[];
    final sync = build(
      source,
      cursor,
      onInvalidated: (kind, id, _) => invalidated.add((kind, id)),
    );

    await sync.poll();

    expect(source.calls, [3]);
    expect(cursor.value, 4);
    expect(invalidated, [(ContentKind.word, 'w_1')]);
    Future<Object?> cached(String key) =>
        CacheService.get<dynamic>(key, (d) => d);
    expect(await cached('content_list_word_all'), isNull);
    expect(await cached('content_list_word_cat_vocab'), isNull);
    expect(await cached('content_item_word_w_1'), isNull);
    expect(await cached('content_item_word_w_2'), isNotNull);
    sync.dispose();
  });

  test('bulk lesson change (restore) refreshes every lesson', () async {
    await CacheService.set('content_item_lesson_l1', {'id': 'l1'});
    await CacheService.set('content_admin_item_lesson_l1', {'id': 'l1'});
    final source = _FakeSource(
      (_) async => _page([_change(8, 'lessons', '*')], 8),
    );
    final invalidated = <(ContentKind, String?)>[];
    final sync = build(
      source,
      _MemoryCursor(7),
      onInvalidated: (kind, id, _) => invalidated.add((kind, id)),
    );

    await sync.poll();

    expect(invalidated, [(ContentKind.lesson, null)]);
    expect(
      await CacheService.get<dynamic>('content_item_lesson_l1', (d) => d),
      isNull,
    );
    expect(
      await CacheService.get<dynamic>('content_admin_item_lesson_l1', (d) => d),
      isNull,
    );
    sync.dispose();
  });

  test('category change evicts the cached category list', () async {
    await CacheService.set('cached_categories', [
      {'id': 'cat_vocab'},
    ]);
    final source = _FakeSource(
      (_) async => _page([_change(2, 'categories', 'cat_vocab')], 2),
    );
    final sync = build(source, _MemoryCursor(1));

    await sync.poll();

    expect(
      await CacheService.get<dynamic>('cached_categories', (d) => d),
      isNull,
    );
    sync.dispose();
  });

  test('changes to untracked tables are ignored', () async {
    final source = _FakeSource(
      (_) async => _page([_change(2, 'banners', 'b1')], 2),
    );
    final cursor = _MemoryCursor(1);
    var invalidations = 0;
    final sync = build(
      source,
      cursor,
      onInvalidated: (_, _, _) => invalidations++,
    );

    await sync.poll();

    expect(invalidations, 0);
    expect(cursor.value, 2);
    sync.dispose();
  });

  test('pages through the feed until it reaches latest', () async {
    final source = _FakeSource(
      (since) async => switch (since) {
        10 => _page([_change(11, 'words', 'a'), _change(12, 'words', 'b')], 14),
        12 => _page([_change(14, 'numbers', 'n1')], 14),
        _ => _page([], 14),
      },
    );
    final cursor = _MemoryCursor(10);
    final invalidated = <(ContentKind, String?)>[];
    final sync = build(
      source,
      cursor,
      onInvalidated: (kind, id, _) => invalidated.add((kind, id)),
    );

    await sync.poll();

    expect(source.calls, [10, 12]);
    expect(cursor.value, 14);
    expect(invalidated, [
      (ContentKind.word, 'a'),
      (ContentKind.word, 'b'),
      (ContentKind.number, 'n1'),
    ]);
    sync.dispose();
  });

  test(
    'a reset feed (latest behind our cursor) triggers a full refresh',
    () async {
      final source = _FakeSource((_) async => _page([], 3));
      final cursor = _MemoryCursor(50);
      var syncAll = 0;
      final sync = build(source, cursor, onSyncAll: () => syncAll++);

      await sync.poll();

      expect(syncAll, 1);
      expect(cursor.value, 3);
      sync.dispose();
    },
  );

  test('failures back off exponentially and recover', () async {
    var fail = true;
    final source = _FakeSource((_) async {
      if (fail) throw StateError('offline');
      return _page([], 1);
    });
    final cursor = _MemoryCursor(1);
    final sync = build(
      source,
      cursor,
      pollInterval: const Duration(seconds: 60),
    );

    expect(sync.nextDelay, const Duration(seconds: 60));
    await sync.poll();
    expect(sync.nextDelay, const Duration(seconds: 120));
    await sync.poll();
    expect(sync.nextDelay, const Duration(seconds: 240));
    for (var i = 0; i < 10; i++) {
      await sync.poll();
    }
    expect(sync.nextDelay, const Duration(minutes: 15));
    expect(cursor.value, 1);

    fail = false;
    await sync.poll();
    expect(sync.nextDelay, const Duration(seconds: 60));
    sync.dispose();
  });

  test('polls on start, periodically while active, and on resume', () async {
    final source = _FakeSource((_) async => _page([], 1));
    final sync = build(
      source,
      _MemoryCursor(1),
      pollInterval: const Duration(milliseconds: 30),
    );

    sync.initialize();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final whileActive = source.calls.length;
    expect(whileActive, greaterThanOrEqualTo(2));

    sync.didChangeAppLifecycleState(AppLifecycleState.paused);
    await pumpEventQueue();
    final atPause = source.calls.length;
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(source.calls.length, atPause, reason: 'no polling in background');

    sync.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpEventQueue();
    expect(source.calls.length, atPause + 1);
    sync.dispose();
  });

  test('regaining connectivity polls immediately', () async {
    final source = _FakeSource((_) async => _page([], 1));
    final sync = build(source, _MemoryCursor(1));
    sync.initialize();
    await pumpEventQueue();
    final before = source.calls.length;

    connectivity.add([ConnectivityResult.wifi]);
    await pumpEventQueue();

    expect(source.calls.length, before + 1);
    sync.dispose();
  });

  test('EdgeContentChangeSource reads the Worker change feed', () async {
    late Uri requested;
    final source = EdgeContentChangeSource(
      MockClient((request) async {
        requested = request.url;
        return http.Response(
          jsonEncode({
            'ok': true,
            'changes': [
              {
                'seq': 7,
                'table_name': 'words',
                'row_id': 'w1',
                'op': 'update',
                'changed_at': '2026-10-15T00:00:00Z',
              },
              {'seq': 'bad'},
            ],
            'latest': 7,
          }),
          200,
        );
      }),
    );

    final page = await source.fetch(6);

    expect(requested.path, '/api/v1/content/changes');
    expect(requested.queryParameters['since'], '6');
    expect(page.latest, 7);
    expect(page.changes.single.table, 'words');
    expect(page.changes.single.rowId, 'w1');
  });

  test('parses the field names the Worker actually emits', () async {
    // routes/admin_content.ts serializes {seq, table, id, op, changedAt}.
    final source = EdgeContentChangeSource(
      MockClient(
        (_) async => http.Response(
          jsonEncode({
            'ok': true,
            'changes': [
              {
                'seq': 3,
                'table': 'letters',
                'id': 'l1',
                'op': 'upsert',
                'changedAt': '2026-10-15T00:00:00Z',
              },
              {'seq': 4, 'table': 'lessons', 'id': '*', 'op': 'restore'},
            ],
            'latest': 4,
            'hasMore': false,
          }),
          200,
        ),
      ),
    );

    final page = await source.fetch(2);

    expect(page.changes.map((c) => c.table), ['letters', 'lessons']);
    expect(page.changes.first.rowId, 'l1');
    expect(page.changes.last.isBulk, isTrue);
  });
}
