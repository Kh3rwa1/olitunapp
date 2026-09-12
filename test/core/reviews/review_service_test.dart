import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/reviews/review_service.dart';

void main() {
  test('review result types preserve truthful outcomes', () {
    const unavailable = ReviewNotAvailable('Not supported');
    const failed = ReviewFailed('Platform failure');

    expect(const ReviewCompleted(), isA<ReviewResult>());
    expect(const ReviewAlreadyGiven(), isA<ReviewResult>());
    expect(unavailable.reason, 'Not supported');
    expect(failed.error, 'Platform failure');
  });

  test('provider exposes a reusable review service', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(reviewServiceProvider), isA<ReviewService>());
    expect(
      identical(
        container.read(reviewServiceProvider),
        container.read(reviewServiceProvider),
      ),
      isTrue,
    );
  });
}
