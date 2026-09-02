import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/presentation/settings/forms/admin_wipe_confirmation_dialog.dart';

void main() {
  Future<void> pumpDialog(
    WidgetTester tester, {
    VoidCallback? onConfirm,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => AdminWipeConfirmationDialog(
                    onConfirm: onConfirm ?? () {},
                  ),
                ),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
  }

  testWidgets('renders the destructive confirmation copy and key field', (
    tester,
  ) async {
    await pumpDialog(tester);

    expect(find.text('Are you absolutely sure?'), findsOneWidget);
    expect(find.text('Destructive Action'), findsOneWidget);
    expect(find.text('Authorization Key'), findsOneWidget);
    expect(find.text('WIPE ALL & RE-SEED'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });

  testWidgets('confirm button stays disabled until WIPE ALL is typed', (
    tester,
  ) async {
    await pumpDialog(tester);

    await tester.enterText(find.byType(TextField), 'wipe');
    await tester.pump();

    final button = find.ancestor(
      of: find.text('WIPE ALL & RE-SEED'),
      matching: find.byType(InkWell),
    );
    final inkWell = tester.widget<InkWell>(button);
    expect(inkWell.onTap, isNull);

    await tester.enterText(find.byType(TextField), 'WIPE ALL');
    await tester.pump();

    final inkWellAfter = tester.widget<InkWell>(button);
    expect(inkWellAfter.onTap, isNotNull);
  });

  testWidgets('confirming pops the dialog and fires onConfirm', (tester) async {
    var confirmed = false;
    await pumpDialog(tester, onConfirm: () => confirmed = true);

    await tester.enterText(find.byType(TextField), 'WIPE ALL');
    await tester.pump();
    await tester.tap(find.text('WIPE ALL & RE-SEED'));
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
    expect(find.text('Are you absolutely sure?'), findsNothing);
  });

  testWidgets('cancel button closes the dialog without confirming', (
    tester,
  ) async {
    var confirmed = false;
    await pumpDialog(tester, onConfirm: () => confirmed = true);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(confirmed, isFalse);
    expect(find.text('Are you absolutely sure?'), findsNothing);
  });
}
