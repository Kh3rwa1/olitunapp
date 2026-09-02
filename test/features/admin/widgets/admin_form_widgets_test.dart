import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/presentation/widgets/admin_form_widgets.dart';

/// Covers the admin_form_widgets.dart export barrel: every common form
/// control is reachable through this single import in app code.
void main() {
  Future<void> pumpScaffold(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: child)),
      ),
    );
    await tester.pump();
  }

  testWidgets('barrel exposes AdminPrimaryButton with tap callback', (
    tester,
  ) async {
    var tapped = false;
    await pumpScaffold(
      tester,
      AdminPrimaryButton(
        label: 'Save',
        icon: Icons.save_rounded,
        onTap: () => tapped = true,
      ),
    );

    expect(find.text('Save'), findsOneWidget);
    expect(find.byIcon(Icons.save_rounded), findsOneWidget);
    await tester.tap(find.text('Save'));
    expect(tapped, isTrue);
  });

  testWidgets('barrel exposes AdminSecondaryButton in destructive mode', (
    tester,
  ) async {
    await pumpScaffold(
      tester,
      AdminSecondaryButton(label: 'Discard', onTap: () {}, destructive: true),
    );

    expect(find.text('Discard'), findsOneWidget);
  });

  testWidgets('barrel exposes AdminIconAction with tooltip', (tester) async {
    await pumpScaffold(
      tester,
      AdminIconAction(
        icon: Icons.edit_rounded,
        tooltip: 'Edit item',
        onTap: () {},
      ),
    );

    expect(find.byIcon(Icons.edit_rounded), findsOneWidget);
    expect(find.byType(Tooltip), findsOneWidget);
  });
}
