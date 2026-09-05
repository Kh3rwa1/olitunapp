import 'package:flutter_test/flutter_test.dart';
import 'package:itun/shared/security/premium_content_policy.dart';

void main() {
  group('PremiumContentPolicy', () {
    test('keeps a resolved free category public', () {
      final decision = PremiumContentPolicy.forContentItem(
        isPremium: false,
        categoryUnlockMode: 'free',
      );
      expect(decision.allowAnonymousRead, isTrue);
      expect(decision.reason, 'free-category');
    });

    test('never publishes an explicitly premium item anonymously', () {
      final decision = PremiumContentPolicy.forContentItem(
        isPremium: true,
        categoryUnlockMode: 'free',
      );
      expect(decision.allowAnonymousRead, isFalse);
    });

    test('fails closed when category lookup did not complete', () {
      final decision = PremiumContentPolicy.forContentItem(
        isPremium: false,
        categoryResolved: false,
      );
      expect(decision.allowAnonymousRead, isFalse);
      expect(decision.reason, 'category-unresolved');
    });

    test('fails closed for missing and unknown unlock modes', () {
      expect(
        PremiumContentPolicy.forContentItem(
          isPremium: false,
          categoryUnlockMode: null,
        ).allowAnonymousRead,
        isFalse,
      );
      expect(
        PremiumContentPolicy.forContentItem(
          isPremium: false,
          categoryUnlockMode: 'future_mode',
        ).allowAnonymousRead,
        isFalse,
      );
    });

    test('only configured positive-order previews remain public', () {
      expect(
        PremiumContentPolicy.forContentItem(
          isPremium: false,
          categoryUnlockMode: 'paid_only',
          lessonOrder: 2,
          previewLessonCount: 3,
        ).allowAnonymousRead,
        isTrue,
      );
      expect(
        PremiumContentPolicy.forContentItem(
          isPremium: false,
          categoryUnlockMode: 'paid_only',
          lessonOrder: 4,
          previewLessonCount: 3,
        ).allowAnonymousRead,
        isFalse,
      );
      expect(
        PremiumContentPolicy.forContentItem(
          isPremium: false,
          categoryUnlockMode: 'paid_only',
          lessonOrder: 0,
          previewLessonCount: 3,
        ).allowAnonymousRead,
        isFalse,
      );
    });
  });
}
