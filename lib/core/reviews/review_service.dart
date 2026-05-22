import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import '../logging/app_logger.dart';

sealed class ReviewResult {
  const ReviewResult();
}

class ReviewCompleted extends ReviewResult {
  const ReviewCompleted();
}

class ReviewNotAvailable extends ReviewResult {
  final String reason;
  const ReviewNotAvailable(this.reason);
}

class ReviewAlreadyGiven extends ReviewResult {
  const ReviewAlreadyGiven();
}

class ReviewFailed extends ReviewResult {
  final String error;
  const ReviewFailed(this.error);
}

class ReviewService {
  final InAppReview _inAppReview = InAppReview.instance;

  Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    try {
      return await _inAppReview.isAvailable();
    } catch (e) {
      AppLogger.debug('Error checking in-app review availability: $e');
      return false;
    }
  }

  Future<ReviewResult> requestReview() async {
    if (kIsWeb) {
      return const ReviewNotAvailable(
        'In-app reviews are not supported on web.',
      );
    }

    try {
      final available = await _inAppReview.isAvailable();
      if (!available) {
        return const ReviewNotAvailable(
          'In-app reviews are currently not available on this device.',
        );
      }

      await _inAppReview.requestReview();
      // Since requestReview does not return a value (it returns Future<void>),
      // we assume the platform attempted to show the dialog successfully.
      return const ReviewCompleted();
    } catch (e) {
      AppLogger.debug('In-app review request failed: $e');
      return ReviewFailed(e.toString());
    }
  }

  Future<void> openStoreListing() async {
    if (kIsWeb) return;
    try {
      await _inAppReview.openStoreListing();
    } catch (e) {
      AppLogger.debug('Error opening store listing: $e');
    }
  }
}

final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService();
});
