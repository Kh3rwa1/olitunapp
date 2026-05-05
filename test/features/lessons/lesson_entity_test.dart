import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';

void main() {
  group('LessonEntity', () {
    test('creates with required fields and defaults', () {
      const lesson = LessonEntity(
        id: 'l1',
        categoryId: 'alphabets',
        titleOlChiki: 'ᱚᱠᱷᱚᱨ',
        titleLatin: 'Vowels',
      );

      expect(lesson.order, 0);
      expect(lesson.estimatedMinutes, 5);
      expect(lesson.isActive, isTrue);
      expect(lesson.blocks, isEmpty);
      expect(lesson.data, isNull);
      expect(lesson.description, isNull);
    });

    test('copyWith preserves unchanged fields', () {
      const original = LessonEntity(
        id: 'l1',
        categoryId: 'alphabets',
        titleOlChiki: 'ᱚᱠᱷᱚᱨ',
        titleLatin: 'Vowels',
        order: 5,
        estimatedMinutes: 15,
      );

      final copy = original.copyWith(titleLatin: 'Updated Vowels');

      expect(copy.id, 'l1');
      expect(copy.categoryId, 'alphabets');
      expect(copy.titleOlChiki, 'ᱚᱠᱷᱚᱨ');
      expect(copy.titleLatin, 'Updated Vowels');
      expect(copy.order, 5);
      expect(copy.estimatedMinutes, 15);
    });

    test('equatable considers all props', () {
      const a = LessonEntity(
        id: 'l1',
        categoryId: 'alphabets',
        titleOlChiki: 'ᱚ',
        titleLatin: 'Vowels',
      );
      const b = LessonEntity(
        id: 'l1',
        categoryId: 'alphabets',
        titleOlChiki: 'ᱚ',
        titleLatin: 'Vowels',
      );
      const c = LessonEntity(
        id: 'l2',
        categoryId: 'alphabets',
        titleOlChiki: 'ᱚ',
        titleLatin: 'Vowels',
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('blocks are part of equality', () {
      const withBlocks = LessonEntity(
        id: 'l1',
        categoryId: 'alphabets',
        titleOlChiki: 'ᱚ',
        titleLatin: 'Vowels',
        blocks: [LessonBlockEntity(type: 'text', textOlChiki: 'hello')],
      );
      const withoutBlocks = LessonEntity(
        id: 'l1',
        categoryId: 'alphabets',
        titleOlChiki: 'ᱚ',
        titleLatin: 'Vowels',
      );

      expect(withBlocks, isNot(equals(withoutBlocks)));
    });
  });

  group('LessonBlockEntity', () {
    test('creates with required type', () {
      const block = LessonBlockEntity(type: 'text');
      expect(block.type, 'text');
      expect(block.textOlChiki, isNull);
      expect(block.textLatin, isNull);
      expect(block.imageUrl, isNull);
      expect(block.audioUrl, isNull);
    });

    test('equatable compares all fields', () {
      const a = LessonBlockEntity(
        type: 'image',
        imageUrl: 'https://example.com/img.png',
      );
      const b = LessonBlockEntity(
        type: 'image',
        imageUrl: 'https://example.com/img.png',
      );
      const c = LessonBlockEntity(
        type: 'image',
        imageUrl: 'https://example.com/other.png',
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
