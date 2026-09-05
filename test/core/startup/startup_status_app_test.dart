import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/startup/startup_status_app.dart';

void main() {
  testWidgets(
    'loading shell renders without initialized storage or providers',
    (tester) async {
      await tester.pumpWidget(const StartupStatusApp());
      expect(find.text('Starting Olitun'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(const Key('startup-retry')), findsNothing);
      expect(find.byType(Navigator), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('failure shell invokes the supplied retry action', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      StartupStatusApp(
        errorMessage: 'Could not finish starting.',
        onRetry: () => retries++,
      ),
    );
    await tester.tap(find.byKey(const Key('startup-retry')));
    expect(retries, 1);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('failure content scrolls on a narrow large-text display', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 400);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      StartupStatusApp(
        errorMessage: 'Please retry. If this continues, restart the app.',
        onRetry: () {},
      ),
    );
    await tester.ensureVisible(find.byKey(const Key('startup-retry')));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
