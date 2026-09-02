import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/presentation/lessons/widgets/lesson_card.dart';
import 'package:itun/features/categories/domain/entities/category_entity.dart';
import 'package:itun/features/categories/presentation/providers/category_notifier.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';

class _FakeCategoryNotifier extends CategoryNotifier {
  @override
  AsyncValue<List<CategoryEntity>> build() => const AsyncValue.data([]);
}

LessonEntity _lesson({
  String categoryId = 'cat_1',
  List<LessonBlockEntity>? blocks,
}) => LessonEntity(
  id: 'lesson_1',
  categoryId: categoryId,
  titleOlChiki: 'ᱪᱮᱫᱼᱟᱢ',
  titleLatin: 'Colors',
  blocks: blocks ?? const [LessonBlockEntity(type: 'text')],
);

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    required LessonEntity lesson,
    required bool isDark,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryNotifierProvider.overrideWith(_FakeCategoryNotifier.new),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 700,
              child: LessonCard(
                lesson: lesson,
                isDark: isDark,
                onEdit: onEdit ?? () {},
                onDelete: onDelete ?? () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders title, category badge, and metadata chips', (
    tester,
  ) async {
    await pumpCard(tester, lesson: _lesson(), isDark: false);

    expect(find.text('Colors'), findsOneWidget);
    expect(find.text('ᱪᱮᱫᱼᱟᱢ'), findsOneWidget);
    expect(find.text('UNCATEGORIZED'), findsOneWidget);
    expect(find.text('1 block'), findsOneWidget);
    expect(find.text('5 min'), findsOneWidget);
  });

  testWidgets('shows Hidden chip and pluralized block count', (tester) async {
    await pumpCard(
      tester,
      lesson: const LessonEntity(
        id: 'lesson_2',
        categoryId: 'cat_x',
        titleOlChiki: 'ᱛᱤᱱ',
        titleLatin: 'Numbers',
        isActive: false,
        blocks: [
          LessonBlockEntity(type: 'text'),
          LessonBlockEntity(type: 'audio'),
        ],
      ),
      isDark: true,
    );

    expect(find.text('Hidden'), findsOneWidget);
    expect(find.text('2 blocks'), findsOneWidget);
  });

  testWidgets('falls back to Ol Chiki title when latin title is empty', (
    tester,
  ) async {
    await pumpCard(
      tester,
      lesson: const LessonEntity(
        id: 'lesson_3',
        categoryId: 'cat_x',
        titleOlChiki: 'ᱪᱮᱫᱼᱟᱢ',
        titleLatin: '',
      ),
      isDark: false,
    );

    expect(find.text('ᱪᱮᱫᱼᱟᱢ'), findsOneWidget);
  });

  testWidgets('Edit Details triggers onEdit without routing', (tester) async {
    var edited = false;
    await pumpCard(
      tester,
      lesson: _lesson(),
      isDark: false,
      onEdit: () => edited = true,
    );

    await tester.tap(find.byIcon(Icons.edit_note_rounded));
    expect(edited, isTrue);
  });

  testWidgets('Delete button triggers onDelete', (tester) async {
    var deleted = false;
    await pumpCard(
      tester,
      lesson: _lesson(),
      isDark: false,
      onDelete: () => deleted = true,
    );

    await tester.tap(find.text('Delete'));
    expect(deleted, isTrue);
  });
}
