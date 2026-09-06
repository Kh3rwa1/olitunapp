// ignore_for_file: deprecated_member_use
import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:itun/core/config/appwrite_config.dart';
import 'package:itun/core/network/network_info.dart';
import 'package:itun/core/storage/cache_service.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/shared/repositories/content_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockDatabases extends Mock implements Databases {}

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

models.Document _buildCategoryDoc({
  required String categoryId,
  required String unlockMode,
  int previewLessonCount = 0,
}) => models.Document(
  $id: categoryId,
  $collectionId: 'categories',
  $databaseId: AppwriteConfig.databaseId,
  $createdAt: '2026-09-01T00:00:00.000Z',
  $updatedAt: '2026-09-01T00:00:00.000Z',
  $permissions: [],
  $sequence: 1,
  data: {
    'unlockMode': unlockMode,
    'previewLessonCount': previewLessonCount,
  },
);

models.Document _buildLessonDoc(Map<String, dynamic> data) => models.Document(
  $id: 'lesson_basics_1',
  $collectionId: 'lessons',
  $databaseId: AppwriteConfig.databaseId,
  $createdAt: '2026-09-01T00:00:00.000Z',
  $updatedAt: '2026-09-06T00:00:00.000Z',
  $permissions: [],
  $sequence: 1,
  data: data,
);

void main() {
  late Directory tempDir;
  late _MockDatabases databases;
  late ContentRepository repo;

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
    databases = _MockDatabases();
    repo = ContentRepository(
      databases: databases,
      networkInfo: _FakeNetworkInfo(),
    );
  });

  group('ContentRepository.upsert category-aware lesson publication', () {
    test('successfully upserts a lesson in a free category with public permissions', () async {
      when(
        () => databases.getDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: 'categories',
          documentId: 'cat_sentences',
        ),
      ).thenAnswer(
        (_) async => _buildCategoryDoc(
          categoryId: 'cat_sentences',
          unlockMode: 'free',
        ),
      );

      when(
        () => databases.createDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: 'lessons',
          documentId: 'lesson_basics_1',
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
        () => databases.createDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: 'lessons',
          documentId: 'lesson_basics_1',
          data: any(named: 'data'),
          permissions: captureAny(named: 'permissions'),
        ),
      ).captured;

      final perms = captured.first as List<String>;
      expect(perms, contains(Permission.read(Role.any())));
    });

    test('updates existing lesson (409 Conflict) without throwing Bad State', () async {
      when(
        () => databases.getDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: 'categories',
          documentId: 'cat_sentences',
        ),
      ).thenAnswer(
        (_) async => _buildCategoryDoc(
          categoryId: 'cat_sentences',
          unlockMode: 'free',
        ),
      );

      when(
        () => databases.createDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: 'lessons',
          documentId: 'lesson_basics_1',
          data: any(named: 'data'),
          permissions: any(named: 'permissions'),
        ),
      ).thenThrow(AppwriteException('Document already exists', 409));

      when(
        () => databases.updateDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: 'lessons',
          documentId: 'lesson_basics_1',
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
        () => databases.updateDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: 'lessons',
          documentId: 'lesson_basics_1',
          data: any(named: 'data'),
          permissions: any(named: 'permissions'),
        ),
      ).called(1);
    });

    test('protects paid lessons outside preview window', () async {
      when(
        () => databases.getDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: 'categories',
          documentId: 'cat_paid',
        ),
      ).thenAnswer(
        (_) async => _buildCategoryDoc(
          categoryId: 'cat_paid',
          unlockMode: 'paid_only',
          previewLessonCount: 2,
        ),
      );

      when(
        () => databases.createDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: 'lessons',
          documentId: 'lesson_basics_1',
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
        () => databases.createDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: 'lessons',
          documentId: 'lesson_basics_1',
          data: any(named: 'data'),
          permissions: captureAny(named: 'permissions'),
        ),
      ).captured;

      final perms = captured.first as List<String>;
      expect(perms, isEmpty);
    });
  });
}
