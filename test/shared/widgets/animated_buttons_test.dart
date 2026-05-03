import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:itun/shared/widgets/animated_buttons.dart';

void main() {
  Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('PrimaryButton renders its label', (tester) async {
    await tester.pumpWidget(_wrap(
      PrimaryButton(text: 'Continue', onPressed: () {}),
    ));
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('PrimaryButton invokes onPressed when tapped', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(
      PrimaryButton(text: 'Tap', onPressed: () => taps++),
    ));
    await tester.tap(find.text('Tap'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(taps, 1);
  });

  testWidgets('PrimaryButton does NOT invoke onPressed when disabled',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(
      PrimaryButton(
        text: 'Off',
        isDisabled: true,
        onPressed: () => taps++,
      ),
    ));
    await tester.tap(find.text('Off'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 100));
    expect(taps, 0);
  });

  testWidgets('PrimaryButton respects custom width', (tester) async {
    await tester.pumpWidget(_wrap(
      SizedBox(
        width: 400,
        child: PrimaryButton(
          text: 'Wide',
          width: 240,
          onPressed: () {},
        ),
      ),
    ));
    expect(find.text('Wide'), findsOneWidget);
  });
}
