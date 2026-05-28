import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:appwrite/appwrite.dart';
import 'package:itun/core/storage/media_uploader.dart';
import 'package:itun/core/api/appwrite_db_service.dart';
import 'package:itun/core/error/failures.dart';

class MockClient extends Mock implements Client {}

class MockAppwriteDbService extends Mock implements AppwriteDbService {}

/// Subclass of MediaUploader that overrides `delete` to verify reference guarding
/// without having to mock Appwrite's internal Client.call/Storage mechanisms.
class TestMediaUploader extends MediaUploader {
  bool deleteCalled = false;
  String? deletedFileId;
  String? deletedBucketId;
  Either<Failure, Unit> deleteResult = right(unit);

  TestMediaUploader(super.client, super.dbService);

  @override
  Future<Either<Failure, Unit>> delete(
    String fileId, [
    String? bucketId,
  ]) async {
    deleteCalled = true;
    deletedFileId = fileId;
    deletedBucketId = bucketId;
    return deleteResult;
  }
}

void main() {
  group('MediaUploader deleteIfUnreferenced (Reference Guard) Tests', () {
    late MockClient mockClient;
    late MockAppwriteDbService mockDbService;
    late TestMediaUploader uploader;

    setUp(() {
      mockClient = MockClient();
      mockDbService = MockAppwriteDbService();
      uploader = TestMediaUploader(mockClient, mockDbService);
    });

    test(
      '1. Empty fileId -> returns right(unit) without checks or deletion',
      () async {
        final res = await uploader.deleteIfUnreferenced(
          fileId: '',
          checks: const [
            ReferenceCheck(
              databaseId: 'db',
              collectionId: 'col',
              fieldNames: ['audioFileId'],
            ),
          ],
        );

        expect(res.isRight(), isTrue);
        expect(uploader.deleteCalled, isFalse);
      },
    );

    test('2. No references found -> proceeds to actual deletion', () async {
      const fileId = 'target_file_123';

      // Mock listDocuments returning empty (no references)
      when(
        () => mockDbService.listDocuments(
          'rhymes',
          queries: any(named: 'queries'),
          paginate: false,
        ),
      ).thenAnswer((_) async => []);

      final res = await uploader.deleteIfUnreferenced(
        fileId: fileId,
        checks: const [
          ReferenceCheck(
            databaseId: 'olitun_db',
            collectionId: 'rhymes',
            fieldNames: ['audioFileId'],
          ),
        ],
      );

      expect(res.isRight(), isTrue);
      expect(uploader.deleteCalled, isTrue);
      expect(uploader.deletedFileId, equals(fileId));
      verify(
        () => mockDbService.listDocuments(
          'rhymes',
          queries: [Query.equal('audioFileId', fileId), Query.limit(1)],
          paginate: false,
        ),
      ).called(1);
    });

    test(
      '3. File referenced by document -> refuses deletion and returns right(unit) no-op',
      () async {
        const fileId = 'actively_referenced_file';

        // Mock listDocuments returning a referencing document
        when(
          () => mockDbService.listDocuments(
            'rhymes',
            queries: any(named: 'queries'),
            paginate: false,
          ),
        ).thenAnswer(
          (_) async => [
            {'id': 'doc_abc', 'audioFileId': fileId},
          ],
        );

        final res = await uploader.deleteIfUnreferenced(
          fileId: fileId,
          checks: const [
            ReferenceCheck(
              databaseId: 'olitun_db',
              collectionId: 'rhymes',
              fieldNames: ['audioFileId'],
            ),
          ],
        );

        expect(res.isRight(), isTrue);
        expect(uploader.deleteCalled, isFalse); // Refused!
        verify(
          () => mockDbService.listDocuments(
            'rhymes',
            queries: [Query.equal('audioFileId', fileId), Query.limit(1)],
            paginate: false,
          ),
        ).called(1);
      },
    );

    test(
      '4. Reference check query failure -> refuses deletion (fail-safe) and returns right(unit)',
      () async {
        const fileId = 'safe_failure_file';

        // Mock listDocuments throwing an error
        when(
          () => mockDbService.listDocuments(
            'rhymes',
            queries: any(named: 'queries'),
            paginate: false,
          ),
        ).thenThrow(AppwriteException('Connection timed out', 500));

        final res = await uploader.deleteIfUnreferenced(
          fileId: fileId,
          checks: const [
            ReferenceCheck(
              databaseId: 'olitun_db',
              collectionId: 'rhymes',
              fieldNames: ['audioFileId'],
            ),
          ],
        );

        expect(res.isRight(), isTrue);
        expect(uploader.deleteCalled, isFalse); // Refused as a fail-safe!
      },
    );

    test('5. Multiple field checks -> any reference blocks deletion', () async {
      const fileId = 'multi_checked_file';

      // Setup 1: first check (audioFileId) has no references
      when(
        () => mockDbService.listDocuments(
          'rhymes',
          queries: [Query.equal('audioFileId', fileId), Query.limit(1)],
          paginate: false,
        ),
      ).thenAnswer((_) async => []);

      // Setup 2: second check (coverFileId) has a reference
      when(
        () => mockDbService.listDocuments(
          'rhymes',
          queries: [Query.equal('coverFileId', fileId), Query.limit(1)],
          paginate: false,
        ),
      ).thenAnswer(
        (_) async => [
          {'id': 'doc_xyz', 'coverFileId': fileId},
        ],
      );

      final res = await uploader.deleteIfUnreferenced(
        fileId: fileId,
        checks: const [
          ReferenceCheck(
            databaseId: 'olitun_db',
            collectionId: 'rhymes',
            fieldNames: ['audioFileId', 'coverFileId'],
          ),
        ],
      );

      expect(res.isRight(), isTrue);
      expect(
        uploader.deleteCalled,
        isFalse,
      ); // Refused because second field has reference!
    });
  });
}
