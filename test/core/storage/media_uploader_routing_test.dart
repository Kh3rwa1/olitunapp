import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:appwrite/appwrite.dart';
import 'package:itun/core/storage/media_uploader.dart';
import 'package:itun/shared/models/content_item.dart';

class MockClient extends Mock implements Client {}

void main() {
  group('MediaUploader Bucket Routing Tests', () {
    late MediaUploader uploader;
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient();
      uploader = MediaUploader(mockClient);
    });

    test('Video uploads correctly route to cover_videos bucket', () {
      final bucketIdMp4 = uploader.getBucketIdForTesting(
        ContentMediaKind.video,
        'test.mp4',
      );
      final bucketIdWebm = uploader.getBucketIdForTesting(
        ContentMediaKind.video,
        'my_video.webm',
      );
      final bucketIdMov = uploader.getBucketIdForTesting(
        ContentMediaKind.video,
        'loop.mov',
      );

      expect(bucketIdMp4, equals('cover_videos'));
      expect(bucketIdWebm, equals('cover_videos'));
      expect(bucketIdMov, equals('cover_videos'));
    });

    test('Image uploads correctly route to images bucket', () {
      final bucketIdPng = uploader.getBucketIdForTesting(
        ContentMediaKind.image,
        'thumb.png',
      );
      final bucketIdJpg = uploader.getBucketIdForTesting(
        ContentMediaKind.image,
        'banner.jpg',
      );
      final bucketIdSvg = uploader.getBucketIdForTesting(
        ContentMediaKind.image,
        'vector.svg',
      );

      expect(bucketIdPng, equals('images'));
      expect(bucketIdJpg, equals('images'));
      expect(bucketIdSvg, equals('images'));
    });

    test('Audio uploads correctly route to audio bucket', () {
      final bucketIdMp3 = uploader.getBucketIdForTesting(
        ContentMediaKind.audio,
        'soundtrack.mp3',
      );
      final bucketIdWav = uploader.getBucketIdForTesting(
        ContentMediaKind.audio,
        'vocals.wav',
      );

      expect(bucketIdMp3, equals('audio'));
      expect(bucketIdWav, equals('audio'));
    });

    test('Lottie uploads correctly route to animations bucket', () {
      final bucketIdJson = uploader.getBucketIdForTesting(
        ContentMediaKind.lottie,
        'confetti.json',
      );
      expect(bucketIdJson, equals('animations'));
    });
  });
}
