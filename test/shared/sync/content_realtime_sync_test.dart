import 'dart:async';
import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

import 'package:itun/core/error/failures.dart';
import 'package:itun/core/network/network_info.dart';
import 'package:itun/core/storage/cache_service.dart';
import 'package:itun/features/auth/presentation/providers/auth_providers.dart';
import 'package:itun/features/categories/domain/repositories/category_repository.dart';
import 'package:itun/features/categories/presentation/providers/category_providers.dart';
import 'package:itun/features/lessons/data/di/lesson_di.dart';
import 'package:itun/features/lessons/domain/repositories/lesson_repository.dart';
import 'package:itun/core/api/appwrite_db_service.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/shared/repositories/content_repository.dart';
import 'package:itun/shared/sync/content_realtime_sync.dart';

class _MockContentRepository extends Mock implements ContentRepository {}

class _MockLessonRepository extends Mock implements LessonRepository {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockAppwriteDbService extends Mock implements AppwriteDbService {}

class _MockNetworkInfo extends Mock implements NetworkInfo {}

class _FakeRealtime extends Mock implements Realtime {
  final StreamController<RealtimeMessage> controller;
  List<Object>? subscribedChannels;

  _FakeRealtime(this.controller);

  @override
  RealtimeSubscription subscribe(
    List<Object> channels, {
    List<String> queries = const [],
  }) {
    subscribedChannels = channels;
    return RealtimeSubscription(
      close: () async => controller.close(),
      channels: channels.map((c) => c.toString()).toList(),
      queries: queries,
      controller: controller,
    );
  }
}

final _refProvider = Provider<Ref>((ref) => ref);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late StreamController<RealtimeMessage> realtimeController;
  late _FakeRealtime fakeRealtime;
  late _MockNetworkInfo mockNetworkInfo;
  late StreamController<List<ConnectivityResult>> connectivityController;
  late ProviderContainer container;
  late Ref testRef;

  setUpAll(() async {
    registerFallbackValue(ContentKind.word);
    tempDir = await Directory.systemTemp.createTemp(
      'content_realtime_sync_test_',
    );
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  late _MockContentRepository mockContentRepository;
  late _MockLessonRepository mockLessonRepository;
  late _MockCategoryRepository mockCategoryRepository;
  late _MockAppwriteDbService mockAppwriteDbService;

  setUp(() async {
    CacheService.resetForTesting();

    realtimeController = StreamController<RealtimeMessage>.broadcast();
    fakeRealtime = _FakeRealtime(realtimeController);
    mockNetworkInfo = _MockNetworkInfo();
    mockContentRepository = _MockContentRepository();
    mockLessonRepository = _MockLessonRepository();
    mockCategoryRepository = _MockCategoryRepository();
    mockAppwriteDbService = _MockAppwriteDbService();
    connectivityController =
        StreamController<List<ConnectivityResult>>.broadcast();

    when(
      () => mockNetworkInfo.onConnectivityChanged,
    ).thenAnswer((_) => connectivityController.stream);
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

    when(
      () => mockContentRepository.cachedList(
        any(),
        categoryId: any(named: 'categoryId'),
      ),
    ).thenAnswer((_) async => const Right([]));
    when(
      () => mockContentRepository.list(
        any(),
        categoryId: any(named: 'categoryId'),
      ),
    ).thenAnswer((_) async => const Right([]));
    when(
      () => mockLessonRepository.getLessonById(any()),
    ).thenAnswer((_) async => const Left(CacheFailure(message: 'none')));
    when(
      () => mockCategoryRepository.getCategories(),
    ).thenAnswer((_) async => const Right([]));
    when(
      () => mockAppwriteDbService.listDocuments(
        any(),
        queries: any(named: 'queries'),
      ),
    ).thenAnswer((_) async => []);

    container = ProviderContainer(
      overrides: [
        isAuthenticatedProvider.overrideWith((ref) async => false),
        currentUserProvider.overrideWith((ref) async => null),
        contentRepositoryProvider.overrideWithValue(mockContentRepository),
        lessonRepositoryProvider.overrideWithValue(mockLessonRepository),
        categoryRepositoryProvider.overrideWithValue(mockCategoryRepository),
        appwriteDbServiceProvider.overrideWithValue(mockAppwriteDbService),
      ],
    );
    testRef = container.read(_refProvider);
  });

  tearDown(() async {
    container.dispose();
    CacheService.resetForTesting();
    await realtimeController.close();
    await connectivityController.close();
  });

  test('subscribes to all 7 content collection channels on initialize', () {
    final sync = ContentRealtimeSync(
      ref: testRef,
      networkInfo: mockNetworkInfo,
      realtimeOverride: fakeRealtime,
    );

    sync.initialize();

    expect(fakeRealtime.subscribedChannels, isNotNull);
    final channels = fakeRealtime.subscribedChannels!.cast<String>();
    expect(
      channels,
      contains('databases.olitun_db.collections.words.documents'),
    );
    expect(
      channels,
      contains('databases.olitun_db.collections.sentences.documents'),
    );
    expect(
      channels,
      contains('databases.olitun_db.collections.lessons.documents'),
    );
    expect(
      channels,
      contains('databases.olitun_db.collections.letters.documents'),
    );
    expect(
      channels,
      contains('databases.olitun_db.collections.numbers.documents'),
    );
    expect(
      channels,
      contains('databases.olitun_db.collections.rhymes.documents'),
    );
    expect(
      channels,
      contains('databases.olitun_db.collections.categories.documents'),
    );

    sync.dispose();
  });

  test(
    'incoming word message evicts cache and invalidates providers',
    () async {
      ContentKind? invalidatedKind;
      String? invalidatedItemId;
      String? invalidatedCategoryId;

      final sync = ContentRealtimeSync(
        ref: testRef,
        networkInfo: mockNetworkInfo,
        realtimeOverride: fakeRealtime,
        onInvalidated: (kind, itemId, categoryId) {
          invalidatedKind = kind;
          invalidatedItemId = itemId;
          invalidatedCategoryId = categoryId;
        },
      );
      sync.initialize();

      // Populate local cache
      await CacheService.set('content_list_word_all', [
        {'id': 'w_1'},
      ]);
      await CacheService.set('content_list_word_cat_vocab', [
        {'id': 'w_1'},
      ]);
      await CacheService.set('content_item_word_w_1', {'id': 'w_1'});

      // Simulate incoming Realtime message for word w_1
      final message = RealtimeMessage(
        events: ['databases.olitun_db.collections.words.documents.w_1.update'],
        payload: {'\$id': 'w_1', 'category': 'cat_vocab', 'textLatin': 'Test'},
        channels: ['databases.olitun_db.collections.words.documents'],
        timestamp: DateTime.now().toIso8601String(),
      );

      await sync.handleMessageForTesting(message);

      // Verify cache eviction
      expect(
        await CacheService.get<dynamic>('content_list_word_all', (d) => d),
        isNull,
      );
      expect(
        await CacheService.get<dynamic>(
          'content_list_word_cat_vocab',
          (d) => d,
        ),
        isNull,
      );
      expect(
        await CacheService.get<dynamic>('content_item_word_w_1', (d) => d),
        isNull,
      );

      // Verify invalidation callback fired with correct parameters
      expect(invalidatedKind, ContentKind.word);
      expect(invalidatedItemId, 'w_1');
      expect(invalidatedCategoryId, 'cat_vocab');

      sync.dispose();
    },
  );

  test(
    'incoming lesson message evicts lesson cache and invalidates learner lessons',
    () async {
      ContentKind? invalidatedKind;
      String? invalidatedItemId;
      String? invalidatedCategoryId;

      final sync = ContentRealtimeSync(
        ref: testRef,
        networkInfo: mockNetworkInfo,
        realtimeOverride: fakeRealtime,
        onInvalidated: (kind, itemId, categoryId) {
          invalidatedKind = kind;
          invalidatedItemId = itemId;
          invalidatedCategoryId = categoryId;
        },
      );
      sync.initialize();

      await CacheService.set('content_list_lesson_all', [
        {'id': 'lesson_greet_1'},
      ]);
      await CacheService.set('content_list_lesson_cat_phrases', [
        {'id': 'lesson_greet_1'},
      ]);
      await CacheService.set('content_item_lesson_lesson_greet_1', {
        'id': 'lesson_greet_1',
      });

      final message = RealtimeMessage(
        events: [
          'databases.olitun_db.collections.lessons.documents.lesson_greet_1.update',
        ],
        payload: {
          '\$id': 'lesson_greet_1',
          'categoryId': 'cat_phrases',
          'titleLatin': 'Meeting People',
        },
        channels: ['databases.olitun_db.collections.lessons.documents'],
        timestamp: DateTime.now().toIso8601String(),
      );

      await sync.handleMessageForTesting(message);

      expect(
        await CacheService.get<dynamic>('content_list_lesson_all', (d) => d),
        isNull,
      );
      expect(
        await CacheService.get<dynamic>(
          'content_list_lesson_cat_phrases',
          (d) => d,
        ),
        isNull,
      );
      expect(
        await CacheService.get<dynamic>(
          'content_item_lesson_lesson_greet_1',
          (d) => d,
        ),
        isNull,
      );

      expect(invalidatedKind, ContentKind.lesson);
      expect(invalidatedItemId, 'lesson_greet_1');
      expect(invalidatedCategoryId, 'cat_phrases');

      sync.dispose();
    },
  );

  test(
    'incoming category message evicts category cache and invalidates categoryNotifierProvider',
    () async {
      final sync = ContentRealtimeSync(
        ref: testRef,
        networkInfo: mockNetworkInfo,
        realtimeOverride: fakeRealtime,
      );
      sync.initialize();

      await CacheService.set('cached_categories', [
        {'id': 'cat_vocab'},
      ]);

      final message = RealtimeMessage(
        events: [
          'databases.olitun_db.collections.categories.documents.cat_vocab.update',
        ],
        payload: {'\$id': 'cat_vocab', 'titleLatin': 'Vocabulary'},
        channels: ['databases.olitun_db.collections.categories.documents'],
        timestamp: DateTime.now().toIso8601String(),
      );

      await sync.handleMessageForTesting(message);

      expect(
        await CacheService.get<dynamic>('cached_categories', (d) => d),
        isNull,
      );

      sync.dispose();
    },
  );

  test('syncAll triggers onSyncAll callback', () {
    var syncAllCalled = false;
    final sync = ContentRealtimeSync(
      ref: testRef,
      networkInfo: mockNetworkInfo,
      realtimeOverride: fakeRealtime,
      onSyncAll: () => syncAllCalled = true,
    );

    sync.syncAll();

    expect(syncAllCalled, isTrue);
    sync.dispose();
  });

  test('regaining connectivity triggers syncAll', () async {
    var syncAllCalled = false;
    final sync = ContentRealtimeSync(
      ref: testRef,
      networkInfo: mockNetworkInfo,
      realtimeOverride: fakeRealtime,
      onSyncAll: () => syncAllCalled = true,
    );
    sync.initialize();

    // Fire connectivity restored event
    connectivityController.add([ConnectivityResult.wifi]);
    await pumpEventQueue();

    expect(syncAllCalled, isTrue);
    sync.dispose();
  });
}
