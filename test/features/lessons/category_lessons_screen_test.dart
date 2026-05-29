import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/features/lessons/presentation/category_lessons_screen.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/features/categories/domain/entities/category_entity.dart';
import 'package:itun/features/categories/presentation/providers/category_notifier.dart';
import 'package:itun/features/lessons/presentation/providers/lesson_notifier.dart';
import 'package:itun/shared/providers/purchases_provider.dart';
import 'package:itun/shared/providers/local_settings_provider.dart';
import 'package:itun/core/storage/hive_service.dart';

class MockCategoryNotifier
    extends StateNotifier<AsyncValue<List<CategoryEntity>>>
    implements CategoryNotifier {
  MockCategoryNotifier(List<CategoryEntity> initial)
    : super(AsyncValue.data(initial));
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

void main() {
  const mockAlphabetCategory = CategoryEntity(
    id: 'cat_alphabets',
    titleOlChiki: 'ᱚᱞ ᱪᱤᱠᱤ',
    titleLatin: 'Alphabets',
    totalLessons: 1,
  );

  const mockNumberCategory = CategoryEntity(
    id: 'cat_numbers',
    titleOlChiki: 'ᱞᱮᱠᱷᱟ',
    titleLatin: 'Numbers',
    gradientPreset: 'peach',
    totalLessons: 1,
  );

  final mockLessons = [
    const LessonEntity(
      id: 'lesson_vowels_1',
      categoryId: 'cat_alphabets',
      titleOlChiki: 'Vowels I',
      titleLatin: 'Vowels I',
    ),
  ];

  final mockNumberLessons = [
    const LessonEntity(
      id: 'lesson_numbers_1',
      categoryId: 'cat_numbers',
      titleOlChiki: 'Lekha 1',
      titleLatin: 'Numbers 1-5',
    ),
  ];

  testWidgets(
    'CategoryLessonsScreen displays Ol Chiki Browse All card and routes correctly for Alphabets',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final router = GoRouter(
        initialLocation: '/lessons/cat_alphabets',
        routes: [
          GoRoute(
            path: '/lessons/:categoryId',
            builder: (context, state) => CategoryLessonsScreen(
              categoryId: state.pathParameters['categoryId'] ?? '',
            ),
          ),
          GoRoute(
            path: '/letter/standalone/:subcategoryId',
            builder: (context, state) => Scaffold(
              body: Text(
                'Standalone Letter Grid: ${state.pathParameters['subcategoryId']}',
              ),
            ),
          ),
          GoRoute(
            path: '/lesson/:lessonId',
            builder: (context, state) => Scaffold(
              body: Text(
                'Lesson Carousel: ${state.pathParameters['lessonId']}',
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            categoryNotifierProvider.overrideWith(
              (ref) => MockCategoryNotifier([mockAlphabetCategory]),
            ),
            lessonsByCategoryProvider(
              'cat_alphabets',
            ).overrideWith((ref) => AsyncValue.data(mockLessons)),
            purchasedCategoriesProvider.overrideWith(
              (ref) => {'cat_alphabets'},
            ),
            effectiveScriptModeProvider.overrideWith((ref) => 'latin'),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Assert that "Ol Chiki" Browse All card appears at the top
      expect(find.text('Ol Chiki'), findsOneWidget);
      expect(
        find.text('Explore the complete grid dictionary of all letters'),
        findsOneWidget,
      );

      // Assert that "Vowels I" lesson card appears below it
      expect(find.text('Vowels I'), findsOneWidget);

      // Tap the "Ol Chiki" card
      await tester.tap(find.text('Ol Chiki'));
      await tester.pumpAndSettle();

      // Assert navigation to standalone letter grid all
      expect(find.text('Standalone Letter Grid: all'), findsOneWidget);
    },
  );

  testWidgets(
    'CategoryLessonsScreen displays Lekha Browse All card and routes correctly for Numbers',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final router = GoRouter(
        initialLocation: '/lessons/cat_numbers',
        routes: [
          GoRoute(
            path: '/lessons/:categoryId',
            builder: (context, state) => CategoryLessonsScreen(
              categoryId: state.pathParameters['categoryId'] ?? '',
            ),
          ),
          GoRoute(
            path: '/number/standalone/:subcategoryId',
            builder: (context, state) => Scaffold(
              body: Text(
                'Standalone Number Grid: ${state.pathParameters['subcategoryId']}',
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            categoryNotifierProvider.overrideWith(
              (ref) => MockCategoryNotifier([mockNumberCategory]),
            ),
            lessonsByCategoryProvider(
              'cat_numbers',
            ).overrideWith((ref) => AsyncValue.data(mockNumberLessons)),
            purchasedCategoriesProvider.overrideWith((ref) => {'cat_numbers'}),
            effectiveScriptModeProvider.overrideWith((ref) => 'latin'),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Assert that "Lekha" Browse All card appears at the top
      expect(find.text('Lekha'), findsOneWidget);
      expect(
        find.text('Explore the complete grid dictionary of all numbers'),
        findsOneWidget,
      );

      // Tap the "Lekha" card
      await tester.tap(find.text('Lekha'));
      await tester.pumpAndSettle();

      // Assert navigation to standalone number grid all
      expect(find.text('Standalone Number Grid: all'), findsOneWidget);
    },
  );

  testWidgets(
    'CategoryLessonsScreen tapping a lesson card routes to the per-lesson carousel route, NOT standalone grid',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final router = GoRouter(
        initialLocation: '/lessons/cat_alphabets',
        routes: [
          GoRoute(
            path: '/lessons/:categoryId',
            builder: (context, state) => CategoryLessonsScreen(
              categoryId: state.pathParameters['categoryId'] ?? '',
            ),
          ),
          GoRoute(
            path: '/letter/standalone/:subcategoryId',
            builder: (context, state) => Scaffold(
              body: Text(
                'Standalone Letter Grid: ${state.pathParameters['subcategoryId']}',
              ),
            ),
          ),
          GoRoute(
            path: '/lesson/:lessonId',
            builder: (context, state) => Scaffold(
              body: Text(
                'Lesson Carousel: ${state.pathParameters['lessonId']}',
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            categoryNotifierProvider.overrideWith(
              (ref) => MockCategoryNotifier([mockAlphabetCategory]),
            ),
            lessonsByCategoryProvider(
              'cat_alphabets',
            ).overrideWith((ref) => AsyncValue.data(mockLessons)),
            purchasedCategoriesProvider.overrideWith(
              (ref) => {'cat_alphabets'},
            ),
            effectiveScriptModeProvider.overrideWith((ref) => 'latin'),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Assert lesson card Vowels I is present
      expect(find.text('Vowels I'), findsOneWidget);

      // Tap the Vowels I card
      await tester.tap(find.text('Vowels I'));
      await tester.pumpAndSettle();

      // Assert navigation to the per-lesson carousel, NOT ContentGridScreen standalone
      expect(find.text('Lesson Carousel: lesson_vowels_1'), findsOneWidget);
      expect(find.textContaining('Standalone Letter Grid:'), findsNothing);
    },
  );
}
