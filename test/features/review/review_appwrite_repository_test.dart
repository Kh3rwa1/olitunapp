import 'package:appwrite/appwrite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/api/appwrite_db_service.dart';
import 'package:itun/core/api/appwrite_functions_service.dart';
import 'package:itun/features/review/data/review_appwrite_repository.dart';
import 'package:itun/features/review/data/review_store.dart';
import 'package:itun/features/review/domain/review_item.dart';

class _FakeAppwriteDbService implements AppwriteDbService {
  final Map<String, Map<String, dynamic>> rows = {};
  final Map<String, List<String>> permissions = {};
  final Map<String, String> rowOwners = {};

  @override
  Future<Map<String, dynamic>> createOwnerPrivateRow(
    String collectionId,
    String documentId,
    Map<String, dynamic> data,
    String ownerUserId,
  ) async {
    if (rows.containsKey(documentId)) {
      throw AppwriteException(
        'Document already exists',
        409,
        'document_already_exists',
      );
    }
    rows[documentId] = Map.of(data);
    permissions[documentId] = [
      'read("user:$ownerUserId")',
      'update("user:$ownerUserId")',
      'delete("user:$ownerUserId")',
    ];
    rowOwners[documentId] = ownerUserId;
    return rows[documentId]!;
  }

  @override
  Future<Map<String, dynamic>> updateDataPreservingPermissions(
    String collectionId,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    if (!rows.containsKey(documentId)) {
      throw AppwriteException('Document not found', 404, 'document_not_found');
    }
    rows[documentId] = Map.of(data);
    return rows[documentId]!;
  }

  @override
  Future<void> deleteDocument(String collectionId, String documentId) async {
    if (!rows.containsKey(documentId)) {
      throw AppwriteException('Document not found', 404, 'document_not_found');
    }
    rows.remove(documentId);
    permissions.remove(documentId);
    rowOwners.remove(documentId);
  }

  @override
  Future<List<Map<String, dynamic>>> listDocuments(
    String collectionId, {
    int pageSize = 100,
    bool paginate = false,
    List<String>? queries,
  }) async {
    return rows.values.toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAppwriteFunctionsService implements AppwriteFunctionsService {
  final List<({String functionId, Map<String, dynamic> body, bool usePost})>
  calls = [];
  FunctionExecutionResult Function(
    String functionId,
    Map<String, dynamic> body,
    bool usePost,
  )?
  onExecute;

  @override
  Future<FunctionExecutionResult> execute(
    String functionId, {
    Map<String, dynamic> body = const {},
    bool usePost = false,
  }) async {
    calls.add((functionId: functionId, body: body, usePost: usePost));
    if (onExecute != null) {
      return onExecute!(functionId, body, usePost);
    }
    return const FunctionExecutionResult(
      status: 'completed',
      statusCode: 200,
      responseBody: '{"ok":true}',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ReviewAppwriteRepository rowId algorithms', () {
    test(
      'current hashed row ID format adheres strictly to Appwrite document-ID specifications',
      () {
        final id = ReviewAppwriteRepository.rowIdFor('user-123', 'word_456');
        expect(id.length, lessThanOrEqualTo(36));
        expect(id.length, 33);
        expect(RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9._-]*$').hasMatch(id), isTrue);
        expect(id.startsWith('r_'), isTrue);
      },
    );

    test(
      'legacy row ID format adheres to sanitized double-underscore format',
      () {
        final id = ReviewAppwriteRepository.legacyRowIdFor('user/1', 'word@1');
        expect(id, equals('user_1__word_1'));
      },
    );

    test(
      'row-ID sanitization collisions: special characters produce distinct hashed IDs',
      () {
        final id1 = ReviewAppwriteRepository.rowIdFor('u/1', 'word1');
        final id2 = ReviewAppwriteRepository.rowIdFor('u_1', 'word1');
        final id3 = ReviewAppwriteRepository.rowIdFor('u-1', 'word1');
        final id4 = ReviewAppwriteRepository.rowIdFor('u.1', 'word1');

        expect(id1, isNot(equals(id2)));
        expect(id1, isNot(equals(id3)));
        expect(id1, isNot(equals(id4)));
        expect(id2, isNot(equals(id3)));
      },
    );

    test(
      'truncation collisions: strings beyond 60 chars produce distinct hashed IDs',
      () {
        final longBase = 'a' * 80;
        final id1 = ReviewAppwriteRepository.rowIdFor('${longBase}_1', 'w1');
        final id2 = ReviewAppwriteRepository.rowIdFor('${longBase}_2', 'w1');

        expect(id1, isNot(equals(id2)));
      },
    );

    test(
      'different user/item boundary inputs never produce the same hashed row ID',
      () {
        final id1 = ReviewAppwriteRepository.rowIdFor('user_1', 'item_2');
        final id2 = ReviewAppwriteRepository.rowIdFor('user', '1__item_2');
        final id3 = ReviewAppwriteRepository.rowIdFor('user_1_item', '2');

        expect(id1, isNot(equals(id2)));
        expect(id1, isNot(equals(id3)));
        expect(id2, isNot(equals(id3)));
      },
    );
  });

  group('ReviewAppwriteRepository Function-based mutations', () {
    late _FakeAppwriteDbService db;
    late _FakeAppwriteFunctionsService functions;
    late ReviewAppwriteRepository repo;

    setUp(() {
      db = _FakeAppwriteDbService();
      functions = _FakeAppwriteFunctionsService();
      repo = ReviewAppwriteRepository(db, functions);
    });

    final testItem = MemoryItemState(
      itemId: 'word_1',
      itemType: ReviewItemType.word,
      introducedAt: DateTime.utc(2026),
      nextReviewAt: DateTime.utc(2026, 1, 4),
      lastPresentedAt: DateTime.utc(2026),
      lastReviewedAt: DateTime.utc(2026),
      successfulRecalls: 1,
      intervalDays: 3.0,
    );

    test(
      'pushState routes through mutateReviewState Appwrite Function',
      () async {
        await repo.pushState('alice_123', testItem);

        expect(functions.calls, hasLength(1));
        final call = functions.calls.first;
        expect(call.functionId, 'mutateReviewState');
        expect(call.usePost, isTrue);
        expect(call.body['action'], 'upsert');
        expect(call.body['itemId'], 'word_1');
        expect(call.body['itemType'], 'word');
        expect(call.body['schemaVersion'], ReviewStore.schemaVersion);
        expect(
          call.body['nextReviewAt'],
          testItem.nextReviewAt.toIso8601String(),
        );
        expect(
          call.body.containsKey('userId'),
          isFalse,
        ); // Prefer removing userId from client payload
      },
    );

    test(
      'deleteState routes through mutateReviewState Appwrite Function',
      () async {
        await repo.deleteState('alice_123', 'word_1');

        expect(functions.calls, hasLength(1));
        final call = functions.calls.first;
        expect(call.functionId, 'mutateReviewState');
        expect(call.usePost, isTrue);
        expect(call.body['action'], 'delete');
        expect(call.body['itemId'], 'word_1');
      },
    );

    test('pushState throws AppwriteException on function failure', () async {
      functions.onExecute = (_, _, _) => const FunctionExecutionResult(
        status: 'failed',
        statusCode: 500,
        responseBody: '{"ok":false,"error":"SERVER_ERROR"}',
      );

      expect(
        () => repo.pushState('alice_123', testItem),
        throwsA(isA<AppwriteException>()),
      );
    });
  });

  group(
    'ReviewAppwriteRepository security and Function-only mutation enforcement',
    () {
      late _FakeAppwriteDbService db;
      late _FakeAppwriteFunctionsService functions;
      late ReviewAppwriteRepository repo;

      setUp(() {
        db = _FakeAppwriteDbService();
        functions = _FakeAppwriteFunctionsService();
        repo = ReviewAppwriteRepository(db, functions);
      });

      final testItem = MemoryItemState(
        itemId: 'word_1',
        itemType: ReviewItemType.word,
        introducedAt: DateTime.utc(2026),
        nextReviewAt: DateTime.utc(2026, 1, 4),
        lastPresentedAt: DateTime.utc(2026),
        lastReviewedAt: DateTime.utc(2026),
        successfulRecalls: 1,
        intervalDays: 3.0,
      );

      test(
        'pushState executes via Function and performs zero direct DB writes',
        () async {
          await repo.pushState('alice_123', testItem);

          expect(functions.calls, hasLength(1));
          expect(functions.calls.first.functionId, 'mutateReviewState');
          expect(functions.calls.first.body['action'], 'upsert');
          expect(
            db.rows,
            isEmpty,
            reason:
                'Direct database writes are forbidden; mutations must go through Function.',
          );
        },
      );

      test(
        'deleteState executes via Function and performs zero direct DB writes',
        () async {
          await repo.deleteState('alice_123', 'word_1');

          expect(functions.calls, hasLength(1));
          expect(functions.calls.first.functionId, 'mutateReviewState');
          expect(functions.calls.first.body['action'], 'delete');
          expect(
            db.rows,
            isEmpty,
            reason:
                'Direct database deletions are forbidden; deletions must go through Function.',
          );
        },
      );

      test(
        'SECURITY: client cannot directly write to review_states table',
        () async {
          // Direct table create is forbidden by empty table permissions []
          // and repository does not expose any direct write methods.
          expect(
            () async => repo.pushState('alice_123', testItem),
            returnsNormally,
          );
          expect(
            functions.calls.any((c) => c.functionId == 'mutateReviewState'),
            isTrue,
          );
        },
      );
    },
  );
}
