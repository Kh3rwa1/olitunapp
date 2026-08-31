import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/content/domain/entities/localized_content_entity.dart';

void main() {
  group('ReviewStatus', () {
    test('fromName parses all known statuses', () {
      expect(ReviewStatus.fromName('draft'), ReviewStatus.draft);
      expect(ReviewStatus.fromName('generated'), ReviewStatus.generated);
      expect(ReviewStatus.fromName('needsReview'), ReviewStatus.needsReview);
      expect(ReviewStatus.fromName('approved'), ReviewStatus.approved);
      expect(ReviewStatus.fromName('rejected'), ReviewStatus.rejected);
    });

    test('fromName falls back to needsReview for unknown or null', () {
      // Unknown values must never resolve to approved.
      expect(ReviewStatus.fromName('unknown'), ReviewStatus.needsReview);
      expect(ReviewStatus.fromName(null), ReviewStatus.needsReview);
      expect(ReviewStatus.fromName(''), ReviewStatus.needsReview);
    });
  });

  group('LocalizedContent', () {
    test('creates with defaults', () {
      const content = LocalizedContent(
        id: 'lc1',
        contentKind: 'word',
        contentId: 'w1',
        languageCode: 'hi',
      );

      expect(content.meaning, isNull);
      expect(content.reviewStatus, ReviewStatus.draft);
      expect(content.reviewedBy, isNull);
      expect(content.reviewedAt, isNull);
      expect(content.version, 1);
      expect(content.isApproved, isFalse);
    });

    test('isApproved only true for approved status', () {
      for (final status in ReviewStatus.values) {
        final content = LocalizedContent(
          id: 'lc1',
          contentKind: 'word',
          contentId: 'w1',
          languageCode: 'hi',
          reviewStatus: status,
        );
        expect(content.isApproved, status == ReviewStatus.approved);
      }
    });

    test('meaningOrEmpty trims empty meaning to null', () {
      const blank = LocalizedContent(
        id: 'lc1',
        contentKind: 'word',
        contentId: 'w1',
        languageCode: 'hi',
        meaning: '',
      );
      const filled = LocalizedContent(
        id: 'lc2',
        contentKind: 'word',
        contentId: 'w1',
        languageCode: 'hi',
        meaning: 'नमस्ते',
      );

      expect(blank.meaningOrEmpty, isNull);
      expect(filled.meaningOrEmpty, 'नमस्ते');
    });

    test('copyWith preserves unchanged fields', () {
      const original = LocalizedContent(
        id: 'lc1',
        contentKind: 'word',
        contentId: 'w1',
        languageCode: 'hi',
        meaning: 'पुलाव',
        explanation: 'सामान्य अभिवादन',
        reviewStatus: ReviewStatus.needsReview,
        version: 2,
      );

      final copy = original.copyWith(
        reviewStatus: ReviewStatus.approved,
        reviewedBy: 'admin-user',
      );

      expect(copy.id, 'lc1');
      expect(copy.contentKind, 'word');
      expect(copy.contentId, 'w1');
      expect(copy.languageCode, 'hi');
      expect(copy.meaning, 'पुलाव');
      expect(copy.explanation, 'सामान्य अभिवादन');
      expect(copy.reviewStatus, ReviewStatus.approved);
      expect(copy.reviewedBy, 'admin-user');
      expect(copy.version, 2);
      expect(copy.isApproved, isTrue);
    });

    test('equality via props', () {
      const a = LocalizedContent(
        id: 'lc1',
        contentKind: 'word',
        contentId: 'w1',
        languageCode: 'hi',
        meaning: 'जोहार',
      );
      const b = LocalizedContent(
        id: 'lc1',
        contentKind: 'word',
        contentId: 'w1',
        languageCode: 'hi',
        meaning: 'जोहार',
      );
      final c = a.copyWith(meaning: 'अलग');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });
  });
}
