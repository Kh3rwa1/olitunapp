import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/storage/upload_rules.dart';

void main() {
  group('UploadRules.validate', () {
    test('accepts valid image', () {
      final err = UploadRules.validate(
        filename: 'photo.png',
        sizeBytes: 1024,
        category: UploadCategory.image,
      );
      expect(err, isNull);
    });

    test('rejects empty filename', () {
      final err = UploadRules.validate(
        filename: '',
        sizeBytes: 1024,
        category: UploadCategory.image,
      );
      expect(err, contains('empty'));
    });

    test('rejects unsupported extension', () {
      final err = UploadRules.validate(
        filename: 'virus.exe',
        sizeBytes: 1024,
        category: UploadCategory.image,
      );
      expect(err, contains('Unsupported'));
    });

    test('rejects empty file', () {
      final err = UploadRules.validate(
        filename: 'photo.png',
        sizeBytes: 0,
        category: UploadCategory.image,
      );
      expect(err, contains('empty'));
    });

    test('rejects oversized image', () {
      final err = UploadRules.validate(
        filename: 'huge.jpg',
        sizeBytes: 10 * 1024 * 1024,
        category: UploadCategory.image,
      );
      expect(err, contains('too large'));
    });

    test('accepts valid audio', () {
      final err = UploadRules.validate(
        filename: 'pronunciation.mp3',
        sizeBytes: 5 * 1024 * 1024,
        category: UploadCategory.audio,
      );
      expect(err, isNull);
    });

    test('rejects oversized audio', () {
      final err = UploadRules.validate(
        filename: 'huge.mp3',
        sizeBytes: 25 * 1024 * 1024,
        category: UploadCategory.audio,
      );
      expect(err, contains('too large'));
    });

    test('accepts valid animation', () {
      final err = UploadRules.validate(
        filename: 'anim.json',
        sizeBytes: 500 * 1024,
        category: UploadCategory.animation,
      );
      expect(err, isNull);
    });

    test('rejects oversized animation', () {
      final err = UploadRules.validate(
        filename: 'big.json',
        sizeBytes: 3 * 1024 * 1024,
        category: UploadCategory.animation,
      );
      expect(err, contains('too large'));
    });

    test('accepts valid video', () {
      final err = UploadRules.validate(
        filename: 'lesson.mp4',
        sizeBytes: 10 * 1024 * 1024,
        category: UploadCategory.video,
      );
      expect(err, isNull);
    });
  });

  group('UploadRules.sanitizeFilename', () {
    test('strips path separators', () {
      expect(UploadRules.sanitizeFilename('/foo/bar/baz.png'), 'baz.png');
    });

    test('replaces unsafe characters', () {
      expect(
        UploadRules.sanitizeFilename('hello world!.jpg'),
        'hello-world-.jpg',
      );
    });

    test('empty filename returns fallback', () {
      expect(UploadRules.sanitizeFilename(''), 'upload');
    });
  });

  group('UploadRules.shouldCompress', () {
    test('png should compress', () {
      expect(UploadRules.shouldCompress('photo.png'), true);
    });

    test('jpg should compress', () {
      expect(UploadRules.shouldCompress('photo.jpg'), true);
    });

    test('svg should NOT compress', () {
      expect(UploadRules.shouldCompress('icon.svg'), false);
    });

    test('json should NOT compress', () {
      expect(UploadRules.shouldCompress('anim.json'), false);
    });
  });

  group('UploadRules.recommendedQuality', () {
    test('large files get lower quality', () {
      expect(UploadRules.recommendedQuality(4 * 1024 * 1024), 70);
    });

    test('medium files get medium quality', () {
      expect(UploadRules.recommendedQuality(2 * 1024 * 1024), 80);
    });

    test('small files get high quality', () {
      expect(UploadRules.recommendedQuality(500 * 1024), 90);
    });
  });
}
