import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/features/admin/presentation/content/admin_content_list_screen.dart';
import 'package:itun/features/categories/domain/entities/category_entity.dart';
import 'package:itun/features/categories/domain/repositories/category_repository.dart';
import 'package:itun/shared/providers/providers.dart';

class MockContentRepository extends Mock implements ContentRepository {}


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

  testWidgets('Tapping Edit metadata on Rhyme kind opens edit form', (
    tester,
  ) async {
    final mockRepo = MockContentRepository();
    final item = ContentItem(
      id: 'rhyme_1',
      kind: ContentKind.rhyme,
      categoryId: 'cat_1',
      title: 'Test Rhyme',
      titleOlChiki: 'ᱴᱮᱥᱴ ᱨᱟᱭᱤᱢ',
      subtitle: 'A test rhyme',
      blocks: const [],
      updatedAt: DateTime.now(),
    );

    when(() => mockRepo.get(ContentKind.rhyme, 'rhyme_1'))
        .thenAnswer((_) async => Right(item));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentListProvider.overrideWith((ref, arg) async {
            return [item];
          }),
          categoryRepositoryProvider.overrideWithValue(
            FakeCategoryRepository(),
          ),
          contentRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AdminContentListScreen(kind: ContentKind.rhyme)),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final editButton = find.byIcon(Icons.edit_rounded);
    expect(editButton, findsOneWidget);
    await tester.tap(editButton);
    await tester.pumpAndSettle();

    expect(find.text('Edit Rhymes & Stories'), findsOneWidget);
  });

  testWidgets('Rhyme with empty heroMedia url renders and edits without crashing', (
    tester,
  ) async {
    final mockRepo = MockContentRepository();
    final item = ContentItem(
      id: 'rhyme_1',
      kind: ContentKind.rhyme,
      categoryId: 'cat_1',
      title: 'Test Rhyme',
      titleOlChiki: 'ᱴᱮᱥᱴ ᱨᱟᱭᱤᱢ',
      subtitle: 'A test rhyme',
      heroMedia: const ContentMedia(url: '', fileId: '', kind: ContentMediaKind.image),
      blocks: const [],
      updatedAt: DateTime.now(),
    );

    when(() => mockRepo.get(ContentKind.rhyme, 'rhyme_1'))
        .thenAnswer((_) async => Right(item));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentListProvider.overrideWith((ref, arg) async {
            return [item];
          }),
          categoryRepositoryProvider.overrideWithValue(
            FakeCategoryRepository(),
          ),
          contentRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AdminContentListScreen(kind: ContentKind.rhyme)),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Test Rhyme'), findsOneWidget);

    final editButton = find.byIcon(Icons.edit_rounded);
    expect(editButton, findsOneWidget);
    await tester.tap(editButton);
    await tester.pumpAndSettle();

    expect(find.text('Edit Rhymes & Stories'), findsOneWidget);
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
