import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/presentation/bakhed/widgets/bakhed_category_field.dart';
import 'package:itun/features/rhymes/domain/rhyme_category_model.dart';
import 'package:itun/shared/providers/rhymes_providers.dart';

void main() {
  Widget wrap(Widget child, List<String> categories) {
    return ProviderScope(
      overrides: [
        rhymeCategoriesProvider.overrideWithValue(
          AsyncValue.data(
            categories
                .asMap()
                .entries
                .map(
                  (entry) => RhymeCategoryModel(
                    id: entry.value,
                    nameOlChiki: entry.value,
                    nameLatin: entry.value,
                    iconName: 'auto_awesome',
                    order: entry.key,
                  ),
                )
                .toList(),
          ),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: child,
          ),
        ),
      ),
    );
  }

  testWidgets('BakhedCategoryField renders with initial value', (tester) async {
    await tester.pumpWidget(
      wrap(
        BakhedCategoryField(
          initialValue: 'Sohrai',
          onChanged: (_) {},
        ),
        ['Sohrai', 'Baha'],
      ),
    );
    expect(find.text('Sohrai'), findsOneWidget);
  });

  testWidgets('BakhedCategoryField shows suggestion list on focus', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        BakhedCategoryField(
          initialValue: '',
          onChanged: (_) {},
        ),
        ['Sohrai', 'Baha'],
      ),
    );

    // Tap the field to focus it
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    // Verify suggestions are displayed in the overlay
    expect(find.text('Sohrai'), findsOneWidget);
    expect(find.text('Baha'), findsOneWidget);
  });

  testWidgets('Typing Soh filters suggestions to Sohrai', (tester) async {
    await tester.pumpWidget(
      wrap(
        BakhedCategoryField(
          initialValue: '',
          onChanged: (_) {},
        ),
        ['Sohrai', 'Baha'],
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Soh');
    await tester.pumpAndSettle();

    expect(find.text('Sohrai'), findsOneWidget);
    expect(find.text('Baha'), findsNothing);
  });

  testWidgets(
    'Typing a new category shows Create new option and calls onChanged on selection',
    (tester) async {
      String? updatedValue;
      await tester.pumpWidget(
        wrap(
          BakhedCategoryField(
            initialValue: '',
            onChanged: (val) => updatedValue = val,
          ),
          ['Sohrai'],
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Baha');
      await tester.pumpAndSettle();

      // Verify the "+ Create new: "Baha"" option is shown
      expect(find.text('+ Create new: "Baha"'), findsOneWidget);

      // Tap the Create new suggestion
      await tester.tap(find.text('+ Create new: "Baha"'));
      await tester.pumpAndSettle();

      expect(updatedValue, 'Baha');
    },
  );

  testWidgets('Typing exact existing option does not show Create new option', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        BakhedCategoryField(
          initialValue: '',
          onChanged: (_) {},
        ),
        ['Sohrai'],
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Sohrai');
    await tester.pumpAndSettle();

    expect(find.text('+ Create new: "Sohrai"'), findsNothing);
  });

  testWidgets('Clearing the field calls onChanged with null', (tester) async {
    String? updatedValue = 'Initial';
    await tester.pumpWidget(
      wrap(
        BakhedCategoryField(
          initialValue: 'Sohrai',
          onChanged: (val) => updatedValue = val,
        ),
        ['Sohrai'],
      ),
    );

    // Tap the clear button
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();

    expect(updatedValue, isNull);
  });
}
