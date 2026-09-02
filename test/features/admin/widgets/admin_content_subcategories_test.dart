import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/categories/domain/entities/category_entity.dart';
import 'package:itun/features/admin/presentation/widgets/admin_content_subcategories.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';

CategoryEntity _category(String id, String title) =>
    CategoryEntity(id: id, titleLatin: title, titleOlChiki: 'ᱛᱚᱨᱡᱚᱢᱟ');

LessonEntity _lesson(
  String id,
  String title, {
  int order = 0,
  String categoryId = 'cat_vocab',
}) => LessonEntity(
  id: id,
  categoryId: categoryId,
  titleOlChiki: 'ᱪᱮᱫᱼᱟᱢ',
  titleLatin: title,
  order: order,
  blocks: const [LessonBlockEntity(type: 'text')],
);

void main() {
  group('findAdminContentCategory', () {
    test('matches well-known vocabulary ids before titles', () {
      final categories = [
        _category('cat_other', 'Vocabulary'),
        _category('cat_vocab', 'Words'),
      ];
      final found = findAdminContentCategory(
        categories,
        AdminContentKind.vocabulary,
      );
      expect(found?.id, 'cat_vocab');
    });

    test('falls back to a title match for sentences', () {
      final categories = [_category('custom_1', 'Sentences')];
      final found = findAdminContentCategory(
        categories,
        AdminContentKind.sentences,
      );
      expect(found?.id, 'custom_1');
    });

    test('returns null when nothing matches', () {
      final found = findAdminContentCategory([
        _category('x', 'Letters'),
      ], AdminContentKind.vocabulary);
      expect(found, isNull);
    });
  });

  group('filterAdminContentLessons', () {
    test('keeps only lessons from candidate categories, sorted', () {
      final lessons = [
        _lesson('b', 'Banana', order: 2),
        _lesson('a', 'Apple', order: 2),
        _lesson('c', 'Cherry', order: 1),
        _lesson('z', 'Other', categoryId: 'cat_other'),
      ];
      final filtered = filterAdminContentLessons(
        lessons,
        null,
        AdminContentKind.vocabulary,
      );
      expect(filtered.map((l) => l.id), ['c', 'a', 'b']);
    });

    test('uses standard alias sets for standard categories', () {
      final lessons = [
        _lesson('v', 'Vocab lesson'),
        _lesson('s', 'Sentence lesson', categoryId: 'cat_sentences'),
      ];
      final vocab = filterAdminContentLessons(
        lessons,
        _category('seed_words', 'Words'),
        AdminContentKind.vocabulary,
      );
      expect(vocab.map((l) => l.id), ['v']);
    });
  });

  group('adminContentCategorySuggestions', () {
    test('merges categories and lesson titles, case-insensitively sorted', () {
      final suggestions = adminContentCategorySuggestions(
        existingCategories: const ['Greetings', null, '  '],
        lessons: [_lesson('1', 'apple'), _lesson('2', 'Banana')],
      );
      expect(suggestions, ['apple', 'Banana', 'Greetings']);
    });
  });

  group('AdminContentSubcategories widget', () {
    Future<void> pumpWidget_(
      WidgetTester tester, {
      required List<LessonEntity> lessons,
      VoidCallback? onAdd,
      VoidCallback? onSeed,
      ValueChanged<LessonEntity>? onEdit,
      ValueChanged<LessonEntity>? onDelete,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(0.5)),
            child: child!,
          ),
          home: Scaffold(
            body: SizedBox(
              width: 900,
              height: 400,
              child: AdminContentSubcategories(
                title: 'Vocabulary Sections',
                subtitle: 'Group words into teachable sections',
                emptyTitle: 'No sections yet',
                emptyMessage: 'Seed default data to begin.',
                lessons: lessons,
                isDark: false,
                onAdd: onAdd ?? () {},
                onSeed: onSeed ?? () {},
                onEdit: onEdit ?? (_) {},
                onDelete: onDelete ?? (_) {},
                showContentEditor: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders lesson cards with meta chips and actions', (
      tester,
    ) async {
      await pumpWidget_(tester, lessons: [_lesson('1', 'Greetings')]);

      expect(find.text('Vocabulary Sections'), findsOneWidget);
      expect(find.text('Greetings'), findsOneWidget);
      expect(find.text('Order 0'), findsOneWidget);
      expect(find.text('1 blocks'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.byType(AdminContentSubcategories), findsOneWidget);
    });

    testWidgets('empty lessons show the seed state and seed tap works', (
      tester,
    ) async {
      var seeded = false;
      await pumpWidget_(tester, lessons: const [], onSeed: () => seeded = true);

      expect(find.text('No sections yet'), findsOneWidget);
      expect(find.text('Seed Default Data'), findsOneWidget);
      await tester.tap(find.text('Seed Default Data'));
      expect(seeded, isTrue);
    });

    testWidgets('hovering a card reveals edit and delete actions', (
      tester,
    ) async {
      final deleted = <String>[];
      await pumpWidget_(
        tester,
        lessons: [_lesson('1', 'Greetings')],
        onDelete: (lesson) => deleted.add(lesson.id),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.text('Greetings')));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      expect(deleted, ['1']);
    });
  });
}
