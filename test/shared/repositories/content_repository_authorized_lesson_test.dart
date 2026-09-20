import 'dart:convert';
import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:itun/core/api/appwrite_functions_service.dart';
import 'package:itun/core/network/network_info.dart';
import 'package:itun/core/storage/cache_service.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/shared/models/content_item_extensions.dart';
import 'package:itun/shared/repositories/content_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockDatabases extends Mock implements TablesDB {}

class _MockFunctionsService extends Mock implements AppwriteFunctionsService {}

class _OnlineNetworkInfo implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      const Stream.empty();
}

FunctionExecutionResult _execution(Map<String, dynamic> body) =>
    FunctionExecutionResult(
      status: 'completed',
      statusCode: 200,
      responseBody: jsonEncode(body),
    );

Map<String, dynamic> _lessonMetadata({bool locked = true}) => {
  'id': 'secure_shared_lesson',
  'categoryId': 'cat_secure_remote_only',
  'titleOlChiki': 'ᱥᱟᱱᱛᱟᱲᱤ',
  'titleLatin': 'Server-authorized lesson',
  'level': 'intermediate',
  'description': 'Metadata only',
  'order': 7,
  'estimatedMinutes': 9,
  'isActive': true,
  'isPreview': false,
  'isLocked': locked,
  'accessReason': locked ? 'purchase_required' : 'entitled',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDirectory;
  late _MockDatabases tablesDB;
  late _MockFunctionsService functions;

  setUpAll(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'olitun_authorized_content_repo_',
    );
    Hive.init(tempDirectory.path);
  });

  setUp(() {
    CacheService.resetForTesting();
    tablesDB = _MockDatabases();
    functions = _MockFunctionsService();
  });

  tearDownAll(() async {
    await Hive.close();
    CacheService.resetForTesting();
    await tempDirectory.delete(recursive: true);
  });

  test('learner lesson lists use only the authorization function', () async {
    when(
      () => functions.execute(
        'getAuthorizedLesson',
        body: {
          'action': 'list_lessons',
          'limit': 100,
          'categoryId': 'cat_secure_remote_only',
        },
        usePost: true,
      ),
    ).thenAnswer(
      (_) async => _execution({
        'ok': true,
        'lessons': [_lessonMetadata()],
        'hasMore': false,
        'nextCursor': null,
      }),
    );
    final repository = ContentRepository(
      tablesDB: tablesDB,
      networkInfo: _OnlineNetworkInfo(),
      functionsService: functions,
    );

    final result = await repository.list(
      ContentKind.lesson,
      categoryId: 'cat_secure_remote_only',
    );

    result.fold(
      (failure) => fail('Expected authorized lesson metadata: $failure'),
      (items) {
        final lesson = items.singleWhere(
          (item) => item.id == 'secure_shared_lesson',
        );
        expect(lesson.blocks, isEmpty);
        expect(lesson.isLocked, isTrue);
        expect(lesson.accessReason, 'purchase_required');
        expect(lesson.toLessonEntity().isLocked, isTrue);
        expect(lesson.toLessonEntity().level, 'intermediate');
        expect(lesson.toLessonEntity().estimatedMinutes, 9);
      },
    );
    verifyZeroInteractions(tablesDB);
  });

  test('learner lesson detail uses only the authorization function', () async {
    when(
      () => functions.execute(
        'getAuthorizedLesson',
        body: {'action': 'get_lesson', 'lessonId': 'secure_shared_lesson'},
        usePost: true,
      ),
    ).thenAnswer(
      (_) async => _execution({
        'ok': true,
        'locked': true,
        'reason': 'purchase_required',
        'lesson': {..._lessonMetadata(), 'blocks': <Map<String, dynamic>>[]},
      }),
    );
    final repository = ContentRepository(
      tablesDB: tablesDB,
      networkInfo: _OnlineNetworkInfo(),
      functionsService: functions,
    );

    final result = await repository.get(
      ContentKind.lesson,
      'secure_shared_lesson',
    );

    result.fold(
      (failure) => fail('Expected authorized lesson detail: $failure'),
      (lesson) {
        expect(lesson.isLocked, isTrue);
        expect(lesson.accessReason, 'purchase_required');
        expect(lesson.blocks, isEmpty);
      },
    );
    verifyZeroInteractions(tablesDB);
  });

  test(
    'missing authorization service never falls back to lesson reads',
    () async {
      final repository = ContentRepository(
        tablesDB: tablesDB,
        networkInfo: _OnlineNetworkInfo(),
      );

      final result = await repository.get(
        ContentKind.lesson,
        'secure_shared_lesson',
      );

      expect(result.isLeft(), isTrue);
      verifyZeroInteractions(tablesDB);
    },
  );

  test(
    'authorized lesson metadata is never persisted in legacy caches',
    () async {
      when(
        () => functions.execute(
          'getAuthorizedLesson',
          body: {
            'action': 'list_lessons',
            'limit': 100,
            'categoryId': 'cat_secure_remote_only',
          },
          usePost: true,
        ),
      ).thenAnswer(
        (_) async => _execution({
          'ok': true,
          'lessons': [_lessonMetadata(locked: false)],
          'hasMore': false,
          'nextCursor': null,
        }),
      );
      final repository = ContentRepository(
        tablesDB: tablesDB,
        networkInfo: _OnlineNetworkInfo(),
        functionsService: functions,
      );

      final result = await repository.list(
        ContentKind.lesson,
        categoryId: 'cat_secure_remote_only',
      );
      expect(result.isRight(), isTrue);
      final cached = await CacheService.getList<ContentItem>(
        'content_list_lesson_cat_secure_remote_only',
        (data) => ContentItem.fromJson(data, null, ContentKind.lesson),
      );
      expect(cached, isNull);
      expect(
        await CacheService.get<ContentItem>(
          'content_item_lesson_secure_shared_lesson',
          (data) => ContentItem.fromJson(data, null, ContentKind.lesson),
        ),
        isNull,
      );
    },
  );

  test('legacy cached lesson bodies cannot satisfy learner lists', () async {
    await CacheService.set('content_list_lesson_cat_secure_remote_only', [
      {
        'id': 'cached_paid_body',
        'kind': 'lesson',
        'categoryId': 'cat_secure_remote_only',
        'title': 'Legacy premium body',
        'blocks': [
          {'id': 'body', 'type': 'text', 'order': 0, 'markdown': 'secret'},
        ],
      },
    ]);
    when(
      () => functions.execute(
        'getAuthorizedLesson',
        body: {
          'action': 'list_lessons',
          'limit': 100,
          'categoryId': 'cat_secure_remote_only',
        },
        usePost: true,
      ),
    ).thenThrow(StateError('authorization unavailable'));
    final repository = ContentRepository(
      tablesDB: tablesDB,
      networkInfo: _OnlineNetworkInfo(),
      functionsService: functions,
    );

    final result = await repository.list(
      ContentKind.lesson,
      categoryId: 'cat_secure_remote_only',
    );
    expect(result.isLeft(), isTrue);
    verifyZeroInteractions(tablesDB);
  });

  test('legacy cached lesson detail cannot bypass authorization', () async {
    await CacheService.set('content_item_lesson_secure_shared_lesson', {
      'id': 'secure_shared_lesson',
      'kind': 'lesson',
      'categoryId': 'cat_secure_remote_only',
      'title': 'Legacy premium detail',
      'blocks': [
        {'id': 'body', 'type': 'text', 'order': 0, 'markdown': 'secret'},
      ],
    });
    final repository = ContentRepository(
      tablesDB: tablesDB,
      networkInfo: _OnlineNetworkInfo(),
    );

    final result = await repository.get(
      ContentKind.lesson,
      'secure_shared_lesson',
    );
    expect(result.isLeft(), isTrue);
    verifyZeroInteractions(tablesDB);
  });

  test('lesson level and preview survive Appwrite round trips', () {
    final item = ContentItem.fromJson(
      {
        'id': 'lesson_round_trip',
        'categoryId': 'cat_round_trip',
        'titleOlChiki': 'ᱚᱞ',
        'titleLatin': 'Round trip',
        'level': 'advanced',
        'isPreview': true,
      },
      'lesson_round_trip',
      ContentKind.lesson,
    );

    expect(item.difficulty, 'advanced');
    expect(item.isPreview, isTrue);
    final attributes = item.toAppwriteAttributes();
    expect(attributes['level'], 'advanced');
    expect(attributes['isPreview'], isTrue);
  });

  test(
    'remote lessons are authoritative and do not merge bundled seed lessons when online',
    () async {
      when(
        () => functions.execute(
          'getAuthorizedLesson',
          body: {'action': 'list_lessons', 'limit': 100},
          usePost: true,
        ),
      ).thenAnswer(
        (_) async => _execution({
          'ok': true,
          'lessons': [_lessonMetadata()],
          'hasMore': false,
          'nextCursor': null,
        }),
      );
      final repository = ContentRepository(
        tablesDB: tablesDB,
        networkInfo: _OnlineNetworkInfo(),
        functionsService: functions,
      );

      final result = await repository.list(ContentKind.lesson);

      result.fold((failure) => fail('Expected authorized lessons: $failure'), (
        items,
      ) {
        // Must only contain the remote lesson from the server/admin panel,
        // not the 20+ bundled seed lessons
        expect(items.length, 1);
        expect(items.single.id, 'secure_shared_lesson');
      });
    },
  );
}
