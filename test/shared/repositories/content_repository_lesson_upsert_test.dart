import 'dart:convert';
import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/core/api/content_remote_datasource.dart';
import 'package:itun/core/config/appwrite_config.dart';
import 'package:itun/core/network/network_info.dart';
import 'package:itun/core/storage/cache_service.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/shared/repositories/content_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockDatabases extends Mock implements TablesDB {}

class _FakeNetworkInfo implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      const Stream.empty();
}

ContentItem _buildLessonItem({
  String categoryId = 'cat_sentences',
  bool isPremium = false,
  int order = 1,
}) => ContentItem(
  id: 'lesson_basics_1',
  kind: ContentKind.lesson,
  categoryId: categoryId,
  title: 'Basic Sentences',
  titleOlChiki: 'ᱥᱟᱱᱛᱟᱲᱤ ᱟᱹᱭᱟᱹᱛ',
  blocks: const [
    TextBlock(
      id: 'b1',
      order: 0,
      markdown: 'Nowa do ced kana?',
      textLatin: 'Nowa do ced kana?',
      textOlChiki: 'ᱱᱚᱶᱟ ᱫᱚ ᱪᱮᱫ ᱠᱟᱱᱟ?',
      meta: {
        'meaning_bn': 'এটা কি?',
        'meaning_hi': 'यह क्या है?',
        'meaning_or': 'ଏହା କ’ଣ?',
        'meaning_en': 'What is this?',
      },
    ),
  ],
  order: order,
  isPremium: isPremium,
  isPublished: true,
  updatedAt: DateTime(2026, 9, 6),
);

models.Row _buildLessonDoc(Map<String, dynamic> data) => models.Row(
  $id: 'lesson_basics_1',
  $tableId: 'lessons',
  $databaseId: AppwriteConfig.databaseId,
  $createdAt: '2026-09-01T00:00:00.000Z',
  $updatedAt: '2026-09-06T00:00:00.000Z',
  $permissions: [],
  $sequence: 1,
  data: data,
);

void main() {
  late Directory tempDir;
  late _MockDatabases tablesDB;
  late ContentRepository repo;
  late Map<String, Map<String, dynamic>> categories;
  late List<Uri> edgeRequests;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('test_hive_lesson_upsert');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    CacheService.resetForTesting();
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  setUp(() {
    CacheService.resetForTesting();
    tablesDB = _MockDatabases();
    categories = {};
    edgeRequests = [];
    // Category premium lookups go to the Worker's /api/v1/categories/:id.
    final edge = MockClient((request) async {
      edgeRequests.add(request.url);
      final id = request.url.pathSegments.last;
      final category = categories[id];
      if (category == null) return http.Response('{"ok":false}', 404);
      return http.Response(
        jsonEncode({
          'ok': true,
          'category': {'id': id, ...category},
        }),
        200,
      );
    });
    repo = ContentRepository(
      remoteDataSource: ContentRemoteDataSourceImpl(
        tablesDB: tablesDB,
        httpClient: edge,
      ),
      networkInfo: _FakeNetworkInfo(),
    );
  });

  group('ContentRepository.upsert category-aware lesson publication', () {
    test(
      'successfully upserts a lesson in a free category with public permissions',
      () async {
        categories['cat_sentences'] = {
          'unlockMode': 'free',
          'previewLessonCount': 0,
        };

        when(
          () => tablesDB.createRow(
            databaseId: AppwriteConfig.databaseId,
            tableId: 'lessons',
            rowId: 'lesson_basics_1',
            data: any(named: 'data'),
            permissions: any(named: 'permissions'),
          ),
        ).thenAnswer(
          (invocation) async => _buildLessonDoc(
            invocation.namedArguments[#data] as Map<String, dynamic>,
          ),
        );

        final lesson = _buildLessonItem();
        final result = await repo.upsert(lesson);

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Upsert should have succeeded: ${failure.message}'),
          (saved) {
            expect(saved.id, 'lesson_basics_1');
            expect(saved.kind, ContentKind.lesson);
            expect(saved.blocks.length, 1);
          },
        );

        final captured = verify(
          () => tablesDB.createRow(
            databaseId: AppwriteConfig.databaseId,
            tableId: 'lessons',
            rowId: 'lesson_basics_1',
            data: any(named: 'data'),
            permissions: captureAny(named: 'permissions'),
          ),
        ).captured;

        final perms = captured.first as List<String>;
        expect(perms, contains(Permission.read(Role.any())));
      },
    );

    test(
      'updates existing lesson (409 Conflict) without throwing Bad State',
      () async {
        categories['cat_sentences'] = {
          'unlockMode': 'free',
          'previewLessonCount': 0,
        };

        when(
          () => tablesDB.createRow(
            databaseId: AppwriteConfig.databaseId,
            tableId: 'lessons',
            rowId: 'lesson_basics_1',
            data: any(named: 'data'),
            permissions: any(named: 'permissions'),
          ),
        ).thenThrow(AppwriteException('Document already exists', 409));

        when(
          () => tablesDB.updateRow(
            databaseId: AppwriteConfig.databaseId,
            tableId: 'lessons',
            rowId: 'lesson_basics_1',
            data: any(named: 'data'),
            permissions: any(named: 'permissions'),
          ),
        ).thenAnswer(
          (invocation) async => _buildLessonDoc(
            invocation.namedArguments[#data] as Map<String, dynamic>,
          ),
        );

        final lesson = _buildLessonItem();
        final result = await repo.upsert(lesson);

        expect(result.isRight(), isTrue);
        verify(
          () => tablesDB.updateRow(
            databaseId: AppwriteConfig.databaseId,
            tableId: 'lessons',
            rowId: 'lesson_basics_1',
            data: any(named: 'data'),
            permissions: any(named: 'permissions'),
          ),
        ).called(1);
      },
    );

    test('protects paid lessons outside preview window', () async {
      categories['cat_paid'] = {
        'unlockMode': 'paid_only',
        'previewLessonCount': 2,
      };

      when(
        () => tablesDB.createRow(
          databaseId: AppwriteConfig.databaseId,
          tableId: 'lessons',
          rowId: 'lesson_basics_1',
          data: any(named: 'data'),
          permissions: any(named: 'permissions'),
        ),
      ).thenAnswer(
        (invocation) async => _buildLessonDoc(
          invocation.namedArguments[#data] as Map<String, dynamic>,
        ),
      );

      final lesson = _buildLessonItem(categoryId: 'cat_paid', order: 5);
      final result = await repo.upsert(lesson);

      expect(result.isRight(), isTrue);

      final captured = verify(
        () => tablesDB.createRow(
          databaseId: AppwriteConfig.databaseId,
          tableId: 'lessons',
          rowId: 'lesson_basics_1',
          data: any(named: 'data'),
          permissions: captureAny(named: 'permissions'),
        ),
      ).captured;

      final perms = captured.first as List<String>;
      expect(perms, isEmpty);
      expect(edgeRequests.single.path, '/api/v1/categories/cat_paid');
      verifyNever(
        () => tablesDB.getRow(
          databaseId: any(named: 'databaseId'),
          tableId: 'categories',
          rowId: any(named: 'rowId'),
        ),
      );
    });

    test(
      'unresolvable category (Worker error) keeps the lesson private',
      () async {
        when(
          () => tablesDB.createRow(
            databaseId: AppwriteConfig.databaseId,
            tableId: 'lessons',
            rowId: 'lesson_basics_1',
            data: any(named: 'data'),
            permissions: any(named: 'permissions'),
          ),
        ).thenAnswer(
          (invocation) async => _buildLessonDoc(
            invocation.namedArguments[#data] as Map<String, dynamic>,
          ),
        );

        final result = await repo.upsert(_buildLessonItem(categoryId: 'cat_x'));

        expect(result.isRight(), isTrue);
        final captured = verify(
          () => tablesDB.createRow(
            databaseId: AppwriteConfig.databaseId,
            tableId: 'lessons',
            rowId: 'lesson_basics_1',
            data: any(named: 'data'),
            permissions: captureAny(named: 'permissions'),
          ),
        ).captured;
        expect(captured.first as List<String>, isEmpty);
      },
    );
  });
}
