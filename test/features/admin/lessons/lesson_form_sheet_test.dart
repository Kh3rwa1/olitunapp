import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/features/admin/presentation/lessons/widgets/lesson_form_sheet.dart';
import 'package:itun/features/categories/domain/entities/category_entity.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/shared/providers/providers.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockContentRepository extends Mock implements ContentRepository {}

class _FakeCategoryNotifier extends CategoryNotifier {
  @override
  AsyncValue<List<CategoryEntity>> build() => const AsyncValue.data([]);
}

LessonEntity _lesson() => const LessonEntity(
  id: 'lesson_1',
  categoryId: 'cat_1',
  titleOlChiki: 'ᱪᱮᱫᱼᱟᱢ',
  titleLatin: 'Colors',
  blocks: [LessonBlockEntity(type: 'text', textLatin: 'Red')],
);

Future<void> pumpOpener(
  WidgetTester tester, {
  List<Override> overrides = const [],
  required WidgetBuilder sheetBuilder,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        categoryNotifierProvider.overrideWith(_FakeCategoryNotifier.new),
        ...overrides,
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: sheetBuilder,
                ),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('OPEN'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  late MockContentRepository repo;

  setUp(() {
    repo = MockContentRepository();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('new lesson path shows the New Subcategory sheet', (
    tester,
  ) async {
    await pumpOpener(tester, sheetBuilder: (_) => const LessonFormSheet());

    expect(find.text('New Subcategory'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });

  testWidgets('edit path loads the stored content item for the lesson', (
    tester,
  ) async {
    final stored = ContentItem(
      id: 'lesson_1',
      kind: ContentKind.lesson,
      categoryId: 'cat_1',
      title: 'Colors',
      titleOlChiki: 'ᱪᱮᱫᱼᱟᱢ',
      subtitle: 'Learn colors',
      blocks: const [],
      updatedAt: DateTime(2026),
    );
    when(
      () => repo.get(ContentKind.lesson, 'lesson_1'),
    ).thenAnswer((_) async => Right(stored));

    await pumpOpener(
      tester,
      overrides: [contentRepositoryProvider.overrideWithValue(repo)],
      sheetBuilder: (_) => LessonFormSheet(lesson: _lesson()),
    );

    expect(find.text('Edit Subcategory'), findsOneWidget);
    verify(() => repo.get(ContentKind.lesson, 'lesson_1')).called(1);
  });

  testWidgets('edit path falls back to legacy synthesis on repo failure', (
    tester,
  ) async {
    when(
      () => repo.get(ContentKind.lesson, 'lesson_1'),
    ).thenAnswer((_) async => const Left(ServerFailure(message: 'offline')));

    await pumpOpener(
      tester,
      overrides: [contentRepositoryProvider.overrideWithValue(repo)],
      sheetBuilder: (_) => LessonFormSheet(lesson: _lesson()),
    );

    expect(find.text('Edit Subcategory'), findsOneWidget);
  });

  testWidgets('close button pops the sheet', (tester) async {
    await pumpOpener(tester, sheetBuilder: (_) => const LessonFormSheet());

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('New Subcategory'), findsNothing);
  });
}
