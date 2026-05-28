import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:itun/features/admin/presentation/content/admin_content_list_screen.dart';
import 'package:itun/features/categories/domain/entities/category_entity.dart';
import 'package:itun/features/categories/domain/repositories/category_repository.dart';
import 'package:itun/shared/providers/providers.dart';
import 'package:itun/core/error/failures.dart';

class MockContentRepository extends Mock implements ContentRepository {}

class FakeCategoryRepository implements CategoryRepository {
  @override
  Future<Either<Failure, void>> createCategory(CategoryEntity category) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteCategory(String id) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<CategoryEntity>>> getCategories() async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, CategoryEntity>> getCategoryById(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> updateCategory(CategoryEntity category) async {
    return const Right(null);
  }
}

void main() {
  testWidgets(
    'AdminContentListScreen subcategory edit metadata pencil icon resolves synchronously without popping parent screen',
    (tester) async {
      // Set larger screen bounds to prevent RenderFlex layout overflow assertions
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockRepo = MockContentRepository();

      final lessonItem = ContentItem(
        id: 'lesson_1',
        kind: ContentKind.lesson,
        categoryId: 'cat_1',
        title: 'Test Subcategory',
        titleOlChiki: 'ᱴᱮᱥᱴ ᱥᱟᱵᱽᱠᱮᱴᱮᱜᱚᱨᱤ',
        subtitle: 'A test subcategory',
        blocks: const [],
        updatedAt: DateTime.now(),
      );

      // Return synchronously
      when(
        () => mockRepo.get(ContentKind.lesson, 'lesson_1'),
      ).thenAnswer((_) async => Right(lessonItem));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contentListProvider.overrideWith((ref, arg) async {
              return [lessonItem];
            }),
            categoryRepositoryProvider.overrideWithValue(
              FakeCategoryRepository(),
            ),
            contentRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(body: Navigator(onGenerateRoute: _onGenerateRoute)),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the screen and subcategory title render correctly
      expect(find.text('Test Subcategory'), findsOneWidget);
      expect(find.byType(AdminContentListScreen), findsOneWidget);

      // Find the pencil icon (Edit metadata) and tap it
      final editButton = find.byIcon(Icons.edit_rounded);
      expect(editButton, findsOneWidget);

      await tester.tap(editButton);

      // Let the DialogRoute and the Future.delayed yield
      await tester.pump(); // Starts showDialog push and async repo.get call
      await tester.pump(
        Duration.zero,
      ); // Yields to Future.delayed(Duration.zero)
      await tester
          .pumpAndSettle(); // Settles all route transitions (loader pop, sheet push)

      // Assertions
      // 1. Check if the parent screen is still in the widget tree (which guarantees it wasn't popped)
      expect(find.byType(AdminContentListScreen), findsOneWidget);

      // 2. Check if the bottom sheet with 'Edit Subcategories' was successfully presented
      expect(find.text('Edit Subcategories'), findsOneWidget);
    },
  );

  testWidgets(
    'AdminContentListScreen shows Audio Missing and Trace Missing indicators for missing fields',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockRepo = MockContentRepository();

      final letterItemMissingAll = ContentItem(
        id: 'letter_missing',
        kind: ContentKind.letter,
        categoryId: 'cat_1',
        title: 'Missing Letter',
        olChiki: 'ᱚ',
        blocks: const [],
        updatedAt: DateTime.now(),
        audioUrl: null, // Missing audio
        tracing: null, // Missing tracing
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contentListProvider.overrideWith((ref, arg) async {
              return [letterItemMissingAll];
            }),
            categoryRepositoryProvider.overrideWithValue(
              FakeCategoryRepository(),
            ),
            contentRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Navigator(
                onGenerateRoute: (settings) => MaterialPageRoute(
                  builder: (context) =>
                      const AdminContentListScreen(kind: ContentKind.letter),
                  settings: settings,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the item is in the list
      expect(find.text('Missing Letter'), findsOneWidget);

      // Verify the red "Audio Missing" Tooltip and orange "Trace Missing" Tooltip are present
      expect(find.byType(Tooltip), findsAtLeast(2));
      
      final tooltips = tester.widgetList<Tooltip>(find.byType(Tooltip));
      final tooltipMessages = tooltips.map((t) => t.message).toList();
      
      expect(tooltipMessages, contains('Audio Missing'));
      expect(tooltipMessages, contains('Trace Missing'));
    },
  );
}

Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
  return MaterialPageRoute(
    builder: (context) =>
        const AdminContentListScreen(kind: ContentKind.lesson),
    settings: settings,
  );
}
