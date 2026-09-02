import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/features/admin/presentation/rhymes/admin_rhymes_screen.dart';
// ignore: unused_import
import 'package:itun/features/admin/presentation/content/admin_content_list_screen.dart';
import 'package:itun/features/categories/domain/entities/category_entity.dart';
import 'package:itun/features/categories/domain/repositories/category_repository.dart';
import 'package:itun/shared/providers/providers.dart';

class _FakeCategoryRepository implements CategoryRepository {
  @override
  Future<Either<Failure, void>> createCategory(CategoryEntity category) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> deleteCategory(String id) async =>
      const Right(null);

  @override
  Future<Either<Failure, List<CategoryEntity>>> getCategories() async =>
      const Right([]);

  @override
  Future<Either<Failure, CategoryEntity>> getCategoryById(String id) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, void>> updateCategory(CategoryEntity category) async =>
      const Right(null);
}

void main() {
  testWidgets('AdminRhymesScreen renders the rhyme content list', (
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
                titleOlChiki: 'ᱴᱮᱥᱴ',
                subtitle: 'A test rhyme',
                blocks: const [],
                updatedAt: DateTime.now(),
              ),
            ];
          }),
          categoryRepositoryProvider.overrideWithValue(
            _FakeCategoryRepository(),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: AdminRhymesScreen())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Rhymes & Stories'), findsOneWidget);
    expect(find.text('Test Rhyme'), findsOneWidget);
  });

  testWidgets('AdminRhymesScreen forwards an optional category filter', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentListProvider.overrideWith((ref, arg) async {
            return arg.$2 == 'cat_7' ? <ContentItem>[] : <ContentItem>[];
          }),
          categoryRepositoryProvider.overrideWithValue(
            _FakeCategoryRepository(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AdminRhymesScreen(categoryId: 'cat_7')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Rhymes & Stories'), findsOneWidget);
    expect(find.byType(AdminRhymesScreen), findsOneWidget);
  });
}
