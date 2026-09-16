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

class _MockDatabases extends Mock implements Databases {}

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
  late _MockDatabases databases;
  late _MockFunctionsService functions;

  setUpAll(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'olitun_authorized_content_repo_',
    );
    Hive.init(tempDirectory.path);
  });

  setUp(() {
    CacheService.resetForTesting();
    databases = _MockDatabases();
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
      databases: databases,
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
    verifyZeroInteractions(databases);
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
        'lesson': {..._lessonMetadata(), 'blocks': <Map<String, dynamic>>[]},
      }),
    );
    final repository = ContentRepository(
      databases: databases,
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
        expect(lesson.blocks, isEmpty);
      },
    );
    verifyZeroInteractions(databases);
  });

  test(
    'missing authorization service never falls back to lesson reads',
    () async {
      final repository = ContentRepository(
        databases: databases,
        networkInfo: _OnlineNetworkInfo(),
      );

      final result = await repository.get(
        ContentKind.lesson,
        'secure_shared_lesson',
      );

      expect(result.isLeft(), isTrue);
      verifyZeroInteractions(databases);
    },
  );
}
