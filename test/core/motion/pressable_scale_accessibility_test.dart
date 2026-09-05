import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/motion/pressable_scale.dart';
import 'package:itun/shared/widgets/bento_grid.dart';

Widget _wrap(Widget child, {bool reduce = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduce),
    child: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  testWidgets('Enter and Space activate the focused action exactly once', (
    tester,
  ) async {
    var activations = 0;
    await tester.pumpWidget(
      _wrap(
        PressableScale(
          onTap: () => activations++,
          haptic: HapticIntensity.none,
          child: const Text('Open lesson'),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(activations, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(activations, 2);
  });

  testWidgets('exposes one named tap action and a minimum touch target', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        _wrap(
          PressableScale(
            semanticLabel: 'Open numbers',
            onTap: () {},
            child: const Icon(Icons.calculate, size: 20),
          ),
        ),
      );
      final node = tester.getSemantics(find.bySemanticsLabel('Open numbers'));
      expect(node.getSemanticsData().hasAction(ui.SemanticsAction.tap), isTrue);
      final size = tester.getSize(find.byType(PressableScale));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('disabled controls cannot activate via pointer or keyboard', (
    tester,
  ) async {
    var activations = 0;
    await tester.pumpWidget(
      _wrap(
        PressableScale(
          enabled: false,
          onTap: () => activations++,
          child: const Text('Disabled lesson'),
        ),
      ),
    );
    await tester.tap(find.text('Disabled lesson'));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(activations, 0);
  });

  testWidgets('reduced motion skips press transforms and entrance effects', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        AnimatedBentoChild(
          index: 100,
          child: PressableScale(
            onTap: () {},
            child: const Text('Immediately available'),
          ),
        ),
        reduce: true,
      ),
    );
    expect(find.text('Immediately available'), findsOneWidget);
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Immediately available')),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      find.descendant(
        of: find.byType(AnimatedBentoChild),
        matching: find.byType(Transform),
      ),
      findsNothing,
    );
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('late list items never wait seconds for entrance motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const AnimatedBentoChild(index: 100, child: Text('Last category'))),
    );
    await tester.pump();
    for (var frame = 0; frame < 20; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final fades = tester.widgetList<FadeTransition>(
      find.descendant(
        of: find.byType(AnimatedBentoChild),
        matching: find.byType(FadeTransition),
      ),
    );
    expect(fades, isNotEmpty);
    for (final fade in fades) {
      expect(fade.opacity.value, 1);
    }
  });
}
