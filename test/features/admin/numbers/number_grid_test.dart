import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/presentation/numbers/widgets/number_grid.dart';
import 'package:itun/shared/models/content/number_model.dart';

NumberModel _number(int value, String numeral, String name) => NumberModel(
  id: 'num_$value',
  numeral: numeral,
  value: value,
  nameOlChiki: name,
  nameLatin: 'name-$value',
);

void main() {
  Future<void> pumpGrid(
    WidgetTester tester, {
    required bool isWideScreen,
    required List<NumberModel> numbers,
    void Function(NumberModel)? onEdit,
    void Function(NumberModel)? onDelete,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1000,
            height: 800,
            child: NumberGrid(
              numbers: numbers,
              isDark: false,
              isWideScreen: isWideScreen,
              onEdit: onEdit ?? (_) {},
              onDelete: onDelete ?? (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('renders numerals, names, and Ol Chiki values', (tester) async {
    await pumpGrid(
      tester,
      isWideScreen: false,
      numbers: [_number(1, '᱑', 'ᱢᱤᱫᱽ'), _number(2, '᱒', 'ᱵᱟᱨ')],
    );

    expect(find.text('᱑'), findsOneWidget);
    expect(find.text('name-1'), findsOneWidget);
    expect(find.text('ᱢᱤᱫᱽ = 1'), findsOneWidget);
    expect(find.text('ᱵᱟᱨ = 2'), findsOneWidget);
  });

  testWidgets('tapping a card invokes onEdit with that number', (tester) async {
    final edited = <int>[];
    await pumpGrid(
      tester,
      isWideScreen: false,
      numbers: [_number(1, '᱑', 'ᱢᱤᱫᱽ')],
      onEdit: (n) => edited.add(n.value),
    );

    await tester.tap(find.text('᱑'));
    expect(edited, [1]);
  });

  testWidgets('hovering reveals edit and delete actions', (tester) async {
    var deleted = false;
    await pumpGrid(
      tester,
      isWideScreen: false,
      numbers: [_number(3, '᱓', 'ᱯᱮ')],
      onDelete: (_) => deleted = true,
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.text('name-3')));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.edit_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    expect(deleted, isTrue);
  });
}
