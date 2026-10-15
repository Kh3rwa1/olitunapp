import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/storage/upload_service.dart';

void main() {
  group('MediaUploadService', () {
    test('maps supported media extensions to R2 buckets', () {
      expect(
        MediaUploadService.targetForFilename('sound.mp3').bucketId,
        'audio',
      );
      expect(
        MediaUploadService.targetForFilename('hero.PNG').bucketId,
        'images',
      );
      expect(
        MediaUploadService.targetForFilename('motion.json').bucketId,
        'animations',
      );
      expect(
        MediaUploadService.targetForFilename('intro.mov').bucketId,
        'videos',
      );
      expect(
        MediaUploadService.targetForFilename('interactive.html').bucketId,
        'html',
      );
    });

    test('rejects unsupported file types before upload', () {
      expect(
        () => MediaUploadService.targetForFilename('notes.txt'),
        throwsException,
      );
    });

    test('sanitizes logical folder and file names for upload names', () {
      final name = MediaUploadService.storageFilename(
        '../My Lesson Audio.mp3',
        'Letters / Audio',
      );

      expect(name, contains('letters-audio-'));
      expect(name, endsWith('My-Lesson-Audio.mp3'));
      expect(name, isNot(contains('/')));
      expect(name, isNot(contains('..')));
    });
  });
}
