import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/categories/domain/entities/category_entity.dart';
import 'package:itun/features/categories/presentation/providers/category_notifier.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/features/lessons/presentation/category_lessons_screen.dart';
import 'package:itun/features/lessons/presentation/providers/lesson_notifier.dart';
import 'package:itun/features/lessons/presentation/providers/lesson_progression_provider.dart';
import 'package:itun/shared/providers/local_settings_provider.dart';
import 'package:itun/shared/providers/purchases_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CategoryNotifier extends CategoryNotifier {
  @override
  AsyncValue<List<CategoryEntity>> build() => const AsyncValue.data([
    CategoryEntity(
      id: 'category_1',
      titleOlChiki: 'Path',
      titleLatin: 'Learning Path',
      totalLessons: 2,
    ),
  ]);

  @override
  Future<void> loadCategories() async {}
  @override
  Future<void> refresh() async {}
  @override
  Future<void> addCategory(CategoryEntity category) async {}
  @override
  Future<void> updateCategory(CategoryEntity category) async {}
  @override
  Future<void> deleteCategory(String id) async {}
  @override
  Future<void> reorderCategories(int oldIndex, int newIndex) async {}
  @override
  Future<void> seed() async {}
}

const _lessons = [
  LessonEntity(
    id: 'lesson_1',
    categoryId: 'category_1',
    titleOlChiki: 'One',
    titleLatin: 'Lesson One',
    order: 1,
  ),
  LessonEntity(
    id: 'lesson_2',
    categoryId: 'category_1',
    titleOlChiki: 'Two',
    titleLatin: 'Lesson Two',
    order: 2,
  ),
];

Future<void> _pumpPath(
  WidgetTester tester, {
  required Set<String> completedLessonIds,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final router = GoRouter(
    initialLocation: '/lessons/category_1',
    routes: [
      GoRoute(
        path: '/lessons/:categoryId',
        builder: (context, state) => CategoryLessonsScreen(
          categoryId: state.pathParameters['categoryId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/lesson/:lessonId',
        builder: (context, state) => Scaffold(
          body: Text('Opened ${state.pathParameters['lessonId']}'),
        ),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        categoryNotifierProvider.overrideWith(_CategoryNotifier.new),
        lessonsByCategoryProvider(
          'category_1',
        ).overrideWith((ref) => const AsyncValue.data(_lessons)),
        completedLessonIdsProvider.overrideWith(
          (ref) => completedLessonIds,
        ),
        purchasedCategoriesProvider.overrideWith((ref) => {'category_1'}),
        effectiveScriptModeProvider.overrideWith((ref) => 'latin'),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('locks later lessons and explains the prerequisite', (
    tester,
  ) async {
    await _pumpPath(tester, completedLessonIds: const {});

    expect(
      find.bySemanticsLabel(
        'Lesson Two. Locked. Complete the previous lesson first.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('lesson-card-lesson_2')));
    await tester.pumpAndSettle();

    expect(
      find.text('Complete “Lesson One” first to unlock this lesson.'),
      findsOneWidget,
    );
    expect(find.text('Opened lesson_2'), findsNothing);
  });

  testWidgets('completed lessons replay and unlock the next lesson', (
    tester,
  ) async {
    await _pumpPath(tester, completedLessonIds: const {'lesson_1'});

    expect(
      find.bySemanticsLabel(
        'Lesson One. Completed. Available to replay.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('lesson-card-lesson_2')));
    await tester.pumpAndSettle();

    expect(find.text('Opened lesson_2'), findsOneWidget);
  });
}
