import 'package:flutter_test/flutter_test.dart';
import 'package:itun/shared/models/content_item.dart';

ContentItem item({
  required ContentKind kind,
  bool isPremium = false,
}) => ContentItem(
  id: 'content-1',
  kind: kind,
  categoryId: 'category-1',
  title: 'Content',
  blocks: const [],
  isPremium: isPremium,
  updatedAt: DateTime(2026, 9, 5),
);

void main() {
  group('generic Appwrite publication guard', () {
    test('rejects every lesson because category policy is unavailable', () {
      expect(
        () => item(kind: ContentKind.lesson).toAppwrite(),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects explicitly premium non-lesson content', () {
      expect(
        () => item(kind: ContentKind.rhyme, isPremium: true).toAppwrite(),
        throwsA(isA<StateError>()),
      );
    });

    test('preserves generic publication for free non-lesson content', () {
      expect(
        item(kind: ContentKind.rhyme).toAppwrite(),
        isA<Map<String, dynamic>>(),
      );
    });
  });
}
