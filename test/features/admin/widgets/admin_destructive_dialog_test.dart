import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/presentation/widgets/common/admin_destructive_dialog.dart';

void main() {
  group('AdminDestructiveDialog', () {
    testWidgets(
      'requires typed confirmation keyword to enable execute button',
      (tester) async {
        var executed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      AdminDestructiveDialog.show(
                        context: context,
                        title: 'Reset Database',
                        actionName: 'Wipe Database',
                        targetName: 'Appwrite Production DB',
                        blastRadiusDescription:
                            'All collections will be permanently deleted.',
                        requiresTypedConfirmation: true,
                        typedConfirmationKeyword: 'WIPE-DATABASE',
                        onConfirm: () async {
                          executed = true;
                        },
                      );
                    },
                    child: const Text('Open Dialog'),
                  );
                },
              ),
            ),
          ),
        );

        // Open dialog
        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Reset Database'), findsOneWidget);
        expect(find.text('Target: '), findsOneWidget);
        expect(find.text('Appwrite Production DB'), findsOneWidget);
        expect(
          find.text('All collections will be permanently deleted.'),
          findsOneWidget,
        );

        // Verify Execute button is disabled before typing keyword
        final executeButtonFinder = find.widgetWithText(
          ElevatedButton,
          'Execute Action',
        );
        expect(executeButtonFinder, findsOneWidget);
        final executeButtonBefore = tester.widget<ElevatedButton>(
          executeButtonFinder,
        );
        expect(executeButtonBefore.onPressed, isNull);

        // Type wrong keyword
        await tester.enterText(find.byType(TextField), 'WRONG');
        await tester.pumpAndSettle();
        final executeButtonWrong = tester.widget<ElevatedButton>(
          executeButtonFinder,
        );
        expect(executeButtonWrong.onPressed, isNull);

        // Type exact keyword
        await tester.enterText(find.byType(TextField), 'WIPE-DATABASE');
        await tester.pumpAndSettle();
        final executeButtonRight = tester.widget<ElevatedButton>(
          executeButtonFinder,
        );
        expect(executeButtonRight.onPressed, isNotNull);

        // Tap execute
        await tester.tap(executeButtonFinder);
        await tester.pumpAndSettle();

        expect(executed, isTrue);
        expect(find.byType(AdminDestructiveDialog), findsNothing);
      },
    );
  });
}
