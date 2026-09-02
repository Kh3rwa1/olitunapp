import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/categories/domain/entities/category_entity.dart';
import 'package:itun/features/categories/presentation/providers/category_notifier.dart';
import 'package:itun/features/lessons/presentation/lessons_screen.dart';
import 'package:itun/features/lessons/presentation/widgets/bento_category_card.dart';
import 'package:itun/features/lessons/presentation/widgets/hero_category_card.dart';
import 'package:itun/shared/providers/local_settings_provider.dart';

class MockCategoryNotifier extends CategoryNotifier {
  final List<CategoryEntity> _initial;

  MockCategoryNotifier(this._initial);

  @override
  AsyncValue<List<CategoryEntity>> build() => AsyncValue.data(_initial);

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

class ErroringCategoryNotifier extends CategoryNotifier {
  @override
  AsyncValue<List<CategoryEntity>> build() =>
      AsyncValue.error(StateError('boom'), StackTrace.current);

  @override
  Future<void> loadCategories() async {}
  @override
  Future<void> refresh() async {}
}

GoRouter _router() => GoRouter(
  initialLocation: '/lessons',
  routes: [
    GoRoute(
      path: '/lessons',
      builder: (context, state) => const LessonsScreen(),
    ),
    GoRoute(
      path: '/lessons/:categoryId',
      builder: (context, state) =>
          Text('category:${state.pathParameters['categoryId']}'),
    ),
    GoRoute(
      path: '/letter/standalone/:subcategoryId',
      builder: (context, state) =>
          Text('letters:${state.pathParameters['subcategoryId']}'),
    ),
    GoRoute(path: '/', builder: (context, state) => const Text('home')),
  ],
);

Future<void> pumpScreen(
  WidgetTester tester,
  List<CategoryEntity> categories, {
  CategoryNotifier Function()? notifierBuilder,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        reduceVisualEffectsProvider.overrideWithValue(true),
        if (notifierBuilder != null)
          categoryNotifierProvider.overrideWith(notifierBuilder)
        else
          categoryNotifierProvider.overrideWith(
            () => MockCategoryNotifier(categories),
          ),
      ],
      child: MaterialApp.router(routerConfig: _router()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  const categories = [
    CategoryEntity(
      id: 'cat_numbers',
      titleOlChiki: 'ᱞᱮᱠᱷᱟ',
      titleLatin: 'Numbers',
      iconName: 'numbers',
    ),
    CategoryEntity(
      id: 'cat_words',
      titleOlChiki: 'ᱟᱹᱲᱤ',
      titleLatin: 'Words',
      iconName: 'words',
    ),
    CategoryEntity(
      id: 'cat_stories',
      titleOlChiki: 'ᱠᱟᱹᱦᱱᱤ',
      titleLatin: 'Stories',
      iconName: 'stories',
    ),
  ];

  testWidgets('renders header and hero card for the first category', (
    tester,
  ) async {
    await pumpScreen(tester, categories);

    expect(find.text('LEARNING PATHS'), findsOneWidget);
    expect(find.text('Choose Your Journey'), findsOneWidget);
    expect(find.byType(HeroCategoryCard), findsOneWidget);
    expect(find.text('Numbers'), findsOneWidget);
    expect(find.text('MORE PATHS'), findsOneWidget);
    expect(find.byType(BentoCategoryCard), findsNWidgets(2));
  });

  testWidgets('hides the bento grid section when only one category exists', (
    tester,
  ) async {
    await pumpScreen(tester, categories.sublist(0, 1));

    expect(find.byType(HeroCategoryCard), findsOneWidget);
    expect(find.text('MORE PATHS'), findsNothing);
    expect(find.byType(BentoCategoryCard), findsNothing);
  });

  testWidgets('tapping the hero category navigates to its lesson list', (
    tester,
  ) async {
    await pumpScreen(tester, categories);

    await tester.tap(find.text('Numbers'));
    await tester.pumpAndSettle();

    expect(find.text('category:cat_numbers'), findsOneWidget);
  });

  testWidgets('alphabet hero categories route to the standalone letter grid', (
    tester,
  ) async {
    await pumpScreen(tester, [
      const CategoryEntity(
        id: 'cat_alphabets',
        titleOlChiki: 'ᱚᱞ ᱪᱤᱠᱤ',
        titleLatin: 'Alphabets',
      ),
    ]);

    await tester.tap(find.text('Alphabets'));
    await tester.pumpAndSettle();

    expect(find.text('letters:all'), findsOneWidget);
  });

  testWidgets('shows the error state when categories fail to load', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const [],
      notifierBuilder: ErroringCategoryNotifier.new,
    );

    expect(find.text('Could not load lessons'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
  });
}
