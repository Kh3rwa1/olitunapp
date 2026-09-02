import 'package:appwrite/appwrite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/error/appwrite_error_classifier.dart';

void main() {
  group('AppwriteErrorClassifier.infoOf', () {
    test('extracts code, type and message from an AppwriteException', () {
      final error = AppwriteException(
        'User already exists',
        409,
        'user_already_exists',
      );

      final info = AppwriteErrorClassifier.infoOf(error);

      expect(info, isNotNull);
      expect(info!.code, 409);
      expect(info.type, 'user_already_exists');
      expect(info.message, 'User already exists');
    });

    test('defaults null classification fields to zero/empty', () {
      final error = AppwriteException('boom');

      final info = AppwriteErrorClassifier.infoOf(error);

      expect(info, isNotNull);
      expect(info!.code, 0);
      expect(info.type, '');
      expect(info.message, 'boom');
    });

    test('returns null for non-Appwrite errors', () {
      expect(AppwriteErrorClassifier.infoOf(Exception('nope')), isNull);
      expect(AppwriteErrorClassifier.infoOf('a string'), isNull);
      expect(AppwriteErrorClassifier.infoOf(StateError('state')), isNull);
    });
  });
}
