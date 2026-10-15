import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:itun/shared/media/media_uploader.dart';
import 'package:itun/core/storage/worker_media_api.dart';

class MockWorkerMediaApi extends Mock implements WorkerMediaApi {}

const _checks = [
  ReferenceCheck(collectionId: 'rhymes', fieldNames: ['audioFileId']),
];

void main() {
  group('MediaUploader deleteIfUnreferenced (Reference Guard) Tests', () {
    late MockWorkerMediaApi api;
    late MediaUploader uploader;

    setUp(() {
      api = MockWorkerMediaApi();
      uploader = MediaUploader(api);
      when(() => api.delete(any(), any())).thenAnswer((_) async => true);
    });

    test('1. Empty fileId -> no check, no deletion', () async {
      final res = await uploader.deleteIfUnreferenced(
        fileId: '',
        checks: _checks,
      );

      expect(res.isRight(), isTrue);
      verifyNever(() => api.isReferenced(any()));
      verifyNever(() => api.delete(any(), any()));
    });

    test('2. Unreferenced -> deletes from the given bucket', () async {
      when(() => api.isReferenced('f1')).thenAnswer((_) async => false);

      final res = await uploader.deleteIfUnreferenced(
        fileId: 'f1',
        checks: _checks,
        bucketId: 'audio',
      );

      expect(res.isRight(), isTrue);
      verify(() => api.isReferenced('f1')).called(1);
      verify(() => api.delete('audio', 'f1')).called(1);
    });

    test('3. Referenced -> refuses deletion as a no-op', () async {
      when(() => api.isReferenced('f2')).thenAnswer((_) async => true);

      final res = await uploader.deleteIfUnreferenced(
        fileId: 'f2',
        checks: _checks,
      );

      expect(res.isRight(), isTrue);
      verifyNever(() => api.delete(any(), any()));
    });

    test(
      '4. Reference check failure -> refuses deletion (fail-safe)',
      () async {
        when(
          () => api.isReferenced('f3'),
        ).thenThrow(const WorkerMediaException('boom', statusCode: 500));

        final res = await uploader.deleteIfUnreferenced(
          fileId: 'f3',
          checks: _checks,
        );

        expect(res.isRight(), isTrue);
        verifyNever(() => api.delete(any(), any()));
      },
    );
  });

  group('MediaUploader.delete', () {
    late MockWorkerMediaApi api;
    late MediaUploader uploader;

    setUp(() {
      api = MockWorkerMediaApi();
      uploader = MediaUploader(api);
    });

    test(
      'without a bucket, stops at the first bucket that held the file',
      () async {
        when(() => api.delete(any(), any())).thenAnswer((_) async => false);
        when(() => api.delete('audio', 'f4')).thenAnswer((_) async => true);

        final res = await uploader.delete('f4');

        expect(res.isRight(), isTrue);
        verify(() => api.delete('images', 'f4')).called(1);
        verify(() => api.delete('videos', 'f4')).called(1);
        verify(() => api.delete('audio', 'f4')).called(1);
        verifyNever(() => api.delete('animations', 'f4'));
      },
    );

    test('maps Worker errors to a failure', () async {
      when(
        () => api.delete('images', 'f5'),
      ).thenThrow(const WorkerMediaException('forbidden', statusCode: 403));

      final res = await uploader.delete('f5', 'images');

      expect(res.isLeft(), isTrue);
    });
  });
}
