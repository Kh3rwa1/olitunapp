import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:file_picker/file_picker.dart';
import 'package:appwrite/appwrite.dart';
import 'package:itun/core/storage/media_uploader.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/core/error/failures.dart';

class MockClient extends Mock implements Client {}

void main() {
  group('MediaUploader Video Validation Tests', () {
    late MediaUploader uploader;
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient();
      uploader = MediaUploader(mockClient);
    });

    test('1. Reject 11 MB video file with size error', () async {
      final file = PlatformFile(
        name: 'movie.mp4',
        size: 11 * 1024 * 1024, // 11 MB
        path: 'dummy/movie.mp4',
      );

      final res = await uploader.validateFile(file, ContentMediaKind.video);
      expect(res.isLeft(), isTrue);
      res.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, contains('size exceeds the 10 MB limit'));
        },
        (_) => fail('Should have failed'),
      );
    });

    test('2. Reject unsupported extension (.avi) with mime error', () async {
      final file = PlatformFile(
        name: 'video.avi',
        size: 2 * 1024 * 1024, // 2 MB
        path: 'dummy/video.avi',
      );

      final res = await uploader.validateFile(file, ContentMediaKind.video);
      expect(res.isLeft(), isTrue);
      res.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, contains('Unsupported file format: .avi'));
        },
        (_) => fail('Should have failed'),
      );
    });

    test('3. Mock duration probe returning 6 minutes -> reject', () async {
      final file = PlatformFile(
        name: 'long_loop.mp4',
        size: 5 * 1024 * 1024, // 5 MB
        path: 'dummy/long_loop.mp4',
      );

      // Probe returns 6 minutes (360,000 ms)
      uploader.videoDurationProberOverride = (f) async => 360000;

      final res = await uploader.validateFile(file, ContentMediaKind.video);
      expect(res.isLeft(), isTrue);
      res.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, contains('duration exceeds the 5 minutes limit'));
        },
        (_) => fail('Should have failed'),
      );
    });

    test('4. Mock duration probe returning 4 minutes -> accept', () async {
      final file = PlatformFile(
        name: 'good_loop.mp4',
        size: 5 * 1024 * 1024, // 5 MB
        path: 'dummy/good_loop.mp4',
      );

      // Probe returns 4 minutes (240,000 ms)
      uploader.videoDurationProberOverride = (f) async => 240000;

      final res = await uploader.validateFile(file, ContentMediaKind.video);
      expect(res.isRight(), isTrue);
    });

    test('5. Mock duration probe throwing -> reject with graceful error message', () async {
      final file = PlatformFile(
        name: 'corrupt.mp4',
        size: 1 * 1024 * 1024,
        path: 'dummy/corrupt.mp4',
      );

      // Probe throws exception (e.g. read failure / corrupt header)
      uploader.videoDurationProberOverride = (f) async {
        throw Exception('File read error');
      };

      final res = await uploader.validateFile(file, ContentMediaKind.video);
      expect(res.isLeft(), isTrue);
      res.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, contains('Could not read video duration'));
        },
        (_) => fail('Should have failed'),
      );
    });

    test('6. Non-video file kind (e.g. image) -> skips validation constraints', () async {
      final file = PlatformFile(
        name: 'huge_image.png',
        size: 25 * 1024 * 1024, // 25 MB (size rule is only for video)
        path: 'dummy/huge_image.png',
      );

      final res = await uploader.validateFile(file, ContentMediaKind.image);
      expect(res.isRight(), isTrue);
    });
  });
}
