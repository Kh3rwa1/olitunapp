import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:itun/features/admin/data/bakhed_repository.dart';
import 'package:itun/features/admin/presentation/bakhed/bakhed_hub_screen.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/features/rhymes/domain/rhyme_category_model.dart';
import 'package:itun/shared/providers/rhymes_providers.dart';
import 'package:itun/shared/repositories/content_repository.dart';
import 'package:itun/core/error/failures.dart';

class MockBakhedRepository extends Mock implements BakhedRepository {}

void main() {
  testWidgets('BakhedHubScreen delete button with instant database failure', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockRepo = MockBakhedRepository();

    final rhyme = ContentItem(
      id: 'rhyme_1',
      kind: ContentKind.rhyme,
      categoryId: 'cat_sohrai',
      category: 'Sohrai',
      title: 'Sohrai Rhyme',
      blocks: const [],
      updatedAt: DateTime(2026),
    );

    // We make the repository methods complete instantly
    when(
      () => mockRepo.getLyrics('rhyme_1'),
    ).thenAnswer((_) async => right(const []));
    when(
      () => mockRepo.getVocabulary('rhyme_1'),
    ).thenAnswer((_) async => right(const []));
    when(
      () => mockRepo.getCulturalNotes('rhyme_1'),
    ).thenAnswer((_) async => right(const []));
    when(() => mockRepo.delete('rhyme_1')).thenAnswer(
      (_) async => left(const ServerFailure(message: 'Unauthorized')),
    );

    final container = ProviderContainer(
      overrides: [
        contentListProvider((
          ContentKind.rhyme,
          null,
        )).overrideWith((ref) => [rhyme]),
        rhymeCategoriesProvider.overrideWith(
          (ref) => AsyncValue.data([
            RhymeCategoryModel(
              id: 'Sohrai',
              nameOlChiki: 'Sohrai',
              nameLatin: 'Sohrai',
              iconName: 'auto_awesome',
              order: 0,
            ),
          ]),
        ),
        bakhedRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: Navigator(onGenerateRoute: _onGenerateRoute)),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Find delete button
    final deleteBtn = find.byIcon(Icons.delete_outline_rounded);
    expect(deleteBtn, findsOneWidget);

    // Click delete button
    await tester.tap(deleteBtn);
    await tester.pump(); // Starts get child counts dialog push
    await tester.pump(); // Resolves async calls instantly and pops the dialog
    await tester.pumpAndSettle(); // Settle dialogs

    // Verify the confirmation dialog is visible
    expect(
      find.textContaining('Are you sure you want to permanently delete'),
      findsOneWidget,
    );

    // Click the Delete button inside dialog
    final confirmDeleteBtn = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Delete'),
    );
    expect(confirmDeleteBtn, findsOneWidget);

    await tester.tap(confirmDeleteBtn);
    await tester.pump(); // Starts loading dialog push
    await tester.pump(); // Resolves delete instantly and pops
    await tester.pumpAndSettle();

    // Check if we crashed or blank screen occurred
    expect(find.byType(BakhedHubScreen), findsOneWidget);
  });
}

Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
  return MaterialPageRoute(
    builder: (context) => const BakhedHubScreen(),
    settings: settings,
  );
}
