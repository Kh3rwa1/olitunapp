import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/presentation/bakhed/bakhed_hub_screen.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/shared/repositories/content_repository.dart';
import 'package:itun/features/rhymes/domain/rhyme_category_model.dart';
import 'package:itun/shared/providers/rhymes_providers.dart';

void main() {
  testWidgets(
    'Hub filter dropdown shows distinct category strings and filters correctly',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final rhymes = [
        ContentItem(
          id: 'rhyme_1',
          kind: ContentKind.rhyme,
          categoryId: 'cat_sohrai',
          category: 'Sohrai',
          title: 'Sohrai Rhyme',
          blocks: const [],
          updatedAt: DateTime(2026),
        ),
        ContentItem(
          id: 'rhyme_2',
          kind: ContentKind.rhyme,
          categoryId: 'cat_baha',
          category: 'Baha',
          title: 'Baha Rhyme',
          blocks: const [],
          updatedAt: DateTime(2026),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contentListProvider((
              ContentKind.rhyme,
              null,
            )).overrideWith((ref) => rhymes),
            rhymeCategoriesProvider.overrideWith(
              (ref) => AsyncValue.data([
                RhymeCategoryModel(
                  id: 'Sohrai',
                  nameOlChiki: 'Sohrai',
                  nameLatin: 'Sohrai',
                  iconName: 'auto_awesome',
                  order: 0,
                ),
                RhymeCategoryModel(
                  id: 'Baha',
                  nameOlChiki: 'Baha',
                  nameLatin: 'Baha',
                  iconName: 'auto_awesome',
                  order: 1,
                ),
              ]),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: BakhedHubScreen())),
        ),
      );

      await tester.pumpAndSettle();

      // Verify both rhymes are initially visible
      expect(find.text('Sohrai Rhyme'), findsOneWidget);
      expect(find.text('Baha Rhyme'), findsOneWidget);

      // Find the category dropdown button
      final dropdownFinder = find.byType(DropdownButton<String?>);
      expect(dropdownFinder, findsOneWidget);

      // Open the dropdown
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      // Tap on 'Sohrai' option in dropdown
      final sohraiItemFinder = find.text('Sohrai').last;
      await tester.tap(sohraiItemFinder);
      await tester.pumpAndSettle();

      // Verify that only the Sohrai rhyme is visible after filtering
      expect(find.text('Sohrai Rhyme'), findsOneWidget);
      expect(find.text('Baha Rhyme'), findsNothing);

      // Open the dropdown again to switch back to 'All Categories'
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      final allItemFinder = find.text('All Categories').last;
      await tester.tap(allItemFinder);
      await tester.pumpAndSettle();

      // Verify both are visible again
      expect(find.text('Sohrai Rhyme'), findsOneWidget);
      expect(find.text('Baha Rhyme'), findsOneWidget);
    },
  );
}
