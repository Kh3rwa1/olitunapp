import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/features/admin/presentation/content/admin_content_list_screen.dart';
import 'package:itun/features/admin/presentation/widgets/common/admin_states.dart';
import 'package:itun/features/categories/domain/entities/category_entity.dart';
import 'package:itun/features/categories/domain/repositories/category_repository.dart';
import 'package:itun/shared/providers/providers.dart';

class MockContentRepository extends Mock implements ContentRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  testWidgets('content failure shows retry, not empty data', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = MockContentRepository();
    final categories = MockCategoryRepository();
    when(
      () => categories.getCategories(),
    ).thenAnswer((_) async => const Right(<CategoryEntity>[]));
    when(
      () => repository.list(ContentKind.word, categoryId: null),
    ).thenAnswer((_) async => const Left(NetworkFailure()));

    final container = ProviderContainer(
      overrides: [
        contentRepositoryProvider.overrideWithValue(repository),
        categoryRepositoryProvider.overrideWithValue(categories),
        isAuthenticatedProvider.overrideWith((ref) async => false),
      ],
    );
    addTearDown(container.dispose);
    await container.read(isAuthenticatedProvider.future);

    // Exercise the actual provider, not an override returning a canned error.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: AdminContentListScreen(kind: ContentKind.word),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AdminErrorState), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('No items found'), findsNothing);
    expect(find.text('CSV Export'), findsNothing);

    when(
      () => repository.list(ContentKind.word, categoryId: null),
    ).thenAnswer((_) async => const Right(<ContentItem>[]));
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.byType(AdminErrorState), findsNothing);
    expect(find.text('No items found'), findsOneWidget);
    expect(find.text('CSV Export'), findsOneWidget);
    verify(
      () => repository.list(ContentKind.word, categoryId: null),
    ).called(2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
