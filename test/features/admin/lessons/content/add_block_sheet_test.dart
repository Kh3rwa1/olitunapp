import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/presentation/lessons/content/widgets/add_block_sheet.dart';

void main() {
  Future<void> pumpSheet(
    WidgetTester tester,
    ValueChanged<String> onSelectType,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => AddBlockSheet.show(context, onSelectType),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('OPEN'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('renders every block type option', (tester) async {
    await pumpSheet(tester, (_) {});

    expect(find.text('Add Lesson Block'), findsOneWidget);
    for (final label in [
      'Text',
      'Image',
      'SVG',
      'Audio',
      'Video',
      'Quiz',
      'Lottie',
      'Glyph',
      'Callout',
      'Tracing',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('choosing a type pops the sheet and reports it', (tester) async {
    final selected = <String>[];
    await pumpSheet(tester, selected.add);

    await tester.tap(find.text('Quiz'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(selected, ['quiz']);
    expect(find.text('Add Lesson Block'), findsNothing);
  });

  testWidgets('close button dismisses without selecting a type', (
    tester,
  ) async {
    final selected = <String>[];
    await pumpSheet(tester, selected.add);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(selected, isEmpty);
    expect(find.text('Add Lesson Block'), findsNothing);
  });
}
