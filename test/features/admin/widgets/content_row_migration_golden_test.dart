import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/features/admin/presentation/content/admin_content_list_screen.dart';
import 'package:itun/features/categories/domain/entities/category_entity.dart';
import 'package:itun/features/categories/domain/repositories/category_repository.dart';
import 'package:itun/features/categories/presentation/providers/category_notifier.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/shared/providers/providers.dart';
import 'package:itun/features/auth/presentation/providers/auth_providers.dart';
import 'package:itun/core/error/failures.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockContentRepository extends Mock implements ContentRepository {}

class MockCategoryNotifier extends StateNotifier<AsyncValue<List<CategoryEntity>>> with Mock implements CategoryNotifier {
  MockCategoryNotifier() : super(const AsyncValue.data(<CategoryEntity>[]));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<ContentItem> mockItems = [
    ContentItem(
      id: 'item_1',
      kind: ContentKind.word,
      categoryId: 'cat_1',
      title: 'Word with Thumbnail',
      titleOlChiki: 'ᱴᱮᱥᱴ ᱑',
      subtitle: 'A beautifully designed word card featuring an image',
      blocks: const [],
      heroMedia: const ContentMedia(
        url: 'https://images.unsplash.com/photo-1546410531-bb4caa6b424d',
        fileId: 'mock_file_1',
        kind: ContentMediaKind.image,
      ),
      isPublished: true,
      isPremium: true,
      updatedAt: DateTime.now(),
    ),
    ContentItem(
      id: 'item_2',
      kind: ContentKind.word,
      categoryId: 'cat_1',
      title: 'Word without Thumbnail',
      titleOlChiki: 'ᱴᱮᱥᱴ ᱒',
      subtitle: 'A clean metadata text-only card demonstrating responsive wrap layout',
      blocks: const [],
      isPublished: false,
      isPremium: false,
      updatedAt: DateTime.now(),
    ),
    ContentItem(
      id: 'item_3',
      kind: ContentKind.word,
      categoryId: 'cat_1',
      title: 'Selected Word Row',
      titleOlChiki: 'ᱴᱮᱥᱴ ᱓',
      subtitle: 'A card in active selection state with checkmark indicator highlighted',
      blocks: const [],
      isPublished: true,
      isPremium: false,
      updatedAt: DateTime.now(),
    ),
  ];

  group('AdminContentListScreen Row Layout Golden Tests', () {
    testWidgets('captures list view baseline rendering', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockContentRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isAuthenticatedProvider.overrideWith((ref) async => true),
            categoryNotifierProvider.overrideWith((ref) => MockCategoryNotifier()),
            contentListProvider.overrideWith((ref, arg) async {
              return mockItems;
            }),
            contentRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            themeMode: ThemeMode.light,
            home: Scaffold(
              body: AdminContentListScreen(kind: ContentKind.word),
            ),
          ),
        ),
      );

      // Let network images settle
      await tester.pumpAndSettle();

      // Tap on the checkbox of the third row to put it in selected state
      final checkboxFinder = find.byType(Checkbox);
      expect(checkboxFinder, findsNWidgets(3));
      await tester.tap(checkboxFinder.at(2));
      await tester.pumpAndSettle();

      // Find the ListView
      final listViewFinder = find.byType(ListView);
      expect(listViewFinder, findsOneWidget);

      if (!Platform.environment.containsKey('GITHUB_ACTIONS')) {
        await expectLater(
          listViewFinder,
          matchesGoldenFile('../../../goldens/content_row_baseline.png'),
        );
      }
    });
  });
}

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
    return const Right(<CategoryEntity>[]);
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
