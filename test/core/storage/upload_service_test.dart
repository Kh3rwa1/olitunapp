import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/storage/upload_service.dart';

void main() {
  group('AppwriteStorageUploadService', () {
    test('maps supported media extensions to Appwrite buckets', () {
      expect(
        AppwriteStorageUploadService.targetForFilename('sound.mp3').bucketId,
        'audio',
      );
      expect(
        AppwriteStorageUploadService.targetForFilename('hero.PNG').bucketId,
        'images',
      );
      expect(
        AppwriteStorageUploadService.targetForFilename('motion.json').bucketId,
        'animations',
      );
      expect(
        AppwriteStorageUploadService.targetForFilename('intro.mov').bucketId,
        'videos',
      );
    });

    test('rejects unsupported file types before upload', () {
      expect(
        () => AppwriteStorageUploadService.targetForFilename('notes.txt'),
        throwsException,
      );
    });

    test(
      'sanitizes logical folder and file names for Appwrite storage names',
      () {
        final name = AppwriteStorageUploadService.storageFilename(
          '../My Lesson Audio.mp3',
          'Letters / Audio',
        );

        expect(name, contains('letters-audio-'));
        expect(name, endsWith('My-Lesson-Audio.mp3'));
        expect(name, isNot(contains('/')));
        expect(name, isNot(contains('..')));
      },
    );
  });
}
