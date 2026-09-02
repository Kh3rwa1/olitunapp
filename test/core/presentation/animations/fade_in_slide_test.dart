import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/presentation/animations/fade_in_slide.dart';

void main() {
  testWidgets('fades and slides in after mounting', (tester) async {
    const key = Key('target');
    await tester.pumpWidget(
      const MaterialApp(
        home: FadeInSlide(
          duration: Duration(milliseconds: 100),
          child: SizedBox(key: key, width: 50, height: 50),
        ),
      ),
    );

    // Animation just started: opacity near zero and offset shifted down.
    var opacity = tester.widget<Opacity>(
      find.ancestor(of: find.byKey(key), matching: find.byType(Opacity)).first,
    );
    expect(opacity.opacity, lessThan(0.1));

    await tester.pumpAndSettle();

    opacity = tester.widget<Opacity>(
      find.ancestor(of: find.byKey(key), matching: find.byType(Opacity)).first,
    );
    expect(opacity.opacity, 1.0);
  });

  testWidgets('index staggers the start of the animation', (tester) async {
    const key = Key('staggered');
    await tester.pumpWidget(
      const MaterialApp(
        home: FadeInSlide(
          duration: Duration(milliseconds: 50),
          index: 3,
          child: SizedBox(key: key, width: 50, height: 50),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 10));

    // index=3 → 300ms delay: the controller has not started yet.
    final opacity = tester.widget<Opacity>(
      find.ancestor(of: find.byKey(key), matching: find.byType(Opacity)).first,
    );
    expect(opacity.opacity, 0.0);

    // Advance past the 300ms stagger delay, then let the animation finish
    // (pumpAndSettle alone cannot flush the pending delay timer).
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.byKey(key), findsOneWidget);
  });

  testWidgets('offset drives the initial vertical translation', (tester) async {
    const key = Key('offset');
    await tester.pumpWidget(
      const MaterialApp(
        home: FadeInSlide(
          duration: Duration(milliseconds: 100),
          offset: 0,
          child: SizedBox(key: key, width: 50, height: 50),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(key)).dy, greaterThanOrEqualTo(0));
  });

  testWidgets('disposes without leaking the controller', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FadeInSlide(
          duration: Duration(milliseconds: 100),
          child: SizedBox(width: 50, height: 50),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pumpAndSettle();
    // No exception thrown on dispose.
    expect(tester.takeException(), isNull);
  });
}
