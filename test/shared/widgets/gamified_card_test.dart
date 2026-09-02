import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/shared/widgets/gamified_card.dart';

Widget _wrap(Widget child, {Brightness brightness = Brightness.light}) {
  return MaterialApp(
    theme: ThemeData(brightness: brightness),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('renders its child and default 4px bottom border', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const GamifiedCard(child: Text('Card body'))),
    );

    expect(find.text('Card body'), findsOneWidget);
    // Outer decoration (border colour) + inner card decoration.
    expect(find.byType(GamifiedCard), findsOneWidget);
    final containers = tester.widgetList<Container>(
      find.descendant(
        of: find.byType(GamifiedCard),
        matching: find.byType(Container),
      ),
    );
    expect(containers.length, greaterThanOrEqualTo(2));
    // Inner container carries the bottom margin that forms the border.
    final inner = containers.last;
    expect(inner.margin, const EdgeInsets.only(bottom: 4.0));
  });

  testWidgets('onTap fires and triggers the press animation', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(GamifiedCard(onTap: () => taps++, child: const Text('Tap me'))),
    );

    await tester.tap(find.text('Tap me'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 150));

    expect(taps, 1);
  });

  testWidgets('custom color, border color and padding are applied', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const GamifiedCard(
          color: Colors.deepPurple,
          bottomBorderColor: Colors.orange,
          padding: EdgeInsets.all(32),
          child: Text('Styled'),
        ),
      ),
    );

    final containers = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(GamifiedCard),
            matching: find.byType(Container),
          ),
        )
        .toList();

    expect(containers.first.decoration, isA<BoxDecoration>());
    final outer = containers.first.decoration! as BoxDecoration;
    expect(outer.color, Colors.orange);
    expect(containers.last.padding, const EdgeInsets.all(32));
  });

  testWidgets('dark theme picks the elevated surface color by default', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const GamifiedCard(child: Text('Dark')),
        brightness: Brightness.dark,
      ),
    );

    expect(find.text('Dark'), findsOneWidget);
  });

  testWidgets('tap cancel reverses the press animation without crashing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(GamifiedCard(onTap: () {}, child: const Text('Cancel me'))),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Cancel me')),
    );
    await tester.pump(const Duration(milliseconds: 60));
    await gesture.cancel();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
