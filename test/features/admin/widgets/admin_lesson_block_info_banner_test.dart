import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/presentation/widgets/admin_lesson_block_info_banner.dart';

void main() {
  Future<void> pumpBanner(WidgetTester tester, {VoidCallback? onAction}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: AdminLessonBlocksNeedEditingState(
              title: 'No blocks yet',
              message: 'Add your first lesson block to get started.',
              actionLabel: 'Open block editor',
              isDark: false,
              onAction: onAction ?? () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders title, message, icon, and action button', (
    tester,
  ) async {
    await pumpBanner(tester);

    expect(find.text('No blocks yet'), findsOneWidget);
    expect(
      find.text('Add your first lesson block to get started.'),
      findsOneWidget,
    );
    expect(find.text('Open block editor'), findsOneWidget);
    expect(find.byIcon(Icons.dashboard_customize_rounded), findsOneWidget);
    expect(find.byIcon(Icons.edit_rounded), findsOneWidget);
  });

  testWidgets('tapping the action button fires onAction', (tester) async {
    var acted = false;
    await pumpBanner(tester, onAction: () => acted = true);

    await tester.tap(find.text('Open block editor'));
    expect(acted, isTrue);
  });
}
