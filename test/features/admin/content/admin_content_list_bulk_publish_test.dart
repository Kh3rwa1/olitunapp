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
  setUpAll(() {
    registerFallbackValue(
      ContentItem(
        id: 'lesson_1',
        kind: ContentKind.lesson,
        categoryId: 'cat_1',
        title: 'Test Subcategory',
        blocks: const [],
        updatedAt: DateTime.now(),
      ),
    );
  });

  testWidgets(
    'AdminContentListScreen bulk publish resolves synchronously without popping parent screen',
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

      // Return synchronously on upsert
      when(
        () => mockRepo.upsert(any()),
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

      // Find the checkbox for the lesson row
      final checkbox = find.byType(Checkbox).first;
      expect(checkbox, findsOneWidget);

      // Tap the checkbox to select the item
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      // Verify the bulk action bottom bar is now displayed
      expect(find.text('1 items selected'), findsOneWidget);

      // Find the bulk 'Publish' button using direct text search
      final publishButton = find.text('Publish');
      expect(publishButton, findsOneWidget);

      await tester.tap(publishButton);

      // Let the DialogRoute and the Future.delayed yield
      await tester.pump(); // Starts showDialog push and async repo.upsert call
      await tester.pump(
        Duration.zero,
      ); // Yields to Future.delayed(Duration.zero)
      await tester
          .pumpAndSettle(); // Settles all route transitions (loader pop, sheet push)

      // Assertions
      // 1. Check if the parent screen is still in the widget tree (which guarantees it wasn't popped)
      expect(find.byType(AdminContentListScreen), findsOneWidget);

      // 2. Check that the selection is cleared
      expect(find.text('1 items selected'), findsNothing);
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
