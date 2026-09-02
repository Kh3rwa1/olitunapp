import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/shared/widgets/progress_ring.dart';

Widget _wrap(Widget child, {Brightness brightness = Brightness.light}) {
  return MaterialApp(
    theme: ThemeData(brightness: brightness),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('animates from 0 to the requested progress', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const ProgressRing(
          progress: 0.6,
          animationDuration: Duration(milliseconds: 200),
          child: Text('60%'),
        ),
      ),
    );

    expect(find.text('60%'), findsOneWidget);
    final paints = tester.widgetList<CustomPaint>(
      find.descendant(
        of: find.byType(ProgressRing),
        matching: find.byType(CustomPaint),
      ),
    );
    expect(paints, isNotEmpty);

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('animate=false renders the final value immediately', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const ProgressRing(progress: 0.75, animate: false, size: 96)),
    );

    final ringBox = tester.widget<SizedBox>(
      find
          .descendant(
            of: find.byType(ProgressRing),
            matching: find.byType(SizedBox),
          )
          .first,
    );
    expect(ringBox.width, 96);
    expect(tester.takeException(), isNull);
  });

  testWidgets('progress updates re-run the tween from the old value', (
    tester,
  ) async {
    Widget host(double value) => _wrap(
      ProgressRing(
        progress: value,
        animationDuration: const Duration(milliseconds: 100),
      ),
    );

    await tester.pumpWidget(host(0.2));
    await tester.pumpAndSettle();

    await tester.pumpWidget(host(0.8));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(find.byType(ProgressRing), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('MiniProgressBar clamps progress and honours custom colors', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const SizedBox(
          width: 200,
          child: MiniProgressBar(
            progress: 1.5, // out of range on purpose
            height: 10,
            progressColor: Colors.green,
          ),
        ),
      ),
    );

    final containerFinder = find.descendant(
      of: find.byType(MiniProgressBar),
      matching: find.byType(AnimatedContainer),
    );
    expect(containerFinder, findsOneWidget);

    final bar = tester.widget<AnimatedContainer>(containerFinder);
    // Clamped to 1.0 → full width (200px).
    expect(bar.constraints?.maxWidth, 200);
  });

  testWidgets('MiniProgressBar supports gradient fills', (tester) async {
    const gradient = LinearGradient(colors: [Colors.red, Colors.blue]);
    await tester.pumpWidget(
      _wrap(
        const SizedBox(
          width: 120,
          child: MiniProgressBar(progress: 0.5, progressGradient: gradient),
        ),
      ),
    );

    final bar = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(MiniProgressBar),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final decoration = bar.decoration! as BoxDecoration;
    expect(decoration.gradient, gradient);
    expect(decoration.color, isNull);
  });

  testWidgets('painter does not crash on edge progress values', (tester) async {
    for (final value in [0.0, 1.0, -0.3, 2.0]) {
      await tester.pumpWidget(_wrap(ProgressRing(progress: value)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
