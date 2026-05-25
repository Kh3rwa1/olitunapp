import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/features/admin/presentation/content/admin_content_list_screen.dart';
import 'package:itun/features/categories/domain/entities/category_entity.dart';
import 'package:itun/features/categories/domain/repositories/category_repository.dart';
import 'package:itun/shared/providers/providers.dart';

void main() {
  testWidgets('AdminContentListScreen renders cleanly for Rhyme kind', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentListProvider.overrideWith((ref, arg) async {
            return <ContentItem>[
              ContentItem(
                id: 'rhyme_1',
                kind: ContentKind.rhyme,
                categoryId: 'cat_1',
                title: 'Test Rhyme',
                titleOlChiki: 'ᱴᱮᱥᱴ ᱨᱟᱭᱤᱢ',
                subtitle: 'A test rhyme',
                blocks: const [],
                updatedAt: DateTime.now(),
              ),
            ];
          }),
          categoryRepositoryProvider.overrideWithValue(
            FakeCategoryRepository(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AdminContentListScreen(kind: ContentKind.rhyme)),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Rhymes & Stories'), findsOneWidget);
    expect(find.text('Test Rhyme'), findsOneWidget);
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
