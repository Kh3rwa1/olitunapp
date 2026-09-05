import 'package:flutter_test/flutter_test.dart';
import 'package:itun/shared/models/content_item.dart';

ContentItem item({required ContentKind kind, bool isPremium = false}) =>
    ContentItem(
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

    test('lesson local/cache serialization remains available', () {
      final serialized = item(kind: ContentKind.lesson).toJson();
      expect(serialized['kind'], ContentKind.lesson.name);
      expect(serialized['categoryId'], 'category-1');
    });

    test('rejects explicitly premium non-lesson content', () {
      expect(
        () => item(kind: ContentKind.rhyme, isPremium: true).toAppwrite(),
        throwsA(isA<StateError>()),
      );
    });

    test('preserves generic publication for free unrelated serializers', () {
      for (final kind in [
        ContentKind.letter,
        ContentKind.number,
        ContentKind.word,
        ContentKind.sentence,
        ContentKind.rhyme,
      ]) {
        expect(
          item(kind: kind).toAppwrite(),
          isA<Map<String, dynamic>>(),
          reason: '${kind.name} free serialization must remain available',
        );
      }
    });
  });
}
