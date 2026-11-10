import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/home/presentation/widgets/home_tool_tile.dart';

void main() {
  testWidgets('HomeToolTile shows title, subtitle and fires onTap', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeToolTile(
            icon: Icons.translate_rounded,
            title: 'Instant Translate',
            subtitle: 'Any Language → Ol Chiki',
            onTap: () => taps++,
          ),
        ),
      ),
    );
    expect(find.text('Instant Translate'), findsOneWidget);
    expect(find.text('Any Language → Ol Chiki'), findsOneWidget);
    expect(find.byIcon(Icons.translate_rounded), findsOneWidget);
    await tester.tap(find.byType(HomeToolTile));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('HomeToolTile is a flat surface (no gradient)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: HomeToolTile(
            icon: Icons.mic_rounded,
            title: 'AI Voice',
            subtitle: 'Hear it in Santali',
            onTap: () {},
          ),
        ),
      ),
    );
    final containers = tester.widgetList<Container>(find.byType(Container));
    for (final c in containers) {
      final d = c.decoration;
      if (d is BoxDecoration) expect(d.gradient, isNull);
    }
  });
}
