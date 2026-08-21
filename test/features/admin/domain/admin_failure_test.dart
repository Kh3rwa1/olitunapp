import 'dart:async';
import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/domain/admin_failure.dart';

void main() {
  group('AdminFailure', () {
    test('maps AppwriteException 404 to AdminNotFoundFailure', () {
      final appwriteErr = AppwriteException(
        'Document not found',
        404,
        'document_not_found',
      );
      final failure = AdminFailure.fromException(appwriteErr);
      expect(failure, isA<AdminNotFoundFailure>());
      expect(failure.isNotFound, isTrue);
      expect(failure.userMessage, contains('was not found'));
    });

    test('maps AppwriteException 401/403 to AdminPermissionFailure', () {
      final appwriteErr = AppwriteException(
        'Unauthorized',
        401,
        'user_unauthorized',
      );
      final failure = AdminFailure.fromException(appwriteErr);
      expect(failure, isA<AdminPermissionFailure>());
      expect(failure.userMessage, contains('do not have permission'));
    });

    test('maps AppwriteException 409 to AdminConflictFailure', () {
      final appwriteErr = AppwriteException(
        'Already exists',
        409,
        'document_already_exists',
      );
      final failure = AdminFailure.fromException(appwriteErr);
      expect(failure, isA<AdminConflictFailure>());
      expect(failure.userMessage, contains('already exists'));
    });

    test('maps AppwriteException 429 to AdminRateLimitFailure', () {
      final appwriteErr = AppwriteException(
        'Rate limit reached',
        429,
        'rate_limit_exceeded',
      );
      final failure = AdminFailure.fromException(appwriteErr);
      expect(failure, isA<AdminRateLimitFailure>());
      expect(failure.isRetryable, isTrue);
    });

    test('maps TimeoutException to AdminTimeoutFailure', () {
      final timeoutErr = TimeoutException('Connection timed out');
      final failure = AdminFailure.fromException(timeoutErr);
      expect(failure, isA<AdminTimeoutFailure>());
      expect(failure.isRetryable, isTrue);
    });

    test('maps SocketException to AdminNetworkFailure', () {
      const socketErr = SocketException('No internet');
      final failure = AdminFailure.fromException(socketErr);
      expect(failure, isA<AdminNetworkFailure>());
      expect(failure.isRetryable, isTrue);
    });

    test('redacts sensitive API keys and secrets in sanitizedDetails', () {
      const failure = AdminServerFailure(
        'Server failed',
        technicalDetails:
            'Failed connecting to Razorpay with key rzp_live_9876543210 and Bearer eyJhbGciOi...',
      );
      expect(failure.sanitizedDetails, contains('rzp_***'));
      expect(failure.sanitizedDetails, contains('Bearer ***'));
      expect(failure.sanitizedDetails, isNot(contains('9876543210')));
    });
  });
}
