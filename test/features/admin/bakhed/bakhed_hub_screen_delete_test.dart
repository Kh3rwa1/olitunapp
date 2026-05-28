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

class MockBakhedRepository extends Mock implements BakhedRepository {}

void main() {
  testWidgets(
    'BakhedHubScreen delete button reproduces the blank screen issue',
    (tester) async {
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

      when(
        () => mockRepo.getLyrics('rhyme_1'),
      ).thenAnswer((_) async => right(const []));
      when(
        () => mockRepo.getVocabulary('rhyme_1'),
      ).thenAnswer((_) async => right(const []));
      when(
        () => mockRepo.getCulturalNotes('rhyme_1'),
      ).thenAnswer((_) async => right(const []));
      when(
        () => mockRepo.delete('rhyme_1'),
      ).thenAnswer((_) async => right(unit));

      await tester.pumpWidget(
        ProviderScope(
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
          child: const MaterialApp(home: Scaffold(body: BakhedHubScreen())),
        ),
      );

      await tester.pumpAndSettle();

      // Find delete button
      final deleteBtn = find.byIcon(Icons.delete_outline_rounded);
      expect(deleteBtn, findsOneWidget);

      // Click delete button
      await tester.tap(deleteBtn);
      await tester.pump(); // Start fetching child counts (loading dialog shown)
      await tester.pump(
        const Duration(milliseconds: 100),
      ); // Complete async fetches
      await tester.pumpAndSettle(); // Settle transition dialogs

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
      await tester.pump(); // Starts delete call
      await tester.pump(const Duration(milliseconds: 100)); // Complete delete
      await tester.pumpAndSettle(); // Settle list refresh / snackbar
    },
  );
}
